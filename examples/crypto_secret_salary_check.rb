#!/usr/bin/env ruby
# frozen_string_literal: true

# Yao's garbled circuits: Alice and Bob learn whether their salaries are within a threshold, and nothing else.
#
# Alice (garbler) turns the comparison into an encrypted boolean circuit and sends Bob one message. Bob
# (evaluator) gets the labels for his own input bits through oblivious transfer, so Alice never sees his salary,
# then evaluates the circuit and decodes only the final output bit. Semi-honest model: both parties are assumed
# to follow the protocol. Toy code for learning, not for real secrets.

require 'digest'
require 'optparse'
require 'securerandom'

# ==============================================================================
# CONSTANTS
# ==============================================================================
BITS = 21 # 2**21 covers salaries up to $2,097,151.
LABEL_BYTES = 16 # 128-bit wire labels, the usual security level for garbling.

# RFC 3526 group 14, the 2048-bit MODP group.
PRIME_HEX = [
    'FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD129024E088A67CC74020BBEA63B139B22514A08798E3404DD',
    'EF9519B3CD3A431B302B0A6DF25F14374FE1356D6D51C245E485B576625E7EC6F44C42E9A637ED6B0BFF5CB6F406B7ED',
    'EE386BFB5A899FA5AE9F24117C4B1FE649286651ECE45B3DC2007CB8A163BF0598DA48361C55D39A69163FA8FD24CF5F',
    '83655D23DCA3AD961C62F356208552BB9ED529077096966D670C354E4ABC9804F1746C08CA18217C32905E462E36CE3B',
    'E39E772C180E86039B2783A2EC07A28FB5C55DF06F4C52C9DE2BCBF6955817183995497CEA956AE515D2261898FA0510',
    '15728E5A8AACAA68FFFFFFFFFFFFFFFF'
].join
PRIME = PRIME_HEX.to_i(16)
GENERATOR = 2

GATE_TRUTH = {
    and: ->(left, right) { left & right },
    or: ->(left, right) { left | right },
    xor: ->(left, right) { left ^ right }
}.freeze


# ==============================================================================
# ARGUMENTS
# ==============================================================================
options = { alice: 150_000, bob: 155_000, threshold: 10_000 }
parser = OptionParser.new
parser.banner = 'usage: crypto_secret_salary_check.rb [options]'
parser.on('--alice SALARY', Integer, "Alice's salary (default: #{options[:alice]})")
parser.on('--bob SALARY', Integer, "Bob's salary (default: #{options[:bob]})")
parser.on('--threshold AMOUNT', Integer, "public threshold (default: #{options[:threshold]})")
begin
    parser.parse!(into: options)
rescue OptionParser::ParseError => error
    abort "ERROR: #{error.message}; see --help"
end
abort "ERROR: unexpected arguments: #{ARGV.join(' ')}; see --help" unless ARGV.empty?

salary_limit = 2**BITS - 1
options.each do |name, value|
    next if value.between?(0, salary_limit)

    abort "ERROR: --#{name} #{value} is outside 0..#{salary_limit}; raise BITS to compare larger amounts"
end

# ==============================================================================
# HELPERS
# ==============================================================================
def xor_bytes(first, second)
    raise ArgumentError, "length mismatch: #{first.bytesize} vs #{second.bytesize}" if first.bytesize != second.bytesize

    pairs = first.bytes.zip(second.bytes)
    return pairs.map { |left, right| left ^ right }.pack('C*')
end

def to_bits(value, width)
    return Array.new(width) { |position| value[position] }
end

# The domain tag keeps gate pads and OT keys from ever hashing the same input.
def digest_prefix(domain, material)
    digest = Digest::SHA256.digest([domain, material].join)
    return digest.byteslice(0, LABEL_BYTES + 1)
end

# ==============================================================================
# CIRCUIT
# ==============================================================================
Gate = Struct.new(:operation, :left, :right, :output)

class Circuit
    attr_reader :wire_count, :gates

    def initialize
        @wire_count = 0
        @gates = []
    end

    def new_wires(count)
        start = @wire_count
        @wire_count += count
        return (start...@wire_count).to_a
    end

    def gate(operation, left, right)
        output = new_wires(1).first
        @gates.append(Gate.new(operation, left, right, output))
        return output
    end

    def full_adder(left_bit, right_bit, carry)
        partial = gate(:xor, left_bit, right_bit)
        total = gate(:xor, partial, carry)
        both_set = gate(:and, left_bit, right_bit)
        carried = gate(:and, partial, carry)
        carry_out = gate(:or, both_set, carried)
        return [total, carry_out]
    end

    # Little-endian ripple-carry adder. The result is one bit wider than the inputs.
    def add(left_bits, right_bits, zero)
        carry = zero
        bit_pairs = left_bits.zip(right_bits)
        total = bit_pairs.map do |left_bit, right_bit|
            sum_bit, carry = full_adder(left_bit, right_bit, carry)
            sum_bit
        end
        return total + [carry]
    end

    # left >= right exactly when left + ~right + 1 carries out of the top bit.
    def greater_or_equal(left_bits, right_bits, one)
        carry = one
        bit_pairs = left_bits.zip(right_bits)
        bit_pairs.each do |left_bit, right_bit|
            inverted = gate(:xor, right_bit, one)
            _sum_bit, carry = full_adder(left_bit, inverted, carry)
        end
        return carry
    end
end

SalaryCircuit = Struct.new(:circuit, :alice_wires, :bob_wires, :threshold_wires, :one_wire, :output_wire)

# Computes (alice <= bob + threshold) AND (bob <= alice + threshold), i.e. |alice - bob| <= threshold.
def build_salary_circuit(bits)
    circuit = Circuit.new
    alice = circuit.new_wires(bits)
    bob = circuit.new_wires(bits)
    threshold = circuit.new_wires(bits)
    one = circuit.new_wires(1).first
    zero = circuit.gate(:xor, one, one)

    alice_plus_threshold = circuit.add(alice, threshold, zero)
    bob_plus_threshold = circuit.add(bob, threshold, zero)
    alice_not_far_above = circuit.greater_or_equal(bob_plus_threshold, alice + [zero], one)
    bob_not_far_above = circuit.greater_or_equal(alice_plus_threshold, bob + [zero], one)
    output = circuit.gate(:and, alice_not_far_above, bob_not_far_above)
    return SalaryCircuit.new(circuit, alice, bob, threshold, one, output)
end


# ==============================================================================
# GARBLING
# ==============================================================================
# color is the point-and-permute bit: it tells the evaluator which table row to open and says nothing about the value.
Label = Struct.new(:key, :color) do
    def encode
        return [key, color.chr].join
    end

    def self.decode(raw)
        return new(raw.byteslice(0, LABEL_BYTES), raw.getbyte(LABEL_BYTES))
    end
end

def gate_pad(left, right, gate_index)
    parts = []
    parts.append(left.key)
    parts.append(right.key)
    parts.append([gate_index].pack('N'))
    return digest_prefix('gate', parts.join)
end

# Everything Alice hands Bob in the clear. Bob's own input labels arrive separately, through oblivious transfer.
MessageToBob = Struct.new(:tables, :input_labels, :output_decoding_bit)

class Garbler
    def initialize(salary_circuit)
        @salary_circuit = salary_circuit
        circuit = salary_circuit.circuit
        @labels = Array.new(circuit.wire_count) do
            permute = SecureRandom.random_number(2)
            [
                Label.new(SecureRandom.random_bytes(LABEL_BYTES), permute),
                Label.new(SecureRandom.random_bytes(LABEL_BYTES), 1 ^ permute)
            ]
        end
        @tables = circuit.gates.each_with_index.map { |gate, index| garble_gate(gate, index) }
    end

    def message_to_bob(alice_salary, threshold)
        known_bits = @salary_circuit.alice_wires.zip(to_bits(alice_salary, BITS))
        known_bits += @salary_circuit.threshold_wires.zip(to_bits(threshold, BITS))
        known_bits.append([@salary_circuit.one_wire, 1])
        wire_labels = known_bits.map { |wire, bit| [wire, @labels[wire][bit]] }
        output_wire = @salary_circuit.output_wire
        return MessageToBob.new(@tables, wire_labels.to_h, @labels[output_wire][0].color)
    end

    # Alice offers both labels of one of Bob's wires; OT lets Bob take exactly one without her learning which.
    def offer_for(wire)
        return @labels[wire].map(&:encode)
    end

    private

    def garble_gate(gate, index)
        truth = GATE_TRUTH.fetch(gate.operation)
        table = Array.new(4)
        value_pairs = [0, 1].product([0, 1])
        value_pairs.each do |left_value, right_value|
            left = @labels[gate.left][left_value]
            right = @labels[gate.right][right_value]
            output = @labels[gate.output][truth.call(left_value, right_value)]
            table[2 * left.color + right.color] = xor_bytes(gate_pad(left, right, index), output.encode)
        end
        return table
    end
end

class Evaluator
    def initialize(circuit, message)
        @circuit = circuit
        @message = message
        @wires = message.input_labels.dup
    end

    def receive_input(wire, encoded_label)
        @wires[wire] = Label.decode(encoded_label)
    end

    def evaluate(output_wire)
        @circuit.gates.each_with_index do |gate, index|
            left = @wires.fetch(gate.left)
            right = @wires.fetch(gate.right)
            row = @message.tables[index][2 * left.color + right.color]
            @wires[gate.output] = Label.decode(xor_bytes(gate_pad(left, right, index), row))
        end
        output_label = @wires.fetch(output_wire)
        return (output_label.color ^ @message.output_decoding_bit) == 1
    end
end


# ==============================================================================
# OBLIVIOUS TRANSFER
# ==============================================================================
# 1-out-of-2 OT after Chou and Orlandi, "The Simplest Protocol for Oblivious Transfer" (2015). Simplified for the
# semi-honest model: keys hash only the shared secret, not the (A, B) transcript the paper adds against cheaters.

def shared_key(shared_secret)
    secret_hex = shared_secret.to_s(16).rjust(PRIME_HEX.length, '0')
    return digest_prefix('ot', [secret_hex].pack('H*'))
end

def random_exponent
    return SecureRandom.random_number(PRIME - 3) + 2
end

class OTSender
    attr_reader :public_key

    def initialize
        @secret = random_exponent
        @public_key = GENERATOR.pow(@secret, PRIME)
        # Fermat inverse, since PRIME is prime; Ruby 2.5's Integer#pow rejects negative exponents.
        @public_key_inverse = @public_key.pow(PRIME - 2, PRIME)
    end

    def encrypt(receiver_key, message_zero, message_one)
        key_zero = shared_key(receiver_key.pow(@secret, PRIME))
        unblinded = receiver_key * @public_key_inverse % PRIME
        key_one = shared_key(unblinded.pow(@secret, PRIME))
        return [xor_bytes(message_zero, key_zero), xor_bytes(message_one, key_one)]
    end
end

class OTReceiver
    attr_reader :public_key

    def initialize(sender_key, choice)
        @secret = random_exponent
        @sender_key = sender_key
        @choice = choice
        blinded = GENERATOR.pow(@secret, PRIME)
        @public_key = choice == 1 ? blinded * sender_key % PRIME : blinded
    end

    def decrypt(ciphertexts)
        key = shared_key(@sender_key.pow(@secret, PRIME))
        return xor_bytes(ciphertexts[@choice], key)
    end
end


# ==============================================================================
# PROTOCOL
# ==============================================================================
def run_protocol(alice_salary, bob_salary, threshold)
    salary_circuit = build_salary_circuit(BITS)
    circuit = salary_circuit.circuit
    puts "Circuit: #{circuit.gates.length} gates, #{circuit.wire_count} wires"

    alice = Garbler.new(salary_circuit)
    message = alice.message_to_bob(alice_salary, threshold)
    table_rows = message.tables.flatten
    table_bytes = table_rows.sum(&:bytesize)
    puts "Alice -> Bob: #{table_bytes} bytes of garbled tables plus labels for her inputs"

    bob = Evaluator.new(circuit, message)
    bob_bits = salary_circuit.bob_wires.zip(to_bits(bob_salary, BITS))
    bob_bits.each do |wire, bit|
        sender = OTSender.new
        receiver = OTReceiver.new(sender.public_key, bit)
        ciphertexts = sender.encrypt(receiver.public_key, *alice.offer_for(wire))
        bob.receive_input(wire, receiver.decrypt(ciphertexts))
    end
    puts "Oblivious transfer: Bob fetched #{BITS} input labels, Alice learned none of his bits"

    return bob.evaluate(salary_circuit.output_wire)
end


# ==============================================================================
# MAIN
# ==============================================================================

within = run_protocol(options[:alice], options[:bob], options[:threshold])
expected = (options[:alice] - options[:bob]).abs <= options[:threshold]
if within != expected
    abort "ERROR: garbled result #{within} disagrees with plaintext #{expected}; rerun with the same flags to reproduce"
end

verdict = within ? 'within' : 'NOT within'
puts "Result: salaries are #{verdict} $#{options[:threshold]} of each other"

