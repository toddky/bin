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

Each rule is written for a reviewer reading one file or one diff. The first sentence says exactly what counts as a violation. The second says when the rule is followed, including when the code has nothing the rule applies to. Then comes why, and the Bad and Good examples.

## CR-A: Comments and documentation

### CR-A1: Short Comments
A violation is a comment block longer than 2 lines, a comment line wider than 120 columns, or a comment line holding more than one sentence. The rule is followed when every comment is 1 or 2 lines with one sentence per line. Lines that quote an example input (CR-A3), a usage example (CR-A6), a permalink on its own line (CR-A7), section header banners (CR-B8), and a script's USAGE and DESCRIPTION header lines do not count toward the limit. Why: a paragraph of comment stops being read and goes stale first.

```python
# NFS dentry cache can hide a lock made on another host.
# 5s is the observed maximum staleness window.
time.sleep(5)
```

### CR-A2: Obvious Comments
A violation is a comment that restates what the next line of code does, such as `# increment the counter` above a counter increment or `# wait 10 seconds` above `sleep 10`. The rule is followed when every comment gives a reason, gotcha, or intent the code cannot show by itself. The fix is to delete the comment, not to reword it.

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
A violation is a regular expression or string-parsing step, such as `grep -E`, `sed`, `awk`, `=~`, `re.search`, or a split on a delimiter, with no comment directly above it quoting a real input line it handles. The rule is followed when every pattern has an exact sample input line in a comment above it. Code with no regex or text parsing follows the rule. Why: the sample line is the only way to check a pattern without running it.

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
A violation is a multiline docstring on a short, simple function where a one-line comment would say the same thing. The rule is followed when simple functions carry at most a short comment. Code with no docstrings follows the rule.

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
A violation is a change that deletes an existing comment that is still true, or keeps a comment that the change made wrong. The rule is followed when existing comments survive and any the change made inaccurate are rewritten to match. This rule needs a diff; a whole file reviewed without history follows it. Why: a deleted comment throws away a reason nobody writes down twice.

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
A violation is a function whose inputs or outputs are not obvious from its name and parameters, with no one-line example call and result as its first comment. The rule is followed when such functions start with a comment like `# parse_duration("1h30m") -> 5400`. Functions whose behavior is obvious from the signature, and code with no functions, follow the rule.

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
A violation is code copied from or reproducing another project's behavior with no comment giving the upstream repository, pinned commit SHA, line number, and a permalink. The rule is followed when borrowed logic carries that comment. Code that borrows nothing follows the rule.

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
A violation is a help string or option description longer than a short phrase, or one that restates an example or states common sense. The rule is followed when help text is a few words, like `"Report output format"`. Code with no help text follows the rule.

Bad:
```python
parser.add_argument("--format", help="The output format to use when writing the report. This controls whether the report comes out as JSON or as CSV. JSON is the default because most consumers expect it.")
```

Good:
```python
parser.add_argument("--format", choices=["json", "csv"], default="json", help="Report output format")
```

### CR-A9: Explain Numbers
A violation is a number used as a timeout, sleep duration, retry count, size limit, or threshold with no comment saying where the value came from or that it is a guess. A comment that only repeats the number, like `# wait 10 seconds`, does not explain it. The rule is followed when every such number has a one-line comment giving its source. Why: nobody can safely tune a number when they do not know what it was tuned against.

Bad:
```python
MAX_ATTEMPTS = 3
```

Good:
```python
# 3 attempts covers the transient fetch failures seen in CI; beyond that it is a real break.
MAX_ATTEMPTS = 3
```

### CR-A10: Contents Match Headings
A violation is a table of contents that does not match the document: a link to an anchor no heading produces, a section left out, or entries in a different order from the headings. The rule is followed when every heading at the listed level has one entry, in document order, and each link is the heading's own anchor. A document with no table of contents follows the rule. Why: a dead link or missing entry sends the reader to the wrong place, and nobody notices because the file still renders.

Bad:
```markdown
- [Usage](#usage)
- [Directory Structure](#directory-structure)

## Usage
## Output Directory Structure
## Troubleshooting
```

Good:
```markdown
- [Usage](#usage)
- [Output Directory Structure](#output-directory-structure)
- [Troubleshooting](#troubleshooting)

## Usage
## Output Directory Structure
## Troubleshooting
```

## CR-B: Formatting and readability

### CR-B1: Break Expressions
A violation is one line that does several things at once: a comprehension that filters, transforms, and calls functions together, a call or command substitution nested inside another, or a chain of three or more calls. The rule is followed when intermediate results are assigned to named variables, one step per line.

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
A violation is a command or assignment inside a loop body whose result does not use the loop variable and so is the same on every pass, such as reading the same file or computing the same value each iteration. The rule is followed when such values are computed once above the loop. Code with no loops follows the rule. Why: inside the loop it hides the cost and reads as though it depends on the iteration.

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
A violation is a short command, call, or list split one item per line when it would fit on a single line. The rule is followed when short invocations sit on one line and long ones are built per CR-B4.

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
A violation is a command or argument list built by concatenating strings with `+`, `\` line continuations, or one long interpolated string. The rule is followed when the parts are collected in a list or array and appended one at a time. Code that builds no commands or argument lists follows the rule.

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
A violation is a single regex or nested expression that pulls several fields out of text, a URL, or a path at once. The rule is followed when parsing happens in small sequential steps, such as split, then pick fields, then validate. Code with no text or path parsing follows the rule.

Bad:
```python
group_id, item_id = re.match(r".*?/groups/([^/]+)/.*?/items/([^/]+).*", full_url).groups()
```

Good:
```python
# https://gitlab.example.com/api/v4/groups/42/-/items/7
path_tokens = urlparse(full_url).path.strip("/").split("/")
segments = dict(zip(path_tokens, path_tokens[1:]))
if "groups" not in segments or "items" not in segments:
    sys.exit(f"ERROR: {full_url} is not a group item URL, expected /groups/<id>/-/items/<id>")

group_id = segments["groups"]
item_id = segments["items"]
```

### CR-B6: Vertical Spacing
A violation is two or more blank lines in a row anywhere other than directly before a section header banner (CR-B8). The rule is followed when one blank line separates functions and blocks. When a formatter such as black or ruff owns the file, its spacing wins.

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
A violation is an import, `require`, or `source` statement anywhere other than the top of the file, such as inside a function or halfway down. The rule is followed when every import is at the top. Code with no imports follows the rule. Why: a buried import hides a dependency.

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
A violation is a section header banner whose title is not all caps, is longer than three words, or describes the code instead of naming the step; standard sections out of the order `IMPORTS`, `ARGUMENTS`, `ENVIRONMENT`, `HELPERS`; or step sections out of the order the code runs. The rule is followed when every banner is the language's comment marker plus 78 `=`, a short all-caps step name, and 78 `=` again. A small main section is called `MAIN`. Code with no section headers follows the rule, and Go uses doc comments instead of banners.

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

### CR-B9: Match The File
A violation is new code written in a different style from the rest of the same file, such as returning a dataclass where every other function returns a dict, or a naming or quoting style the file does not use. The rule is followed when new code matches the file's existing conventions. When the file conflicts with a rule here, the file wins for this change; fix the file in a separate change (CR-E3).

### CR-B10: Multi-line Text
A violation is fixed multi-line text, such as a help epilog, usage text, or a long message, built by joining a list of string literals with `'\n'.join([...])` or by `+` concatenation. The rule is followed when the text is one triple-quoted string. Joining lines computed at runtime follows the rule. A triple-quoted string reads exactly as it prints, with no quotes, commas, or separators in the way.

Bad:
```python
epilog = '\n'.join([
    'examples:',
    '  my-tool --input data.csv',
    '  my-tool --input data.csv --verbose',
])
```

Good:
```python
epilog = '''
examples:
  my-tool --input data.csv
  my-tool --input data.csv --verbose
'''
```

## CR-C: Naming

### CR-C1: Specific Plain Names
A violation is a function or helper named with a generic verb such as `process`, `handle`, `do`, or `manage`, or with jargon such as `orchestrate`, `pipeline`, or `payload`. The rule is followed when every name says the concrete action or output, like `extract_build_errors`. Code with no named functions follows the rule.

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
A violation is a limit, threshold, or fixed key written as a bare literal inside the logic instead of an uppercase constant at the top of the file. The rule is followed when such values are named constants. Argument-parser defaults are exempt, since the parser is already the single place the value lives (CR-E4), and so are 0, 1, and plain exit codes.

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
A violation is a variable or function whose name is a single letter or a shortened word, such as `r`, `q`, `cfg`, `msg`, `out`, or `tmp`. The rule is followed when names are full words, like `config_file` or `build_id`. A plain index loop variable (`i`, `j`) is allowed, and a name that mirrors an API, JSON, or CSV field keeps the field's own spelling, like `jobid`.

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
A variable holding a filesystem path is a violation when its name ends in `_path`, or says nothing about whether it is a file or a directory. The rule is followed when path names end in `_file`, `_dir`, or the extension, like `readme_md` or `config_json`. Code with no path variables follows the rule.

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
A violation is an integer count named with a `_count` suffix or a phrase like `jobs_seen` instead of a `num_` prefix. The rule is followed when every count is named like `num_failures`. Code with no counters follows the rule. Why: a `_count` name reads as a collection until the reader finds the assignment.

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
A violation is a pass-through wrapper around a tool named with decoration such as `run_`, `_cmd`, or `exec_`, like `run_tmux_cmd`. The rule is followed when the wrapper is named after the tool itself, like `tmux`. Code with no wrapper functions follows the rule.

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
A violation is a helper function called from exactly one place whose body is short enough to read inline. The rule is followed when short single-use logic is written at its call site. Code with no helper functions follows the rule.

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
A violation is a custom boolean option or parameter that only maps onto a flag the underlying tool already accepts, such as `skip_hooks=True` turning into `--no-verify`. The rule is followed when tool flags are passed straight through as arguments. Code that wraps no tool follows the rule.

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
A violation is new code that re-implements a call the repository or the same file already wraps in a helper. The rule is followed when existing wrappers are used. Why: a second copy drifts from the first and both have to be fixed later.

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
A violation is a function that needs every caller to run a preparation step first, or a single-use setup step given its own public name. The rule is followed when the setup lives inside the function that owns the work, and the module exposes only the functions other files call. Code with no functions follows the rule.

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
A violation is a function that takes a destination the caller already controls, such as an output file or stream, and writes its result there instead of returning it. The rule is followed when the function returns the result and the caller writes it. Code with no functions follows the rule.

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
A violation is a named function defined inside another function. The rule is followed when every function is defined at the top level of the file. Why: a nested function is invisible to tests and callers; hoist it if it is reused, or inline it per CR-D1 if not.

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
A violation is a file or block copied so a second caller can run the same code with a different hardcoded value. The rule is followed when the differing value is taken as a parameter. Do this once a second caller exists, not speculatively (CR-E5).

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
A violation is comparing a value against a literal boolean, such as `== True`, `is not False`, `== "true"`, or `[[ "$flag" == true ]]`. The rule is followed when the value is tested directly, or as an integer flag with `(( ))` in bash. Why: the comparison breaks the moment the value is `None` or an empty string.

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
A violation is a step table, list of step functions, dispatcher, or registry that drives a fixed sequence that always runs the same way. The rule is followed when the steps run in order under section headers (CR-B8). Code with no such table follows the rule.

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

### CR-D10: One Lookup
A violation is the same lookup or parsing step written out in two or more places, especially when the copies handle a missing input differently: one warns, one exits, one raises a traceback, one never checks. The rule is followed when the step lives in one helper that reports what is missing, and each caller decides whether that is fatal. Code that performs the step once follows the rule. Why: copies drift apart, so the same missing file gives a clear error in one command and a traceback in another.

Bad:
```python
def build(root=None):
    root = root or find_root()
    tool = root / 'bin' / 'my-tool'
    if not tool.exists():
        sys.exit(f"ERROR: {tool} not found")

def query(root=None):
    tool = (root or find_root()) / 'bin' / 'my-tool'
```

Good:
```python
def find_tool(root=None):
    root = Path(root) if root else find_root()
    tool = root / 'bin' / 'my-tool'
    if not tool.exists():
        raise FileNotFoundError(f"{tool} not found")
    return root, tool
```

## CR-E: Change hygiene

### CR-E1: Delete Dead Code
A violation is an unused import, variable, or function, a commented-out block of code, or leftover debug scaffolding. The rule is followed when everything in the code is used. Within a diff, this applies only to code the change touches (CR-E3).

### CR-E2: Reachable Features
A violation is a new branch for a value that the argument parser or enumeration does not allow, so the branch can never run. The rule is followed when the allowed values are updated in the same change as the new branch.

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
A violation is a change that includes unrelated edits, such as reformatting, renaming, or moving code it is not fixing. The rule is followed when every edit serves the change. This rule needs a diff; a whole file reviewed without history follows it.

### CR-E4: One Source
A violation is the same value defined in two places, such as a default set in both the argument parser and the function it feeds, or a constant declared in two files. The rule is followed when each value is defined once. For a CLI, the parser holds the default and the function takes the value as a required parameter.

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
A violation is an option, parameter, hook, or setting that no caller uses. The rule is followed when every option is used by a real caller. Why: the guess about future needs is usually wrong by the time a caller shows up.

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
A violation is an `if` nested inside another `if` to protect the main work, where the failure case could be checked first with an early `continue`, `next`, `return`, or `exit`. The rule is followed when failure checks come first and exit early, leaving the main path unindented.

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
A violation is a negated test on an exit or return value that exits early, followed by handling and a second exit repeating the same value, such as `if exit_code != TIMEOUT: exit(exit_code)` then handling then `exit(TIMEOUT)`. The rule is followed when the code tests the case it handles with `==` and falls through to one exit. Code that never passes through an exit code follows the rule.

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
A violation is a retry loop with no attempt limit, a retry that sleeps the same amount every time instead of backing off exponentially, or retries that do not print the failure reason to stderr. The rule is followed when retries are bounded, back off, and log each failed attempt. Code with no retries follows the rule.

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
A violation is a missing prerequisite or conflicting flag handled with a warning and then continuing, or an error message that names the failure without saying how to fix it. The rule is followed when such problems are checked upfront and exit with one line that ends with the remedy: what to create, which flag to pass, or which value to change.

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
A violation is an error message that does not say what kind of failure happened or leaves out the identifiers needed to debug it, such as which run, host, path, or value, like a bare `run failed`. The rule is followed when every error names the failure and the identifiers. A run that started and never finished is reported as interrupted, not as a bad result.

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
A violation is the same check on external input repeated in several functions instead of once where the input enters the program. The rule is followed when each input is validated once at its entry point.

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
    config = yaml.safe_load(config_file.read_text()) or {}
    if "timeout" not in config:
        sys.exit(f"ERROR: {config_file} is missing required field 'timeout'")
    return config

def run_step(config):
    ...
```

### CR-F7: Check Before Try
A violation is a `try`, `rescue`, or `except` used for a condition that could be tested upfront, such as catching file-not-found instead of checking that the file exists. The rule is followed when exceptions are caught only where a check is impractical, such as parsing or a network call. Code with no exception handling follows the rule.

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
A violation is a bare or broad catch that swallows an error and continues, such as `except:`, `except Exception`, a `rescue` with no error class, or `|| true` on a command whose success matters. The rule is followed when only the specific expected error is caught and the code then exits or re-raises. Code with no error catching follows the rule.

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
A violation is a network call, such as `curl`, `wget`, `ssh`, `requests.get`, or `Net::HTTP`, with no timeout option like `--max-time`, `--connect-timeout`, `timeout=`, or `read_timeout:`. The rule is followed when every network call sets an explicit timeout. Code with no network calls follows the rule. Why: most clients wait forever, so one unresponsive server hangs the job.

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
A violation is a flag defined outside the single argument-parsing block at the top of the file, a default set at a call site, or state derived from the arguments in several scattered places. The rule is followed when every flag is defined in one block at the top and derived state is computed right after it. Code with no command-line arguments follows the rule.

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
A violation is a flag that makes the common case opt-in, such as a `--cleanup` that is off unless passed when cleanup is what users normally want. The rule is followed when the default is the normal use and a `--no-` form turns it off. Code with no flags follows the rule.

Bad:
```python
parser.add_argument("--cleanup", action="store_true", help="Delete the scratch directory when done")
```

Good:
```python
parser.add_argument("--cleanup", action=argparse.BooleanOptionalAction, default=True, help="Delete the scratch directory when done")
```

### CR-G3: Argument Types
A violation is a value-taking argument that is not a string, such as a count or a path, declared without a type, so the parser hands back a string. Boolean flags are exempt, and `type=bool` is itself a violation because `bool("False")` is `True`. Code with no typed arguments follows the rule.

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
A violation is a test that only proves the language or a library works, or that repeats coverage another test already has. The rule is followed when every test would fail if the behavior it covers broke. Code with no tests follows the rule.

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
A violation is a password, token, or other secret passed as a command-line argument, such as `curl -u user:$PASSWORD`, `--token $TOKEN`, or `mysql -p$PASSWORD`; an option of your own tool that takes a secret as its value; or an error or log line that prints a secret unredacted. The rule is followed when secrets travel through the environment, stdin, or a file, and printed values have the secret part redacted (CR-F5). Code that handles no secrets follows the rule. Why: arguments are visible to every user in `ps -ef` and land in shell history.

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
A violation is a subprocess started through a shell with an interpolated string, such as `shell=True`, `os.system`, Ruby's `system` or backticks with one interpolated string, `eval`, or `bash -c "$command"`. The rule is followed when subprocesses take a list of arguments. In a bash script, running a command directly with quoted variables follows the rule. Code that starts no subprocesses follows the rule.

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
A violation is writing a secret to a file that outlives the run, such as caching a token on disk. The rule is followed when secrets stay in memory or are read fresh from an existing credential file each run. A `mktemp` file removed in an exit trap is allowed, since it is owner-only and gone when the run ends (BASH.md, Safety). Code that handles no secrets follows the rule.

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

## CR-J: Files

### CR-J1: Prose Extensions
A violation is a prose file given a custom extension, such as `.prompt`, instead of `.md`. The rule is followed when prose files end in `.md`. Code that creates or names no prose files follows the rule.

### CR-J2: XDG Locations
A violation is a config, cache, or runtime path hardcoded under the home directory, such as `~/.config/tool`, instead of using `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, or `XDG_RUNTIME_DIR` with the fallback stated next to it. The rule is followed when such paths come from the XDG variable. Code with no config, cache, or runtime files follows the rule.

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
A violation is writing to a fixed path under `/tmp`, such as `/tmp/output.txt`, instead of a path created by `mktemp` or `tempfile`, or removing a temp file on the last line instead of in an exit trap or context manager. The rule is followed when temp files are private and cleaned up when the process exits. Code with no temp files follows the rule. Why: a predictable name on a shared machine collides with another user's run.

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
A violation is writing to, or reporting the location of, a caller-supplied path without resolving symlinks first with `realpath`, `.resolve()`, or `File.realpath`. The rule is followed when such paths are resolved before use. Code that writes to and reports no caller-supplied paths follows the rule.

Bad:
```python
print(f"writing report to {report_dir}")
```

Good:
```python
print(f"writing report to {report_dir.resolve()}")
```

### CR-J5: Self Locating Scripts
A violation is a script that reads or runs files by a relative path, such as `./settings.ini`, `data/input.csv`, or `make -C .`, without first changing to its own directory with a `SCRIPT_DIR` line and `cd "$SCRIPT_DIR"`. The rule is followed when such scripts locate themselves first (see BASH.md, New Scripts). Scripts that use no relative paths follow the rule.

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
