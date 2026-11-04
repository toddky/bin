#!/usr/bin/env python3
"""Yao's garbled circuits: Alice and Bob learn whether their salaries are within a threshold, and nothing else.

Alice (garbler) turns the comparison into an encrypted boolean circuit. Bob (evaluator) gets the labels for
his own input bits through oblivious transfer, so Alice never sees his salary, then evaluates the circuit and
decodes only the final output bit. This is the semi-honest model: both parties are assumed to follow the
protocol. Toy code for learning, not for real secrets.
"""

import argparse
import hashlib
import secrets
from dataclasses import dataclass

BITS = 21  # 2**21 covers salaries up to $2,097,151.
LABEL_BYTES = 16  # 128-bit wire labels, the usual security level for garbling.

# RFC 3526 group 14, the 2048-bit MODP group.
PRIME = int(
    "FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD129024E088A67CC74020BBEA63B139B22514A08798E3404DD"
    "EF9519B3CD3A431B302B0A6DF25F14374FE1356D6D51C245E485B576625E7EC6F44C42E9A637ED6B0BFF5CB6F406B7ED"
    "EE386BFB5A899FA5AE9F24117C4B1FE649286651ECE45B3DC2007CB8A163BF0598DA48361C55D39A69163FA8FD24CF5F"
    "83655D23DCA3AD961C62F356208552BB9ED529077096966D670C354E4ABC9804F1746C08CA18217C32905E462E36CE3B"
    "E39E772C180E86039B2783A2EC07A28FB5C55DF06F4C52C9DE2BCBF6955817183995497CEA956AE515D2261898FA0510"
    "15728E5A8AACAA68FFFFFFFFFFFFFFFF",
    16,
)
GENERATOR = 2

GATE_TRUTH = {
    "AND": lambda left, right: left & right,
    "OR": lambda left, right: left | right,
    "XOR": lambda left, right: left ^ right,
}


def xor_bytes(first: bytes, second: bytes) -> bytes:
    return bytes(x ^ y for x, y in zip(first, second, strict=True))


def to_bits(value: int, width: int) -> list[int]:
    return [(value >> position) & 1 for position in range(width)]


# Circuit description, shared in plaintext by both parties.


@dataclass(frozen=True)
class Gate:
    op: str
    left: int
    right: int
    out: int


class Circuit:
    def __init__(self) -> None:
        self.wire_count = 0
        self.gates: list[Gate] = []

    def new_wires(self, count: int) -> list[int]:
        start = self.wire_count
        self.wire_count += count
        return list(range(start, start + count))

    def gate(self, op: str, left: int, right: int) -> int:
        (out,) = self.new_wires(1)
        self.gates.append(Gate(op, left, right, out))
        return out


def full_adder(circuit: Circuit, x: int, y: int, carry: int) -> tuple[int, int]:
    partial = circuit.gate("XOR", x, y)
    total = circuit.gate("XOR", partial, carry)
    carry_out = circuit.gate("OR", circuit.gate("AND", x, y), circuit.gate("AND", partial, carry))
    return total, carry_out


def add(circuit: Circuit, xs: list[int], ys: list[int], zero: int) -> list[int]:
    """Little-endian ripple-carry adder. The result is one bit wider than the inputs."""
    carry = zero
    total = []
    for x, y in zip(xs, ys, strict=True):
        bit, carry = full_adder(circuit, x, y, carry)
        total.append(bit)
    return total + [carry]


def greater_or_equal(circuit: Circuit, xs: list[int], ys: list[int], one: int) -> int:
    """x >= y exactly when x + ~y + 1 carries out of the top bit."""
    carry = one
    for x, y in zip(xs, ys, strict=True):
        _, carry = full_adder(circuit, x, circuit.gate("XOR", y, one), carry)
    return carry


@dataclass
class SalaryCircuit:
    circuit: Circuit
    alice_wires: list[int]
    bob_wires: list[int]
    threshold_wires: list[int]
    one_wire: int
    output_wire: int


def build_salary_circuit(bits: int) -> SalaryCircuit:
    """Computes (alice <= bob + threshold) AND (bob <= alice + threshold), i.e. |alice - bob| <= threshold."""
    circuit = Circuit()
    alice = circuit.new_wires(bits)
    bob = circuit.new_wires(bits)
    threshold = circuit.new_wires(bits)
    (one,) = circuit.new_wires(1)
    zero = circuit.gate("XOR", one, one)

    alice_plus_threshold = add(circuit, alice, threshold, zero)
    bob_plus_threshold = add(circuit, bob, threshold, zero)
    alice_not_far_above = greater_or_equal(circuit, bob_plus_threshold, alice + [zero], one)
    bob_not_far_above = greater_or_equal(circuit, alice_plus_threshold, bob + [zero], one)
    output = circuit.gate("AND", alice_not_far_above, bob_not_far_above)
    return SalaryCircuit(circuit, alice, bob, threshold, one, output)


# Garbling.


@dataclass(frozen=True)
class Label:
    key: bytes
    color: int  # Point-and-permute bit: tells the evaluator which table row to open, unrelated to the value.

    def encode(self) -> bytes:
        return self.key + bytes([self.color])

    @classmethod
    def decode(cls, raw: bytes) -> "Label":
        return cls(raw[:-1], raw[-1])


def gate_pad(left: Label, right: Label, gate_index: int) -> bytes:
    digest = hashlib.sha256(left.key + right.key + gate_index.to_bytes(4, "big")).digest()
    return digest[: LABEL_BYTES + 1]


class Garbler:
    def __init__(self, circuit: Circuit) -> None:
        self.circuit = circuit
        self.labels: dict[int, tuple[Label, Label]] = {}
        for wire in range(circuit.wire_count):
            permute = secrets.randbelow(2)
            self.labels[wire] = (
                Label(secrets.token_bytes(LABEL_BYTES), permute),
                Label(secrets.token_bytes(LABEL_BYTES), 1 ^ permute),
            )
        self.tables = [self._garble_gate(index, gate) for index, gate in enumerate(circuit.gates)]

    def _garble_gate(self, index: int, gate: Gate) -> list[bytes]:
        truth = GATE_TRUTH[gate.op]
        table = [b""] * 4
        for left_value in (0, 1):
            for right_value in (0, 1):
                left = self.labels[gate.left][left_value]
                right = self.labels[gate.right][right_value]
                out = self.labels[gate.out][truth(left_value, right_value)]
                table[2 * left.color + right.color] = xor_bytes(gate_pad(left, right, index), out.encode())
        return table

    def label_for(self, wire: int, value: int) -> Label:
        return self.labels[wire][value]

    def label_pair(self, wire: int) -> tuple[bytes, bytes]:
        zero_label, one_label = self.labels[wire]
        return zero_label.encode(), one_label.encode()

    def output_decoding_bit(self, wire: int) -> int:
        return self.labels[wire][0].color


def evaluate_garbled(circuit: Circuit, tables: list[list[bytes]], inputs: dict[int, Label]) -> dict[int, Label]:
    wires = dict(inputs)
    for index, (gate, table) in enumerate(zip(circuit.gates, tables, strict=True)):
        left, right = wires[gate.left], wires[gate.right]
        row = table[2 * left.color + right.color]
        wires[gate.out] = Label.decode(xor_bytes(gate_pad(left, right, index), row))
    return wires


# 1-out-of-2 oblivious transfer, Chou and Orlandi "The Simplest Protocol for Oblivious Transfer" (2015).


def shared_key(shared_secret: int) -> bytes:
    digest = hashlib.sha256(shared_secret.to_bytes(256, "big")).digest()
    return digest[: LABEL_BYTES + 1]


def random_exponent() -> int:
    return secrets.randbelow(PRIME - 3) + 2


class OTSender:
    def __init__(self) -> None:
        self.secret = random_exponent()
        self.public = pow(GENERATOR, self.secret, PRIME)

    def encrypt(self, receiver_public: int, message0: bytes, message1: bytes) -> tuple[bytes, bytes]:
        key0 = shared_key(pow(receiver_public, self.secret, PRIME))
        unblinded = receiver_public * pow(self.public, -1, PRIME) % PRIME
        key1 = shared_key(pow(unblinded, self.secret, PRIME))
        return xor_bytes(message0, key0), xor_bytes(message1, key1)


class OTReceiver:
    def __init__(self, sender_public: int, choice: int) -> None:
        self.secret = random_exponent()
        self.sender_public = sender_public
        self.choice = choice
        blinded = pow(GENERATOR, self.secret, PRIME)
        self.public = blinded * sender_public % PRIME if choice else blinded

    def decrypt(self, ciphertexts: tuple[bytes, bytes]) -> bytes:
        key = shared_key(pow(self.sender_public, self.secret, PRIME))
        return xor_bytes(ciphertexts[self.choice], key)


# Protocol.


def run_protocol(alice_salary: int, bob_salary: int, threshold: int) -> bool:
    spec = build_salary_circuit(BITS)
    circuit = spec.circuit
    print(f"Circuit: {len(circuit.gates)} gates, {circuit.wire_count} wires")

    alice = Garbler(circuit)
    alice_values = zip(spec.alice_wires, to_bits(alice_salary, BITS), strict=True)
    threshold_values = zip(spec.threshold_wires, to_bits(threshold, BITS), strict=True)
    bob_inputs = {wire: alice.label_for(wire, bit) for wire, bit in [*alice_values, *threshold_values]}
    bob_inputs[spec.one_wire] = alice.label_for(spec.one_wire, 1)
    table_bytes = sum(len(row) for table in alice.tables for row in table)
    print(f"Alice -> Bob: {table_bytes:,} bytes of garbled tables plus labels for her inputs")

    for wire, bit in zip(spec.bob_wires, to_bits(bob_salary, BITS), strict=True):
        sender = OTSender()
        receiver = OTReceiver(sender.public, bit)
        ciphertexts = sender.encrypt(receiver.public, *alice.label_pair(wire))
        bob_inputs[wire] = Label.decode(receiver.decrypt(ciphertexts))
    print(f"Oblivious transfer: Bob fetched {BITS} input labels, Alice learned none of his bits")

    wires = evaluate_garbled(circuit, alice.tables, bob_inputs)
    result = wires[spec.output_wire].color ^ alice.output_decoding_bit(spec.output_wire)
    return bool(result)


def salary(text: str) -> int:
    value = int(text)
    limit = 2**BITS - 1
    if not 0 <= value <= limit:
        raise argparse.ArgumentTypeError(f"{value} is outside 0..{limit}; raise BITS to compare larger amounts")
    return value


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--alice", type=salary, default=150_000, help="Alice's salary (default: %(default)s)")
    parser.add_argument("--bob", type=salary, default=155_000, help="Bob's salary (default: %(default)s)")
    parser.add_argument("--threshold", type=salary, default=10_000, help="public threshold (default: %(default)s)")
    args = parser.parse_args()

    within = run_protocol(args.alice, args.bob, args.threshold)
    assert within == (abs(args.alice - args.bob) <= args.threshold), "garbled result disagrees with plaintext"
    print(f"Result: salaries are {'within' if within else 'NOT within'} ${args.threshold:,} of each other")


if __name__ == "__main__":
    main()
