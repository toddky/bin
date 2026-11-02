#!/usr/bin/env bash
# USAGE: test_curl.sh
# DESCRIPTION: Check that the curl wrapper keeps every arg off curl's argv and still behaves like curl.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ==============================================================================
# ENVIRONMENT
# ==============================================================================
real_curl=/usr/bin/curl
testdir="$(mktemp -d)"
server_pid=""
# The wait after kill keeps bash from printing a "Terminated" line for the server.
trap '[[ -n "$server_pid" ]] && { kill "$server_pid"; wait "$server_pid"; } 2>/dev/null; rm -rf "$testdir"' EXIT

# Every wrapper run appends its stderr here so a bash error inside the wrapper fails the test run.
stderr_file="$testdir/stderr"
num_failures=0

# ==============================================================================
# HELPERS
# ==============================================================================
function wrapper() {
    "$SCRIPT_DIR/curl" "$@" 2>>"$stderr_file"
}

function check() {
    local name="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo "PASS $name"
        return
    fi
    echo "FAIL $name"
    diff <(printf '%s\n' "$expected") <(printf '%s\n' "$actual") | sed 's/^/     /'
    num_failures=$((num_failures + 1))
}

# The fake answers --help with the real curl so the wrapper can build its option table.
cat > "$testdir/fake" <<EOF
#!/usr/bin/env bash
[[ "\$1" == --help ]] && exec $real_curl "\$@"
printf 'ARGV:'
((\$# > 0)) && printf ' [%s]' "\$@"
echo
for arg in "\$@"; do [[ "\$arg" == /dev/fd/* ]] && sed 's/^/CFG: /' "\$arg"; done
env | grep -c '^_AIBIN_' | sed 's/^/AIBIN_ENV: /'
EOF
chmod +x "$testdir/fake"

function fake() {
    AIBIN_CURL_REAL="$testdir/fake" wrapper "$@"
}

# ==============================================================================
# CONFIG SHAPE
# ==============================================================================
check "header, user, cluster" "$(cat <<'EOF'
ARGV: [--config] [/dev/fd/10]
CFG: -sSL
CFG: -H "X-Custom: value with spaces"
CFG: -u "me:pw"
CFG: --compressed
CFG: --url "https://example.com/a"
AIBIN_ENV: 0
EOF
)" "$(fake -sSL -H 'X-Custom: value with spaces' -u 'me:pw' --compressed https://example.com/a)"

check "-q first, inline value, escaping, --no-, -K" "$(cat <<'EOF'
ARGV: [-q] [--config] [/dev/fd/10]
CFG: -HX-Inline:1
CFG: -d "{\"a\":\"b\\c\"}"
CFG: --no-silent
CFG: -o "out.txt"
CFG: -K "my.cfg"
CFG: --url "https://x/y"
AIBIN_ENV: 0
EOF
)" "$(fake -q -HX-Inline:1 -d '{"a":"b\c"}' --no-silent -o out.txt -K my.cfg https://x/y)"

check "-q not first is left in the config" "$(cat <<'EOF'
ARGV: [--config] [/dev/fd/10]
CFG: -s
CFG: -q
CFG: --url "https://x"
AIBIN_ENV: 0
EOF
)" "$(fake -s -q https://x)"

check "unknown options stay on argv" "$(cat <<'EOF'
ARGV: [--config] [/dev/fd/10] [-Zz9] [--bogus] [-sZ] [--header=foo]
CFG: --url "https://x"
AIBIN_ENV: 0
EOF
)" "$(fake -Zz9 --bogus -sZ --header=foo https://x)"

check "value-taking option with no value stays on argv" "$(printf 'ARGV: [-H]\nAIBIN_ENV: 0')" "$(fake -H)"

check "--next, newline in data, bare dash" "$(cat <<'EOF'
ARGV: [--config] [/dev/fd/10] [--]
CFG: --url "https://a"
CFG: -:
CFG: --url "https://b"
CFG: -d "x\ny"
CFG: --url "-"
AIBIN_ENV: 0
EOF
)" "$(fake https://a -: https://b -d $'x\ny' - --)"

check "no args" "$(printf 'ARGV:\nAIBIN_ENV: 0')" "$(fake)"
check "empty arg" "$(printf 'ARGV: [--config] [/dev/fd/10]\nCFG: --url ""\nAIBIN_ENV: 0')" "$(fake "")"
check "preset reexec marker is ignored" "$(printf 'ARGV: [--config] [/dev/fd/10]\nCFG: -s\nCFG: --url "https://x"\nAIBIN_ENV: 0')" "$(_AIBIN_CURL_REEXEC=1 fake -s https://x)"

printf '#!/usr/bin/env bash\nexit 0\n' > "$testdir/nohelp"
chmod +x "$testdir/nohelp"
AIBIN_CURL_REAL="$testdir/nohelp" wrapper -s https://x
check "curl without usable --help fails" 1 "$?"

# ==============================================================================
# MATCHES CURL
# ==============================================================================
echo one > "$testdir/a"
echo two > "$testdir/b"
echo 'k=v' > "$testdir/data"
printf 'write-out = "INNER\\n"\n' > "$testdir/inner.cfg"

check "-K with --next matches direct curl" \
    "$("$real_curl" -sS -K "$testdir/inner.cfg" "file://$testdir/a" -: -w 'c=%{response_code}\n' "file://$testdir/b")" \
    "$(wrapper -sS -K "$testdir/inner.cfg" "file://$testdir/a" -: -w 'c=%{response_code}\n' "file://$testdir/b")"

wrapper -sS --bogus x
check "unknown option exits 2" 2 "$?"
wrapper -sS "file://$testdir/a" -H
check "missing value exits 2" 2 "$?"
wrapper -sSL --no-silent -o "$testdir/out" "file://$testdir/a"
check "-o writes the file" one "$(cat "$testdir/out")"
check "-o- writes stdout" one "$(wrapper -s -o- "file://$testdir/a")"
check "LC_ALL=C with non-ASCII header" one "$(LC_ALL=C wrapper -sS -H 'X-Name: café' "file://$testdir/a")"

mkdir "$testdir/home"
printf 'write-out = "RC_READ\\n"\n' > "$testdir/home/.curlrc"
check "-q first skips .curlrc" one "$(CURL_HOME="$testdir/home" wrapper -q -s "file://$testdir/a")"
check "-q elsewhere does not, like curl" "$(printf 'one\nRC_READ')" "$(CURL_HOME="$testdir/home" wrapper -s -q "file://$testdir/a")"

# ==============================================================================
# HTTP DELIVERY
# ==============================================================================
cat > "$testdir/server.py" <<'EOF'
import http.server
class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self): self.reply()
    def do_POST(self): self.reply()
    def reply(self):
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        reply = (str(self.headers) + "BODY=" + body.decode()).encode()
        self.send_response(200)
        self.send_header("Content-Length", str(len(reply)))
        self.end_headers()
        self.wfile.write(reply)
    def log_message(self, *args): pass
server = http.server.HTTPServer(("127.0.0.1", 0), Handler)
print(server.server_address[1], flush=True)
while True: server.handle_request()
EOF
python3 "$testdir/server.py" > "$testdir/port" &
server_pid=$!
# 10 x 0.2s is far longer than python needs to bind a port; the loop just avoids a fixed sleep.
for _ in $(seq 10); do
    [[ -s "$testdir/port" ]] && break
    sleep 0.2
done
url="http://127.0.0.1:$(cat "$testdir/port")/"

check "header with quotes and backslash, basic auth, data" "$(cat <<'EOF'
Authorization: Basic
X-Quote: a"b\c
BODY=k=v&q="x"
EOF
)" "$(wrapper -sS -H 'X-Quote: a"b\c' -u 'u:p' --data-raw 'k=v&q="x"' "$url" | grep -oE 'Authorization: Basic|X-Quote: .*|BODY=.*')"
check "cluster with inline header" "$(printf 'X-A: 1\nX-B: 2')" "$(wrapper -sSHX-A:1 -HX-B:2 "$url" | grep -E 'X-A|X-B')"
check "-d @file" "BODY=k=v" "$(wrapper -sS -d "@$testdir/data" "$url" | grep BODY)"
check "--data-urlencode name@file" "BODY=n=k%3Dv%0A" "$(wrapper -sS --data-urlencode "n@$testdir/data" "$url" | grep BODY)"
check "-T upload" "BODY=k=v" "$(wrapper -sS -T "$testdir/data" -X POST "$url" | grep BODY)"

# ==============================================================================
# PS DURING TRANSFER
# ==============================================================================
wrapper -sS -H 'X-Marker: VISIBLE_IN_PS' --limit-rate 1 -d 'zzzzzzzzzzzzzzzzzzzz' "$url" >/dev/null &
transfer_pid=$!
# 0.5s is enough for the two execs; the 1 byte/s rate limit keeps the transfer alive much longer.
sleep 0.5
check "curl argv during transfer" "$real_curl --config /dev/fd/10" "$(ps -o args= -p "$(pgrep -P "$transfer_pid" || echo "$transfer_pid")")"
check "marker absent from all of ps" "" "$(ps -eo args | grep VISIBLE_IN_PS | grep -v grep)"
kill "$transfer_pid" 2>/dev/null
wait "$transfer_pid" 2>/dev/null

# ==============================================================================
# RESULT
# ==============================================================================
if grep -E '^[^:]+: line [0-9]+: ' "$stderr_file"; then
    echo "FAIL the wrapper printed a bash error (see above)"
    num_failures=$((num_failures + 1))
fi

echo
if ((num_failures > 0)); then
    echo "$num_failures check(s) failed."
    exit 1
fi
echo "All checks passed."
