# Code Review Rules

Rules are grouped by letter:

| Section | Covers |
|---|---|
| CR-A | Comments and documentation |
| CR-B | Formatting and readability |
| CR-C | Naming |
| CR-D | Simplicity and structure |
| CR-E | Errors and failure handling |
| CR-F | Arguments and CLI design |
| CR-G | Tests |
| CR-H | Security |

Per-language mechanics live in BASH.md and PYTHON.md. This file covers the review decisions that apply regardless of language.

### CR-A-1: Short Comments
Comments must be 2 lines maximum, 1 sentence per line. Keep comments short and direct. Never write paragraphs or multi-sentence explanations. If a comment exceeds 2 lines, shorten it or delete it.

Exception: Regex and parser comments are allowed additional lines to show concrete matching examples (inputs/outputs), and a permalink URL may be included on an additional line.

```python
# NFS dentry cache can hide a lock made on another host.
# 5s is the observed maximum staleness window.
time.sleep(5)
```

### CR-A-2: Obvious Comments
Delete comments that narrate the obvious. If a comment merely restates what the code plainly does, remove it completely. Do not shorten or rephrase it into a superficial explanation.

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

### CR-A-3: Parser Examples
Always include concrete example strings for regular expressions and string parsing logic. Provide an exact sample input line showing what is being matched or extracted.

Bad:
```python
# Parses error line
match = re.search(r"Cannot open directory (\S+)", line)
```

Good:
Adds an example line of the error string that it is parsing:
```python
# ERROR: Cannot open directory /scratch/user/run_123
match = re.search(r"Cannot open directory (\S+)", line)
```

### CR-A-4: Concise Docstrings
Prefer concise comments over multiline docstrings for simple functions or scripts. If the function is straightforward, explain the reason in a short comment rather than a verbose docstring block.

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

### CR-A-5: Usage Examples
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

### CR-A-6: External Permalinks
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

### CR-A-7: Trim Help Text
Keep help strings and descriptions short. If an example already shows the behavior, delete the prose restating it, and cut anything that only states common sense.

Bad:
```python
parser.add_argument("--format", help="The output format to use when writing the report. This controls whether the report comes out as JSON or as CSV. JSON is the default because most consumers expect it.")
```

Good:
```python
parser.add_argument("--format", choices=["json", "csv"], default="json", help="Report output format")
```

### CR-B-1: Break Expressions
Break long expressions and assign intermediate results to named variables instead of compressing logic into single lines or long list comprehensions.

Bad:
```python
results = [process(x, get_config(x)) for x in items if x.startswith("test_") and validate(x)]
```

Good:
```python
test_items = [x for x in items if x.startswith("test_")]
results = [process(x, get_config(x)) for x in test_items if validate(x)]
```

### CR-B-2: Clean Invocations
Avoid awkward multi-line splits for short command invocations or simple expressions. Keep them on a single line or extract arguments cleanly.

Bad:
```python
cmd = [
    "git",
    "status",
]
```

Good:
```python
cmd = ["git", "status", "--short"]
```

### CR-B-3: List Building
Build longer commands and argument collections by appending or extending a list instead of concatenating strings with line continuations or plus signs.

Bad:
```python
cmd = "git commit" + \
      f" -m '{message}'" + \
      " --no-verify"
```

Good:
```python
cmd = ["git", "commit"]
cmd.extend(["-m", message])
if bypass_hooks:
    cmd.append("--no-verify")
```

### CR-B-4: Step Parsing
Split text and path parsing into clean, sequential steps rather than building monolithic nested expressions or complex regex chains.

Bad:
```python
group_id, item_id = re.match(r".*?/groups/([^/]+)/.*?/items/([^/]+).*", full_url).groups()
```

Good:
```python
url_path = full_url.split("/groups/", 1)[-1]
path_tokens = url_path.split("/")
group_id = path_tokens[0]
item_id = path_tokens[1]
```

### CR-B-5: Vertical Spacing
Use one blank line between functions and keep related assignments aligned. Stacked blank lines and ragged columns make a file harder to scan than the code in it.

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

### CR-B-6: Top Imports
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

### CR-B-7: Section Headers
Name each section after the step the code performs, in all caps, three words maximum. Standard up-front sections come first in this order when present: `ARGUMENTS`, `ENVIRONMENT`, `HELPERS`.

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

### CR-B-8: Match The File
Follow the conventions already in the file you are editing. If every other function there returns a dict, do not introduce a dataclass for yours; consistency within one file beats your preferred style.

### CR-B-9: Plain Conditions
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

### CR-C-1: Specific Verbs
Name functions and helpers after specific, concrete actions or outputs rather than generic software abstractions.

Bad:
```python
def process_data(log_file):
    ...
```

Good:
```python
def extract_build_errors(log_file):
    ...
```

### CR-C-2: Plain Names
Avoid software buzzwords and abstract jargon in names. Use plain terms that describe the actual thing.

Bad:
```python
def orchestrate_artifact_pipeline(payload):
    ...
```

Good:
```python
def upload_build_artifacts(files):
    ...
```

### CR-C-3: Named Constants
Give limits, thresholds, and fixed keys an uppercase constant at the top of the file. Do not leave bare literals inline.

Bad:
```python
if len(fields) > 20:
    fields = fields[:20]
```

Good:
```python
MAX_METADATA_FIELDS = 20

if len(fields) > MAX_METADATA_FIELDS:
    fields = fields[:MAX_METADATA_FIELDS]
```

### CR-C-4: Prose Extensions
Use `.md` for prose files. A custom extension like `.prompt` loses syntax highlighting in editors and rendering in the web UI, for no benefit.

### CR-D-1: Inline Helpers
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

### CR-D-2: Direct Passthrough
Pass flags straight through to the underlying tool. Do not invent a custom boolean that maps onto a flag the tool already accepts.

Bad:
```python
def commit(message, skip_hooks=False):
    extra = ["--no-verify"] if skip_hooks else []
    run_git(["commit", "-m", message] + extra)
```

Good:
```python
def commit(message, git_args=None):
    cmd = ["commit"]
    cmd.extend(["-m", message])
    cmd.extend(git_args or [])
    run_git(cmd)
```

### CR-D-3: Delete Dead Code
Delete unused imports, commented-out blocks, and leftover scaffolding instead of leaving them behind. Do not keep code that nothing calls.

### CR-D-4: No Step Machinery
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

### CR-D-5: Existing Helpers
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

### CR-D-6: Cohesive Functions
Put the setup a function needs inside that function. If every caller has to remember a preparation step first, the step belongs in the function that owns the work.

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

### CR-D-7: Fewer Parameters
Do not take a parameter the caller already controls. Return the result instead of writing it somewhere, so the caller decides the destination and the function is testable without a filesystem.

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

### CR-D-8: Stay In Scope
Keep unrelated changes out of the change set. A bug fix does not need surrounding cleanup, and moving or renaming code you are not fixing buries the real change in the diff.

### CR-D-9: One Source
Define a value once. A constant declared in two files, or a default set in both the parser and the function it feeds, will drift, and the copy you forgot to change becomes the bug.

Bad:
The same default lives in two places:
```python
parser.add_argument("--timeout", type=int, default=30)

def fetch_report(timeout=30):
    ...
```

Good:
```python
DEFAULT_TIMEOUT_SECONDS = 30

parser.add_argument("--timeout", type=int, default=DEFAULT_TIMEOUT_SECONDS)

def fetch_report(timeout=DEFAULT_TIMEOUT_SECONDS):
    ...
```

### CR-D-10: No Speculation
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

### CR-D-11: No Nested Functions
Define functions at module level. A function nested inside another is invisible to tests and callers, and it usually only exists to reach a local it could have taken as a parameter. If it is genuinely reused, hoist it; if it is single-use, inline it per CR-D-1.

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

### CR-D-12: Parameterize Reuse
When a second caller needs the same code or data with a different value, take that value as an input instead of copying the file. Do this the moment the second caller exists, not speculatively (CR-D-10).

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

### CR-E-1: Guard Clauses
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

### CR-E-2: Bounded Retries
Retry a fixed number of attempts instead of looping forever, and back off exponentially rather than sleeping the same amount each time. Print the reason on every attempt so a stuck job is diagnosable from the log.

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
BACKOFF_BASE_SECONDS = 2

for attempt in range(1, MAX_ATTEMPTS + 1):
    try:
        run_build()
        break
    except TransientError as error:
        print(f"Attempt {attempt} of {MAX_ATTEMPTS} failed: {error}")
        if attempt == MAX_ATTEMPTS:
            raise
        backoff = BACKOFF_BASE_SECONDS * 2 ** (attempt - 1)
        time.sleep(backoff)
```

### CR-E-3: Loud Failures
Validate conflicting flags and missing prerequisites upfront and exit with a one-line message. Never let a bad configuration limp along silently.

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

### CR-E-4: Debug Context
Print the identifiers needed to debug a failure: job id, host, path, and command. A bare exit code or message with no context forces a second debugging round.

Bad:
```python
if "No space left on device" in log_text:
    sys.exit("ERROR: job failed, disk full")
```

Good:
The job runs on a remote node, so the host and mount are the only way to tell which disk filled:
```python
if "No space left on device" in log_text:
    sys.exit(f"ERROR: no space left on {hostname}:{mount_dir}, clean up that mount or rerun on another host")
```

### CR-E-5: Name The Cause
Say what kind of failure it was, not just that something failed. A run that started and never finished is an interrupted run, not a bad result, and the message should say so.

Bad:
```python
if not result_file.exists():
    sys.exit("ERROR: run failed")
```

Good:
```python
if not result_file.exists():
    sys.exit(f"ERROR: {run_name} started but never wrote {result_file} (it may have died before finishing)")
```

### CR-E-6: Boundary Validation
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
    config = yaml.safe_load(config_file.read_text())
    if "timeout" not in config:
        sys.exit(f"ERROR: {config_file} is missing required field 'timeout'")
    return config

def run_step(config):
    ...
```

### CR-E-7: Narrow Excepts
Never swallow an error you depend on succeeding. Catch the specific exception you expect, then exit or re-raise; a bare `except` hides the real failure and the next symptom shows up somewhere unrelated.

Prefer checking the condition upfront. Reach for `try` only when a check is not practical, as with a parse.

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

### CR-E-8: Always Timeout
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

### CR-F-1: Argument Grouping
Define every flag in `parse_args()` at the top of the file. Do not scatter argument handling into helpers or set defaults at the call site.

Bad:
```python
def fetch_report(timeout=None):
    if timeout is None:
        timeout = 30
```

Good:
```python
def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--timeout", type=int, default=30, help="Seconds to wait before giving up")
    return parser.parse_args()
```

### CR-F-2: Useful Defaults
Default a flag to whatever the tool is normally used for, and give the opposite a `--no-` form. Do not make the common case opt-in.

Bad:
```python
parser.add_argument("--debug", action="store_true", help="Keep the debug artifacts")
```

Good:
```python
parser.add_argument("--debug", action=argparse.BooleanOptionalAction, default=True, help="Keep the debug artifacts")
```

### CR-F-3: Argument Types
Declare `type=` on every value-taking argument that is not a string, since argparse otherwise hands back a string and numeric comparisons silently do the wrong thing.
Boolean flags are exempt: their action already produces a bool, and `type=bool` is wrong because `bool("False")` is `True`.

Bad:
```python
parser.add_argument("--timeout", default=30, help="Seconds to wait before giving up")
parser.add_argument("--config", help="Config file to read")
```

Good:
```python
parser.add_argument("--timeout", type=int, default=30, help="Seconds to wait before giving up")
parser.add_argument("--config", type=Path, help="Config file to read")
```

### CR-F-4: Group Derived Flags
Derive related state from the parsed arguments in one place near the top. Scattering the assignments through the script leaves the reader hunting for what turned a mode on.

Bad:
The two flags belong together but sit far apart:
```python
use_scheduler = args.scheduler is not None
...
use_remote = args.host is not None
```

Good:
```python
use_scheduler = args.scheduler is not None
use_remote = args.host is not None
```

### CR-G-1: Useful Tests
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

### CR-G-2: Reachable Features
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

### CR-H-1: Secret Passing
Never pass a secret as a command-line argument. It is visible to every user on the box in `ps -ef` and it lands in shell history. Pass it through the environment or stdin instead.

Bad:
```python
shell.run(["report-tool", "--token", api_token, "--upload", str(report_file)])
```

Good:
```python
env = os.environ | {"API_TOKEN": api_token}
shell.run(["report-tool", "--upload", str(report_file)], env=env)
```

### CR-H-2: No Shell True
Call subprocesses with a list and no `shell=True`. With a shell in the middle, any value you interpolate can inject its own commands.

Bad:
An `author` of `x; rm -rf ~` runs as a second command:
```python
subprocess.run(f"git log --author={author}", shell=True, check=True)
```

Good:
```python
subprocess.run(["git", "log", f"--author={author}"], check=True, text=True)
```

### CR-H-3: No Secret Flags
Do not give your own tool an option that takes a secret as its value, or every caller ends up leaking it in `ps -ef`. Accept a file path or read it from the environment instead.

Bad:
```python
parser.add_argument("--token", help="API token for the upload")
```

Good:
```python
parser.add_argument("--token-file", type=Path, help="File holding the API token; defaults to $API_TOKEN")
```

### CR-H-4: Secret Storage
Never persist a secret to a file your program creates. Reading one from an existing credential file is fine; writing one leaves it on disk after the run, where it can be committed, logged, or left world-readable.

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

Exception: a short-lived temp file is the right way to keep a secret off the command line, since `mktemp` creates it with owner-only permissions. Clean it up in a trap rather than at the end of the script.

```bash
header_file="$(mktemp)"
trap 'rm -f "$header_file"' EXIT
printf 'PRIVATE-TOKEN: %s\n' "$api_key" > "$header_file"
curl --silent --header @"$header_file" "$url"
```

When the script must `exec`, the trap never fires, so unlink the file up front and pass it by descriptor. The kernel reclaims the inode on exit:

```bash
config_file="$(mktemp --tmpdir curl-cfg.XXXXXX)"
chmod 600 "$config_file"
printf '%s\n' "${config_lines[@]}" > "$config_file"
exec {config_fd}<"$config_file"
rm -f "$config_file"
exec curl --config "/dev/fd/${config_fd}" "${safe_args[@]}"
```

















