# Code Review Rules

Rules are grouped by letter:

| Section | Covers |
|---|---|
| CR-A | Comments and documentation |
| CR-B | Formatting and readability |
| CR-C | Naming |
| CR-D | Function design |
| CR-E | Change hygiene |
| CR-F | Errors and failure handling |
| CR-G | Arguments and CLI design |
| CR-H | Tests |
| CR-I | Security |
| CR-J | Files |

Per-language mechanics live in BASH.md, PYTHON.md, GO.md, and RUBY.md. This file covers the review decisions that apply regardless of language. Python examples assume 3.9 or newer.

## CR-A: Comments and documentation

### CR-A1: Short Comments
Comments must be 2 lines maximum, 1 sentence per line, each line fitting in 120 columns. Keep comments short and direct. Never write paragraphs or multi-sentence explanations. If a comment exceeds 2 lines, shorten it or delete it.

Exceptions: a regex or parser comment may add lines for concrete example inputs (CR-A3), a usage example may add a line (CR-A6), and a permalink may sit on its own line (CR-A7).

```python
# NFS dentry cache can hide a lock made on another host.
# 5s is the observed maximum staleness window.
time.sleep(5)
```

### CR-A2: Obvious Comments
A comment explains why: the intent, the gotcha, the reason that is not visible in the code. Delete comments that narrate the obvious. If a comment merely restates what the code plainly does, remove it completely. Do not shorten or rephrase it into a superficial explanation.

Bad:
```python
# Check if returncode is zero
if process.returncode == 0:
    return True
```

Good:
```python
if process.returncode == 0:
    return True
```

### CR-A3: Parser Examples
Always include concrete example strings for regular expressions and string parsing logic. Provide an exact sample input line showing what is being matched or extracted.

Bad:
```python
# Parses error line
match = re.search(r"Cannot open directory (\S+)", line)
```

Good:
```python
# ERROR: Cannot open directory /scratch/user/run_123
match = re.search(r"Cannot open directory (\S+)", line)
```

### CR-A4: Comments Over Docstrings
Prefer a short comment over a multiline docstring for simple functions or scripts. If the function is straightforward, explain the reason in a short comment rather than a verbose docstring block.

Bad:
```python
def setup_logging():
    """
    Configures and initializes logging settings.

    This function sets up the default log format and level
    and verifies that all prerequisites are satisfied.
    """
    logging.basicConfig(level=logging.INFO)
```

Good:
```python
def setup_logging():
    # Every subcommand writes to the same log, so the format is set once here.
    logging.basicConfig(level=logging.INFO)
```

### CR-A5: Update, Do Not Delete
Leave an existing comment alone unless it is wrong or no longer applies. When your change makes it inaccurate, rewrite it to match the new behavior; deleting it throws away a reason nobody wrote down twice.

Bad:
The limit was raised and the comment explaining the old one was dropped:
```python
MAX_PARALLEL_UPLOADS = 8
```

Good:
```python
# 8 is the per-client connection limit the reports API enforces; more just get refused.
MAX_PARALLEL_UPLOADS = 8
```

### CR-A6: Usage Examples
Put a usage example at the very top of any function whose inputs or outputs are not obvious from the signature. Show one real call and what it returns.

Bad:
```python
def parse_duration(text):
    ...
```

Good:
```python
def parse_duration(text):
    # parse_duration("1h30m") -> 5400
    ...
```

### CR-A7: External Permalinks
When reusing logic from an upstream project or reproducing behavior from another repository, include the pinned commit SHA and line number along with a permalink.

Bad:
```python
# Borrowed from the other repository
resolve_config()
```

Good:
```python
# Reuses config resolution logic (upstream/tool@a1b2c3d4 line 142)
# https://github.com/example/tool/blob/a1b2c3d4/bin/tool#L142
resolve_config()
```

### CR-A8: Trim Help Text
Keep help strings and descriptions short. If an example already shows the behavior, delete the prose restating it, and cut anything that only states common sense.

Bad:
```python
parser.add_argument("--format", help="The output format to use when writing the report. This controls whether the report comes out as JSON or as CSV. JSON is the default because most consumers expect it.")
```

Good:
```python
parser.add_argument("--format", choices=["json", "csv"], default="json", help="Report output format")
```

### CR-A9: Explain Numbers
Every timeout, retry count, size, and threshold gets a one-line comment saying where the value came from, or that it is a guess. A bare number cannot be tuned safely because nobody knows what it was tuned against.

Bad:
```python
MAX_ATTEMPTS = 3
```

Good:
```python
# 3 attempts covers the transient fetch failures seen in CI; beyond that it is a real break.
MAX_ATTEMPTS = 3
```

## CR-B: Formatting and readability

### CR-B1: Break Expressions
Break long expressions and assign intermediate results to named variables instead of compressing logic into single lines or long list comprehensions.

Bad:
```python
results = [process(item, get_config(item)) for item in items if item.startswith("test_") and validate(item)]
```

Good:
```python
test_items = [item for item in items if item.startswith("test_")]
valid_items = [item for item in test_items if validate(item)]
results = [process(item, get_config(item)) for item in valid_items]
```

### CR-B2: Hoist Out Of Loops
Compute a value that does not change between iterations once, above the loop. Inside the loop it hides the cost and reads as though it depends on the iteration.

Bad:
```python
for branch in branches:
    merge_base = shell.run(["git", "merge-base", "--octopus", *branches])
    print(merge_base, branch)
```

Good:
```python
merge_base = shell.run(["git", "merge-base", "--octopus", *branches])
for branch in branches:
    print(merge_base, branch)
```

### CR-B3: Clean Invocations
Avoid awkward multi-line splits for short command invocations or simple expressions. Keep them on a single line or extract arguments cleanly.

Bad:
```python
cmd = [
    "git",
    "status",
    "--short",
]
```

Good:
```python
cmd = ["git", "status", "--short"]
```

### CR-B4: List Building
Build longer commands and argument collections by appending or extending a list instead of concatenating strings with line continuations or plus signs.

Bad:
```python
cmd = "rsync --archive " + \
      " ".join(f"--exclude={pattern}" for pattern in excludes) + \
      f" {source_dir} {dest_dir}"
```

Good:
```python
cmd = ["rsync", "--archive"]
cmd.extend(f"--exclude={pattern}" for pattern in excludes)
cmd.extend([source_dir, dest_dir])
```

### CR-B5: Step Parsing
Split text and path parsing into clean, sequential steps rather than building monolithic nested expressions or complex regex chains.

Bad:
```python
group_id, item_id = re.match(r".*?/groups/([^/]+)/.*?/items/([^/]+).*", full_url).groups()
```

Good:
```python
# https://gitlab.example.com/api/v4/groups/42/-/items/7
path_tokens = urlparse(full_url).path.strip("/").split("/")
group_id = path_tokens[path_tokens.index("groups") + 1]
item_id = path_tokens[path_tokens.index("items") + 1]
```

### CR-B6: Vertical Spacing
Do not stack blank lines. If a formatter such as black or ruff runs on the file, let it decide the spacing around functions; otherwise use one blank line between functions and within a block, and two blank lines only before a section header (CR-B8, CR-D9).

Bad:
```python
def load_config():
    ...



def save_config():
    ...
```

Good:
```python
def load_config():
    ...

def save_config():
    ...
```

### CR-B7: Top Imports
Put every import at the top of the file. An import buried in a function or halfway down the file hides a dependency and is usually a leftover from adding the code in a hurry.

Bad:
```python
def load_config(config_file):
    import yaml
    return yaml.safe_load(config_file.read_text())
```

Good:
```python
import yaml

def load_config(config_file):
    return yaml.safe_load(config_file.read_text())
```

### CR-B8: Section Headers
Name each section after the step the code performs, in all caps, three words maximum. Standard up-front sections come first in this order when present: `IMPORTS` (CR-B7), `ARGUMENTS`, `ENVIRONMENT`, `HELPERS`. When the section that does the work is small enough that a name would only restate it, call it `MAIN`. After those, the headers run in the order the code runs, so the list of headers reads as the sequence of steps.

Bad:
```python
# ==============================================================================
# THIS SECTION PARSES THE BUILD LOG AND PULLS OUT THE ERRORS
# ==============================================================================
```

Good:
```python
# ==============================================================================
# BUILD LOG PARSING
# ==============================================================================
```

The banner is the language's own comment marker followed by 78 `=` characters, the title line, then the marker and 78 `=` again. Languages with their own documented convention do not get a banner: Go uses package and function doc comments instead.

### CR-B9: Match The File
Follow the conventions already in the file you are editing. If every other function there returns a dict, do not introduce a dataclass for yours; consistency within one file beats your preferred style. When the file's existing convention conflicts with a rule here, the file wins for this change; bring the file in line in a separate change (CR-E3).

## CR-C: Naming

### CR-C1: Specific Plain Names
Name functions and helpers after the concrete action or output, in plain terms. Generic verbs (`process`, `handle`) and software jargon (`orchestrate`, `pipeline`, `payload`) describe every function and therefore none.

Bad:
```python
def process_data(log_file):
    ...

def orchestrate_artifact_pipeline(payload):
    ...
```

Good:
```python
def extract_build_errors(log_file):
    ...

def upload_build_artifacts(files):
    ...
```

### CR-C2: Named Constants
Give limits, thresholds, and fixed keys an uppercase constant at the top of the file. Do not leave bare literals inline. Argparse defaults are the exception: the parser is already the single place that value lives (CR-E4), so a bare default there is fine.

Bad:
```python
if len(fields) > 20:
    fields = fields[:20]
```

Good:
```python
# The metadata API rejects requests with more than 20 fields.
MAX_METADATA_FIELDS = 20

if len(fields) > MAX_METADATA_FIELDS:
    fields = fields[:MAX_METADATA_FIELDS]
```

### CR-C3: Spell Names Out
Spell names out in new code. An abbreviation saves the writer three keystrokes and costs every reader a guess.

This covers single letters too: `result`, not `r`. A plain index loop (`i`, `j`) is the only place one is acceptable.

Exception: a name that mirrors an API, JSON, or CSV field keeps the field's own spelling, however abbreviated. `jobid` stays `jobid` so the same string greps across server and client.

Bad:
```python
out = run_build(cfg)
msg = out.splitlines()[-1]
for r in out.splitlines():
    ...
```

Good:
```python
output = run_build(config)
last_line = output.splitlines()[-1]
jobid = response["jobid"]
```

### CR-C4: File And Dir Suffixes
Name a filesystem path after what it points at: a `_file` or `_dir` suffix, or the extension when it matters (`readme_md`, `config_json`). A `path` suffix says nothing about whether the code can read it, list it, or write into it.

Bad:
```python
config_path = Path.home() / ".config" / "tool" / "config.yaml"
log_path = args.log_path
```

Good:
```python
config_yaml = Path.home() / ".config" / "tool" / "config.yaml"
log_dir = args.log_dir
```

### CR-C5: Count Prefix
Prefix integer counts with `num_`. A `_count` suffix or a phrase like `failures_seen` reads as a collection until the reader finds the assignment.

Bad:
```python
failure_count = len(failed_jobs)
jobs_seen = 0
```

Good:
```python
num_failures = len(failed_jobs)
num_jobs = 0
```

### CR-C6: Name The Wrapper After The Tool
Name a pass-through helper after the binary or concept it wraps. A `run_` or `_cmd` decoration on the name repeats what the body already shows and makes the call site read like plumbing.

Bad:
```python
def run_tmux_cmd(args):
    return shell.run(["tmux", *args])
```

Good:
```python
def tmux(args):
    return shell.run(["tmux", *args])
```

## CR-D: Function design

### CR-D1: Inline Helpers
Inline single-use helpers into the caller. Do not create a function for logic that runs in exactly one place and is short enough to read inline.

Bad:
```python
def is_prebuilt(source_file):
    return source_file.suffix in (".elf", ".axf")

for source_file in sources:
    if is_prebuilt(source_file):
        copy_source(source_file)
```

Good:
```python
for source_file in sources:
    if source_file.suffix in (".elf", ".axf"):
        copy_source(source_file)
```

### CR-D2: Direct Passthrough
Pass flags straight through to the underlying tool. Do not invent a custom boolean that maps onto a flag the tool already accepts.

Bad:
```python
def commit(message, skip_hooks=False):
    extra = ["--no-verify"] if skip_hooks else []
    run_git(["commit", "-m", message] + extra)
```

Good:
```python
def commit(message, git_args=()):
    run_git(["commit", "-m", message, *git_args])
```

### CR-D3: Existing Helpers
Look for an existing helper before writing a new one. If the repo already wraps this call, use the wrapper; a second copy drifts from the first and both have to be fixed later.

Bad:
```python
def current_branch():
    result = subprocess.run(["git", "branch", "--show-current"], capture_output=True, text=True, check=True)
    return result.stdout.strip()
```

Good:
```python
import shell

def current_branch():
    return shell.run(["git", "branch", "--show-current"])
```

### CR-D4: Cohesive Functions
Put the setup a function needs inside that function. If every caller has to remember a preparation step first, the step belongs in the function that owns the work. A one-off step with a single caller does not need its own name at all; fold it in and keep the module's public surface to the functions other files actually call.

Bad:
```python
def parse_build_errors(log_text):
    ...

log_text = build_log.read_text(errors="replace")
errors = parse_build_errors(log_text)
```

Good:
```python
def parse_build_errors(build_log):
    log_text = build_log.read_text(errors="replace")
    ...

errors = parse_build_errors(build_log)
```

### CR-D5: Return, Do Not Write
Do not take a destination parameter the caller already controls. Return the result instead of writing it somewhere, so the caller decides the destination and the function is testable without a filesystem.

Bad:
```python
def summarize_failures(results, log_file):
    lines = [f"{name}: {reason}" for name, reason in results]
    log_file.write_text("\n".join(lines))
```

Good:
```python
def summarize_failures(results):
    lines = [f"{name}: {reason}" for name, reason in results]
    return "\n".join(lines)

log_file.write_text(summarize_failures(results))
```

### CR-D6: No Nested Functions
Define functions at module level. A function nested inside another is invisible to tests and callers, and it usually only exists to reach a local it could have taken as a parameter. If it is genuinely reused, hoist it; if it is single-use, inline it per CR-D1.

Bad:
```python
def build_report(rows):
    def format_row(row):
        return f"{row.name}: {row.status}"

    return "\n".join(format_row(row) for row in rows)
```

Good:
```python
def build_report(rows):
    return "\n".join(f"{row.name}: {row.status}" for row in rows)
```

### CR-D7: Parameterize Reuse
When a second caller needs the same code or data with a different value, take that value as an input instead of copying the file. Do this the moment the second caller exists, not speculatively (CR-E5).

Bad:
The URL is baked in, so the next consumer has to copy the whole file:
```python
API_URL = "https://reports.example.com/api/v4"

def upload(report_file):
    requests.post(f"{API_URL}/reports", files={"report": report_file.read_bytes()})
```

Good:
```python
def upload(report_file, api_url):
    requests.post(f"{api_url}/reports", files={"report": report_file.read_bytes()})
```

### CR-D8: Plain Conditions
Test the value directly. Comparing against `True` or `False` adds noise and breaks the moment the value is `None` or an empty string instead of the literal you compared to.

Bad:
```python
if args.verbose is not False:
    print_details()
```

Good:
```python
if args.verbose:
    print_details()
```

### CR-D9: No Step Machinery
Run the steps in order under named section headers. Do not build a step table, dispatcher, or registry to drive a fixed sequence that only ever runs one way.

Bad:
```python
steps = [("fetch", fetch_sources), ("build", run_build), ("publish", upload_results)]
for name, step in steps:
    print(f"=== {name} ===")
    step()
```

Good:
```python
# ==============================================================================
# FETCH
# ==============================================================================
fetch_sources()


# ==============================================================================
# BUILD
# ==============================================================================
run_build()


# ==============================================================================
# PUBLISH
# ==============================================================================
upload_results()
```

## CR-E: Change hygiene

### CR-E1: Delete Dead Code
Delete unused imports, commented-out blocks, and leftover scaffolding instead of leaving them behind. Do not keep code that nothing calls.

### CR-E2: Reachable Features
When you add a variant, update the place that enumerates the allowed values in the same change. Otherwise the code is unreachable and the argument parser rejects the value before your branch ever runs.

Bad:
`--format yaml` exits with "invalid choice", so the new branch is dead code:
```python
parser.add_argument("--format", choices=["json", "csv"], default="json")

if args.format == "yaml":
    return yaml.safe_dump(report)
```

Good:
```python
parser.add_argument("--format", choices=["json", "csv", "yaml"], default="json")

if args.format == "yaml":
    return yaml.safe_dump(report)
```

### CR-E3: Stay In Scope
Keep unrelated changes out of the change set. A bug fix does not need surrounding cleanup, and moving or renaming code you are not fixing buries the real change in the diff. CR-E1 and CR-D3 apply to the code the change touches, not to the rest of the file.

### CR-E4: One Source
Define a value once. A constant declared in two files, or a default set in both the parser and the function it feeds, will drift, and the copy you forgot to change becomes the bug. For a CLI, the parser holds the default and the function takes the value as a required parameter.

Bad:
The same default lives in two places:
```python
parser.add_argument("--timeout", type=int, default=30)

def fetch_report(timeout=30):
    ...
```

Good:
```python
# 30s is roughly double the slowest response measured against this endpoint (~14s).
parser.add_argument("--timeout", type=int, default=30)

def fetch_report(timeout):
    ...

fetch_report(args.timeout)
```

### CR-E5: No Speculation
Build what the change needs, not what it might need later. An option nobody passes and a hook nobody calls are pure cost, and the guess is usually wrong by the time a caller shows up.

Bad:
No caller passes `dry_run`, `retries`, or `mirror_url`:
```python
def upload_report(report_file, dry_run=False, retries=0, mirror_url=None):
    ...
```

Good:
```python
def upload_report(report_file):
    ...
```

## CR-F: Errors and failure handling

### CR-F1: Guard Clauses
Check failure conditions upfront and exit early with `continue` or `return`. Do not wrap the main path in nested `if` blocks.

Bad:
```python
for log_file in log_files:
    if log_file.exists():
        if log_file.stat().st_size > 0:
            error = parse_log_error(log_file)
            if error:
                return error
            process_log_file(log_file)
```

Good:
```python
for log_file in log_files:
    if not log_file.exists():
        continue
    if log_file.stat().st_size == 0:
        continue
    error = parse_log_error(log_file)
    if error:
        return error
    process_log_file(log_file)
```

### CR-F2: Handle Then Pass Through
Test for the case you actually handle, then fall through to one pass-through path. A negated test inverts the logic and forces a second exit point that has to repeat the value the fall-through already had.

Bad:
```python
if exit_code != TIMEOUT_EXIT_CODE:
    sys.exit(exit_code)
print_timeout_help()
sys.exit(TIMEOUT_EXIT_CODE)
```

Good:
```python
if exit_code == TIMEOUT_EXIT_CODE:
    print_timeout_help()
sys.exit(exit_code)
```

### CR-F3: Bounded Retries
Retry a fixed number of attempts instead of looping forever, and back off exponentially rather than sleeping the same amount each time. Print the reason to stderr on every attempt so a stuck job is diagnosable from the log.

Bad:
```python
while True:
    try:
        run_build()
        break
    except TransientError:
        time.sleep(2)
```

Good:
```python
# 3 attempts covers the transient fetch failures seen in CI; beyond that it is a real break.
MAX_ATTEMPTS = 3
# 2s doubling per attempt is a guess, nothing measured.
BACKOFF_BASE_SECONDS = 2

for attempt in range(1, MAX_ATTEMPTS + 1):
    try:
        run_build()
        break
    except TransientError as error:
        print(f"Attempt {attempt} of {MAX_ATTEMPTS} failed: {error}", file=sys.stderr)
        if attempt == MAX_ATTEMPTS:
            raise
        time.sleep(BACKOFF_BASE_SECONDS * 2 ** (attempt - 1))
```

### CR-F4: Loud Failures
Validate conflicting flags and missing prerequisites upfront and exit with a one-line message. Never let a bad configuration limp along silently. End the message with the way out: what to create, which flag to pass, which value to change. A message that only names the failure leaves the reader to guess the remedy.

Bad:
```python
if not config_file.exists():
    print("WARNING: config file not found, continuing without a config")
```

Good:
```python
if not config_file.exists():
    sys.exit(f"ERROR: config file {config_file} not found, create it or pass --config")
```

### CR-F5: Debug Context
Say what kind of failure it was and print the identifiers needed to debug it: job id, host, path, command. A bare "run failed" forces a second debugging round, and a run that started and never finished is an interrupted run, not a bad result.

Bad:
```python
if "No space left on device" in log_text:
    sys.exit("ERROR: job failed, disk full")

if not result_file.exists():
    sys.exit("ERROR: run failed")
```

Good:
The job runs on a remote node, so the host and mount are the only way to tell which disk filled:
```python
if "No space left on device" in log_text:
    sys.exit(f"ERROR: no space left on {hostname}:{mount_dir}, clean up that mount or rerun on another host")

if not result_file.exists():
    sys.exit(f"ERROR: {run_name} started but never wrote {result_file} (it may have died before finishing)")
```

### CR-F6: Boundary Validation
Validate external input once, where it enters the program. Re-checking the same thing in every function that receives it adds noise and still leaves the real entry point unguarded.

Bad:
Every caller re-checks what the loader should have guaranteed:
```python
def run_step(config):
    if "timeout" not in config:
        sys.exit("ERROR: missing timeout")
    ...
```

Good:
```python
def load_config(config_file):
    try:
        config = yaml.safe_load(config_file.read_text()) or {}
    except yaml.YAMLError as error:
        sys.exit(f"ERROR: {config_file} is not valid YAML: {error}")
    if "timeout" not in config:
        sys.exit(f"ERROR: {config_file} is missing required field 'timeout'")
    return config

def run_step(config):
    ...
```

### CR-F7: Check Before Try
Test for the condition upfront when you can. Reach for `try` only when a check is not practical, as with a parse.

Bad:
A missing file can be tested for, so an `except` is the wrong tool:
```python
try:
    config = yaml.safe_load(config_file.read_text())
except FileNotFoundError:
    sys.exit(f"ERROR: {config_file} not found")
```

Good:
```python
if not config_file.exists():
    sys.exit(f"ERROR: {config_file} not found, create it or pass --config")

config = yaml.safe_load(config_file.read_text())
```

### CR-F8: Narrow Excepts
Never swallow an error you depend on succeeding. Catch the specific exception you expect, then exit or re-raise; a bare `except` hides the real failure and the next symptom shows up somewhere unrelated.

Bad:
```python
try:
    config = yaml.safe_load(config_file.read_text())
except Exception:
    config = {}
```

Good:
Malformed YAML can only be detected by parsing, so here the `except` is the check:
```python
try:
    config = yaml.safe_load(config_file.read_text())
except yaml.YAMLError as error:
    sys.exit(f"ERROR: {config_file} is not valid YAML: {error}")
```

### CR-F9: Always Timeout
Set an explicit timeout on every network call. Most clients default to waiting forever, so one unresponsive server hangs the job until somebody notices and kills it.

Bad:
```python
response = requests.get(url)
```

Good:
```python
# 30s is roughly double the slowest response measured against this endpoint (~14s).
REQUEST_TIMEOUT_SECONDS = 30

response = requests.get(url, timeout=REQUEST_TIMEOUT_SECONDS)
```

## CR-G: Arguments and CLI design

### CR-G1: Arguments At The Top
Define every flag in `parse_args()` at the top of the file, and derive related state from the parsed arguments in one place right after it. Do not scatter argument handling into helpers, set defaults at the call site, or spread mode flags through the script.

Bad:
```python
def fetch_report(timeout=None):
    if timeout is None:
        timeout = 30

use_scheduler = args.scheduler is not None
...
use_remote = args.host is not None
```

Good:
```python
def parse_args():
    parser = argparse.ArgumentParser()
    # 30s is roughly double the slowest response measured against this endpoint (~14s).
    parser.add_argument("--timeout", type=int, default=30, help="Seconds to wait before giving up")
    parser.add_argument("--scheduler", help="Scheduler to submit through; runs locally when omitted")
    parser.add_argument("--host", help="Host to run on; runs locally when omitted")
    return parser.parse_args()

args = parse_args()
use_scheduler = args.scheduler is not None
use_remote = args.host is not None
```

### CR-G2: Useful Defaults
Default a flag to whatever the tool is normally used for, and give the opposite a `--no-` form. Do not make the common case opt-in.

Bad:
```python
parser.add_argument("--cleanup", action="store_true", help="Delete the scratch directory when done")
```

Good:
```python
parser.add_argument("--cleanup", action=argparse.BooleanOptionalAction, default=True, help="Delete the scratch directory when done")
```

### CR-G3: Argument Types
Declare `type=` on every value-taking argument that is not a string, since argparse otherwise hands back a string and numeric comparisons silently do the wrong thing.
Boolean flags are exempt: their action already produces a bool, and `type=bool` is wrong because `bool("False")` is `True`.

Bad:
```python
parser.add_argument("--timeout", help="Seconds to wait before giving up")
parser.add_argument("--config", help="Config file to read")
```

Good:
```python
parser.add_argument("--timeout", type=int, help="Seconds to wait before giving up")
parser.add_argument("--config", type=Path, help="Config file to read")
```

## CR-H: Tests

### CR-H1: Useful Tests
Delete tests that only prove the language works or repeat coverage another test already has. A test earns its place by failing when the new behavior breaks.

Bad:
This only proves Python dicts work, not that anything you wrote works:
```python
def test_config_lookup():
    config = {"timeout": 30}
    assert config["timeout"] == 30
```

Good:
```python
def test_parse_rejects_unknown_field():
    with pytest.raises(ValueError, match="unknown field 'retrys'"):
        parse_config(config_with_typo)
```

## CR-I: Security

### CR-I1: Secrets Off The Command Line
Never pass a secret as a command-line argument, and never give your own tool an option that takes one as its value. Argv is visible to every user on the box in `ps -ef` and lands in shell history. Pass secrets through the environment, stdin, or a file path. The same applies to anything the program prints: when an error or log line includes a value that embeds a secret, such as a URL with a token in it, redact that portion rather than dropping the value the reader needs (CR-F5).

Bad:
```python
parser.add_argument("--token", help="API token for the upload")

shell.run(["report-tool", "--token", api_token, "--upload", str(report_file)])
```

Good:
```python
parser.add_argument("--token-file", type=Path, help="File holding the API token; defaults to $API_TOKEN")

env = os.environ | {"API_TOKEN": api_token}
shell.run(["report-tool", "--upload", str(report_file)], env=env)
```

### CR-I2: No Shell True
Call subprocesses with a list and no `shell=True`. With a shell in the middle, any value you interpolate can inject its own commands.

Bad:
An `author` of `x; rm -rf ~` runs as a second command:
```python
subprocess.run(f"git log --author={author}", shell=True, check=True)
```

Good:
```python
shell.run(["git", "log", f"--author={author}"])
```

### CR-I3: Secret Storage
Never persist a secret to a file that outlives the run. Reading one from an existing credential file is fine; writing one leaves it on disk where it can be committed, logged, or left world-readable.

Bad:
Caching the token to skip the next login leaves it on disk:
```python
token_cache.write_text(api_token)
```

Good:
Read it fresh each run and keep it in memory:
```python
api_token = os.environ["API_TOKEN"]
```

Exception: a temp file from `mktemp` that is removed in an exit trap is the right way to keep a secret off the command line, since `mktemp` creates it owner-only and it is gone when the run ends. The trap and `exec` patterns are in BASH.md under Safety.

## CR-J: Files

### CR-J1: Prose Extensions
Use `.md` for prose files. A custom extension like `.prompt` loses syntax highlighting in editors and rendering in the web UI, for no benefit.

### CR-J2: XDG Locations
Put config, cache, and runtime files under the matching XDG variable and state the fallback next to it. A hardcoded `~/.config` ignores the one variable a caller has to redirect the tool, and it breaks on any host that sets XDG elsewhere.

Bad:
```python
config_yaml = Path.home() / ".config" / "tool" / "config.yaml"
```

Good:
```python
config_home = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
config_yaml = config_home / "tool" / "config.yaml"
```

### CR-J3: Private Temp Files
Never write to a fixed path under `/tmp`. Create a private file or directory, and tie its cleanup to the process exiting rather than to the last line of the happy path. A predictable name on a shared machine collides with another user's run, and on most systems it lets them create the file first.

Bad:
```python
temp_dir = Path("/tmp/build-report")
temp_dir.mkdir(exist_ok=True)
...
shutil.rmtree(temp_dir)
```

Good:
```python
with tempfile.TemporaryDirectory() as temp_dir:
    ...
```

### CR-J4: Resolve Symlinks
Resolve a path before you act on it or report it. On a shared machine the interesting directories are symlinks into someone's scratch or another repo, and the name the caller typed does not say where the write actually lands.

Bad:
```python
print(f"writing report to {report_dir}")
```

Good:
```python
print(f"writing report to {report_dir.resolve()}")
```

### CR-J5: Self Locating Scripts
A script that only works from its own directory resolves its location and changes there before doing anything else. Depending on the caller's cwd makes the script work from one terminal and fail from another, and the failure names a missing file rather than the real cause. See BASH.md under New Scripts for the header to copy.

Bad:
```bash
make -C . release
```

Good:
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
make release
```
