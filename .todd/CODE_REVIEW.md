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

Per-language mechanics live in BASH.md, PYTHON.md, GO.md, RUBY.md, and JAVASCRIPT.md. This file covers the review decisions that apply regardless of language. Python examples assume 3.9 or newer.

Each rule is written for a reviewer reading one file or one diff. The first sentence says exactly what counts as a violation. The second says when the rule is followed, including when the code has nothing the rule applies to. Then comes why, and the Bad and Good examples.

## CR-A: Comments and documentation

### CR-A1: Short Comments
A violation is a comment block longer than 2 lines, a comment line wider than 120 columns, or a comment line holding more than one sentence. The rule is followed when every comment is 1 or 2 lines with one sentence per line. Lines that quote an example input (CR-A3), a usage example (CR-A6), a permalink on its own line (CR-A7), section header banners (CR-B9), and a script's USAGE and DESCRIPTION header lines do not count toward the limit. Why: a paragraph of comment stops being read and goes stale first.

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
A violation is a function that parses, formats, converts, or builds data, or whose result is not obvious from its name, with no example call and result at the top of its comment or docstring. The rule is followed when such functions start with a line like `parse_duration("1h30m") -> 5400`, plus one more line for an edge case worth showing. Functions whose result is plain from the name, like `is_empty(items)`, follow the rule. Why: one example shows what a function is for faster than a sentence describing it.

Bad:
```python
def parse_duration(text):
    ...
```

Good:
```python
def parse_duration(text):
    # parse_duration("1h30m") -> 5400
    # parse_duration("45s") -> 45
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

### CR-A11: Placeholder Examples
A violation is an example in a comment or doc that uses a real value the reader is meant to replace, such as a real commit SHA, job ID, or hostname. The rule is followed when such values are placeholders that name their role, like `<COMMIT>` or `<JOB_ID>`. Why: a real value looks authoritative, so the reader cannot tell whether to copy it or swap it.

Bad:
```python
# Usage: fetch_logs.py 4f9c2a1e
```

Good:
```python
# Usage: fetch_logs.py <COMMIT>
```

### CR-A12: Present Tense
A violation is a comment that tells the story of how the code came to be: what it used to do, what broke, who asked for it, or which ticket or merge request changed it. The rule is followed when the comment states the constraint as it holds now, with the date it was last checked when it describes something outside the code. Why: the history belongs in the commit message, and in a comment it goes stale as soon as the code changes again. The date tells the reader how old the claim is without digging through the log.

Bad:
```python
# Used to retry forever, but that hung the nightly job after the server move, so now we stop at 3.
MAX_ATTEMPTS = 3
```

Good:
```python
# As of 2026-10-15 the server drops connections after 3 failed handshakes, so more attempts never succeed.
MAX_HANDSHAKE_ATTEMPTS = 3
```

### CR-A13: TODOs Need A Reason
A violation is a new TODO or FIXME with no ticket and no reason it cannot be done now. The rule is followed when every new TODO names a ticket or the blocker, or the work is done in the same change. Why: a bare TODO never gets picked up, and later nobody can tell whether it still matters.

Bad:
```python
# TODO: support gzip
data = report_file.read_text()
```

Good:
```python
# TODO PROJ-123: support gzip once the exporter can write compressed reports.
data = report_file.read_text()
```

### CR-A14: Document Only Surprises
A violation is a README or doc sentence describing behavior every tool of its kind already has, such as a command-line tool printing to the terminal or stopping on Ctrl-C. The rule is followed when docs describe only what differs from that default, like a tool that detaches or writes to a file instead of the terminal. Why: readers skim past the obvious lines, and the one that matters gets skimmed with them.

Bad:
```markdown
Run `sync-reports` from a terminal. Output is printed to the terminal, and you can stop it with Ctrl-C.
```

Good:
```markdown
Run `sync-reports` from a terminal. It detaches after starting, so output goes to `~/.cache/sync-reports/sync.log`.
```

### CR-A15: Document Shape
A violation is a README or doc whose opening line does not say what kind of thing it describes, a section that relies on something explained later, or a heading in place of the usual word readers scan for. The rule is followed when the first line names the kind of thing, each section builds on the ones before it, and headings use the plain words like *Usage*, *Installation*, and *Configuration*. Why: readers decide from the first line whether a page is relevant, and then jump to the heading they expected.

Bad:
```markdown
# sync-reports

Uses the token from the setup step below.

## Running it

## Getting started
```

Good:
```markdown
# sync-reports

A command-line tool that copies finished reports to a shared directory.

## Installation

## Usage
```

## CR-B: Formatting and readability

### CR-B1: No Golfing
A violation is code written shorter at the cost of being harder to read, such as `and`/`or` chains used as an if-else, nested conditional expressions, or several assignments packed onto one line. The rule is followed when the plain version is used whenever it is easier to follow, even if it takes more lines. Why: code is read far more often than it is written, so every saved line costs each later reader.

Bad:
```python
label = error and f"failed: {error}" or skipped and "skipped" or "passed"
```

Good:
```python
if error:
    label = f"failed: {error}"
elif skipped:
    label = "skipped"
else:
    label = "passed"
```

### CR-B2: Break Expressions
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

### CR-B3: Hoist Out Of Loops
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

### CR-B4: Clean Invocations
A violation is a short command, call, or list split one item per line when it would fit on a single line. The rule is followed when short invocations sit on one line and long ones are built per CR-B5.

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

### CR-B5: List Building
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

### CR-B6: Step Parsing
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

### CR-B7: Vertical Spacing
A violation is two or more blank lines in a row anywhere other than directly before a section header banner (CR-B9). The rule is followed when one blank line separates functions and blocks. When a formatter such as black or ruff owns the file, its spacing wins.

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

### CR-B8: Top Imports
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

### CR-B9: Section Headers
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

### CR-B10: Match The File
A violation is new code written in a different style from the rest of the same file, such as returning a dataclass where every other function returns a dict, or a naming or quoting style the file does not use. The rule is followed when new code matches the file's existing conventions. When the file conflicts with a rule here, the file wins for this change; fix the file in a separate change (CR-E3).

### CR-B11: Multi-line Text
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

### CR-B12: Sets For Lookups
A violation is an `in` check against a list inside a loop, where the list is built once and only searched. The rule is followed when the list is turned into a set before the loop. Why: each check on a list scans every item, so the loop slows down with the square of the input size.

Bad:
```python
passed_names = [result.name for result in results if result.passed]
missing = [test for test in tests if test.name not in passed_names]
```

Good:
```python
passed_names = {result.name for result in results if result.passed}
missing = [test for test in tests if test.name not in passed_names]
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

### CR-C7: One Meaning
A violation is a name, in code or in an example, built on a word with a second meaning the reader could pick instead, such as `order` (a purchase, or a sort order), `key` (a dict key, or a credential), or `run` (a verb, or a past execution). The rule is followed when every name has only one reasonable reading in its surrounding code or prose. Why: the reader takes the wrong meaning first and then has to work out that the code does not do it.

Bad:
`order` reads as sort order, but the function only adds prices:
```python
def order_total(prices):
    return sum(prices)
```

Good:
```python
def cart_total(prices):
    return sum(prices)
```

### CR-C8: Derived Values
A violation is a literal number, in code or a comment, that is computed from another named constant, such as `8192` where the value means two pages of `PAGE_SIZE`. The rule is followed when the value is written as the expression or refers to the constant by name. Why: the literal stays the same when the constant changes, and nothing flags the mismatch.

Bad:
```python
# Default memory page size on Linux.
PAGE_SIZE = 4096
BUFFER_SIZE = 8192  # two pages
```

Good:
```python
# Default memory page size on Linux.
PAGE_SIZE = 4096
BUFFER_SIZE = PAGE_SIZE * 2
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
A violation is a custom boolean option or parameter that only maps onto a flag the underlying tool already accepts, such as `skip_hooks=True` turning into `--no-verify`. The rule is followed when tool flags are passed straight through as arguments. The wrapper keeps the user's flags in their original order and puts any flags of its own before a `--` separator, since the tool reads everything after `--` as a file or argument, not a flag. Code that wraps no tool follows the rule.

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
A violation is new code that re-implements a call the repository or the same file already wraps in a helper. The rule is followed when existing wrappers are used. The same applies to the standard library and well-known packages: use `shlex.quote`, `re.escape`, or `urllib.parse` rather than a hand-written version, which misses edge cases the library already handles. Why: a second copy drifts from the first and both have to be fixed later.

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
A violation is a step table, list of step functions, dispatcher, or registry that drives a fixed sequence that always runs the same way. The rule is followed when the steps run in order under section headers (CR-B9). Code with no such table follows the rule.

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

### CR-D11: Explicit Dependencies
A violation is a function that only works if another function ran first, with nothing in the code enforcing it, such as reading a global that a setup function fills in. The rule is followed when the function takes what it needs as a parameter, or checks for it and fails with a message naming the setup step. Why: the hidden dependency breaks silently the first time someone calls the function from a new place.

Bad:
`get_output_dir()` fails with a `NameError` unless `load_settings()` ran first:
```python
def load_settings(config_file):
    global SETTINGS
    SETTINGS = read_settings(config_file)

def get_output_dir():
    return SETTINGS["output_dir"]
```

Good:
```python
def get_output_dir(settings):
    return settings["output_dir"]
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
A violation is the same value defined in two places, such as a default set in both the argument parser and the function it feeds, or a constant declared in two files. The rule is followed when each value is defined once. When one rule has to exist in two places that can't share code, such as a filter written in both Python and SQL, each copy names the other in a comment and a test checks that both give the same answer. For a CLI, the parser holds the default and the function takes the value as a required parameter.

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

### CR-E6: Renames Update Every Reference
A violation is a change that renames or moves a file, function, flag, or setting and leaves a reference to the old name behind, such as a default argument, a README, a help string, or a test fixture. The rule is followed when a search for the old name finds nothing the change should have updated, or only references that must keep the old name, each listed with its reason in the commit message. Changes that rename nothing follow the rule. Why: a stale reference fails far from the rename, in a default nobody passes or a doc that sends the reader to a file that no longer exists.

Bad:
The script was renamed, but the default still points at the old name:
```python
# scripts/check-upload.py was renamed to scripts/verify-upload.py
parser.add_argument("--checker", default="scripts/check-upload.py")
```

Good:
```python
parser.add_argument("--checker", default="scripts/verify-upload.py")
```

### CR-E7: Opt In To Changed Defaults
A violation is a change to the default behavior of a function, endpoint, or flag that other callers use, with no opt-in parameter and not every caller checked. The rule is followed when the default stays the same and the new behavior sits behind a parameter, or when the commit message lists every caller and why the new default is right for each. Changes that leave every shared default alone follow the rule. Why: callers that never asked for the new behavior get it without anyone noticing.

Bad:
`get_orders` used to sort by id, and every other caller now gets the new order:
```python
def get_orders(customer_id):
    orders = load_orders(customer_id)
    return sorted(orders, key=lambda order: order.last_activity, reverse=True)
```

Good:
```python
def get_orders(customer_id, by_activity=False):
    orders = load_orders(customer_id)
    if by_activity:
        return sorted(orders, key=lambda order: order.last_activity, reverse=True)
    return sorted(orders, key=lambda order: order.id)
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
A violation is a retry loop with no attempt limit, a retry that sleeps the same amount every time instead of backing off exponentially, or retries that do not print the failure reason to stderr. The rule is followed when retries are bounded, back off, and log each failed attempt. An automatic retry runs only when the failed attempt changed nothing. A request that timed out may still have reached the server, so a post or send is not retried unless the server can tell a repeat from a new request. Code with no retries follows the rule.

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
A violation is the same check on external input repeated in several functions instead of once where the input enters the program. The rule is followed when each input is validated once at its entry point. A value handed to another program enters that program too, so the receiver checks it again at its own entry point instead of trusting the sender. A request or config with an unknown field is refused, not ignored, so a misspelled field name fails instead of quietly falling back to the default.

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
A violation is a bare or broad catch that swallows an error and continues, such as `except:`, `except Exception`, a `rescue` with no error class, `|| true` on a command whose success matters, or a lookup that reports every error as "not found". The rule is followed when only the specific expected error is caught and the code then exits or re-raises. Code with no error catching follows the rule.

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

### CR-F10: Check In The Write
A violation is a write that depends on a check made earlier in a separate step, such as reading a row and then updating it by id alone, or checking a rate limit and recording the attempt only after slow work. The rule is followed when the write repeats the check in its own condition, or the check and the write run inside one transaction or lock, and the code reports when the condition no longer holds; code with no such check-then-write follows the rule. Why: anything that changes in between is silently undone, and the bug only shows up under concurrent use, which normal tests never create.

Bad:
```python
ticket = db.get_ticket(ticket_id)
if ticket.status != "open":
    raise Conflict("ticket is closed")
query = "UPDATE tickets SET status = 'assigned', assignee = ? WHERE id = ?"
db.execute(query, user_id, ticket_id)
```

Good:
```python
query = "UPDATE tickets SET status = 'assigned', assignee = ? WHERE id = ? AND status = 'open'"
updated = db.execute(query, user_id, ticket_id)
if updated.rowcount == 0:
    raise Conflict("ticket changed while this request ran; reload and try again")
```

### CR-F11: Say The Side Effect Happened
A violation is a step after an irreversible action, such as posting, sending, or deploying, whose failure makes the program report that the whole operation failed. The rule is followed when any failure after the action says the action already happened and how to finish by hand, or when nothing that can fail runs after it. Code with no irreversible action follows the rule. Why: a caller told "failed" retries, and the retry repeats the action.

Bad:
A full disk raises after the post, so the caller sees an error and posts again:
```python
message_id = post_message(room_id, body)
save_sent_record(sent_file, message_id)
```

Good:
A full disk can only be detected by writing, so here the `except` is the check:
```python
message_id = post_message(room_id, body)
try:
    save_sent_record(sent_file, message_id)
except OSError as error:
    sys.exit(f"ERROR: posted message {message_id} but could not record it in {sent_file} ({error}); do not post again, add the id by hand")
```

### CR-F12: Kill The Process Group On Timeout
A violation is a timeout on a child process that can start children of its own, such as a shell script or a build tool, where the timeout kills only the direct child. The rule is followed when the child runs in its own process group and the timeout kills the whole group. The code keeps the child's pid until it has been waited for, so a cleanup that runs during a slow stop, such as on Ctrl-C, still finds and kills it. Code with no subprocess timeouts, or whose children start no processes, follows the rule. Why: the grandchildren keep running after the timeout and pile up with every run.

Bad:
`subprocess.run` kills only `check-tool`, and the processes it started keep running:
```python
subprocess.run(["./check-tool"], timeout=CHECK_TIMEOUT_SECONDS)
```

Good:
```python
process = subprocess.Popen(["./check-tool"], start_new_session=True)
try:
    process.wait(timeout=CHECK_TIMEOUT_SECONDS)
except subprocess.TimeoutExpired:
    os.killpg(process.pid, signal.SIGKILL)
    process.wait()
    sys.exit(f"ERROR: ./check-tool did not finish in {CHECK_TIMEOUT_SECONDS}s; run it by hand to see where it hangs")
```

### CR-F13: Check A Pid Before Signalling It
A violation is code that signals a pid read from a file without first confirming that the pid is still the same process that wrote it. The rule is followed when the pid file also records the process start time and the signaller compares it before signalling, or when the code only signals children it started and still holds a handle to. Code that sends no signals follows the rule. Why: pids are reused, so a stale pid file can signal an unrelated process, and a check on the command line alone still matches a second copy of the same program.

Bad:
```python
launcher_pid = int(pid_file.read_text())
os.kill(launcher_pid, signal.SIGUSR2)
```

Good:
A pid and its start time together name exactly one process:
```python
def get_start_time(pid):
    # The process can exit between any separate check and the read, so the read is the check.
    try:
        stat_text = Path(f"/proc/{pid}/stat").read_text()
    except FileNotFoundError:
        return None
    # The command name can hold spaces and parens; start time is field 22 of proc(5), the 20th after the name.
    return stat_text.rsplit(")", 1)[1].split()[19]

# In the launcher:
pid_file.write_text(f"{os.getpid()} {get_start_time(os.getpid())}\n")

# In the signaller:
launcher_pid, start_time = pid_file.read_text().split()
if get_start_time(launcher_pid) != start_time:
    sys.exit(f"ERROR: pid {launcher_pid} in {pid_file} is no longer the launcher; start the workflow again")
# A pid reused in the microseconds between this check and the kill still gets the signal; pidfd closes that gap.
os.kill(int(launcher_pid), signal.SIGUSR2)
```

### CR-F14: Record, Then Publish
A violation is notifying a worker or another process to run a job before saving the record that defines it. The rule is followed when the database or log entry commits first and the notification or enqueue happens second. Code that hands no work to another process follows the rule. Why: if notifying happens first and the save fails or crashes, a background worker picks up a job that has no record, no parameters, and no audit trail.

Bad:
The worker can wake and look up the job before its record exists:
```python
notify_worker(job_id)
db.save_job(job_id, payload)
```

Good:
```python
db.save_job(job_id, payload)
notify_worker(job_id)
```

### CR-F15: One Bad Item Does Not Fail The List
A violation is a loop over many independent items, such as files, hosts, or records, that stops the whole run when one item fails to read or parse. The rule is followed when a bad item is skipped or shown as broken with its name and reason, and the run fails as a whole only when the source itself fails, such as the directory being unreadable. Code that processes no list of independent items follows the rule. Why: one corrupt file hides every good result, and the person reading the output can't tell which item broke.

Bad:
One truncated JSON file makes the whole report exit with a traceback:
```python
for result_json in sorted(results_dir.glob("*.json")):
    results.append(json.loads(result_json.read_text()))
```

Good:
```python
for result_json in sorted(results_dir.glob("*.json")):
    try:
        results.append(json.loads(result_json.read_text()))
    except json.JSONDecodeError as error:
        print(f"WARNING: skipping {result_json}, not valid JSON: {error}", file=sys.stderr)
```

### CR-F16: Bound State Carried Between Runs
A violation is a file or table that a program reads at the start of each run and adds to at the end, such as a list of processed ids or a cache of past answers, with no limit on how old or how large it can get. The rule is followed when old entries are dropped by age or count, the limit has a comment saying where it came from, and the docs say how to reset the state by hand. Programs that keep nothing between runs follow the rule. Why: the file grows until every run slows down or runs out of space, and a bad entry stays forever because nothing ever removes it.

Bad:
Every id ever processed stays in the file, so after a year each run loads and saves millions of lines:
```python
seen_ids = set(seen_file.read_text().split())
...
seen_file.write_text("\n".join(seen_ids | new_ids))
```

Good:
```python
# Reports older than 30 days are archived upstream and never come back, so older ids can go.
SEEN_MAX_AGE_SECONDS = 30 * 24 * 3600

seen = json.loads(seen_file.read_text())
cutoff = time.time() - SEEN_MAX_AGE_SECONDS
seen = {report_id: seen_at for report_id, seen_at in seen.items() if seen_at > cutoff}
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

### CR-G4: Errors To Stderr
A violation is a script that prints warnings, errors, or progress to stdout. The rule is followed when stdout holds only the result and everything else goes to stderr. Why: anyone piping the output into another command gets the messages mixed into the data.

Bad:
Piping this into another command passes the skip message along as if it were a host name:
```python
for host in hosts:
    if not host.reachable:
        print(f"Skipping {host.name}: unreachable")
        continue
    print(host.name)
```

Good:
```python
for host in hosts:
    if not host.reachable:
        print(f"Skipping {host.name}: unreachable", file=sys.stderr)
        continue
    print(host.name)
```

### CR-G5: No Prompt Without A Terminal
A violation is a script that asks a question on stdin when stdin is not a terminal, such as under cron or in CI. The rule is followed when the script offers a flag like `--yes` and exits with an error naming that flag when it would otherwise prompt with no terminal. Why: with no terminal the prompt either hangs forever or reads an empty answer and takes a default nobody chose.

Bad:
```python
if input("Delete 40 files? [y/N] ") != "y":
    sys.exit(1)
```

Good:
```python
if not args.yes:
    if not sys.stdin.isatty():
        sys.exit("ERROR: refusing to delete without a terminal, pass --yes")
    if input("Delete 40 files? [y/N] ") != "y":
        sys.exit(1)
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

### CR-H2: Assert The Behavior
A violation is a test that runs code but asserts nothing, or asserts something that cannot fail or does not match what the test claims to check, such as a test named for sorting that only checks the length. The rule is followed when every test asserts the result it is named for. A test that expects an error or a non-zero exit also checks the message or field that says which error, so a failure for some other reason, such as broken setup, does not pass it. Code with no tests follows the rule. Why: a test that cannot fail reports a pass whether the code works or not.

Bad:
The name promises sorted output, but any list of three items passes:
```python
def test_sort_records():
    result = sort_records([3, 1, 2])
    assert len(result) == 3
```

Good:
```python
def test_sort_records():
    assert sort_records([3, 1, 2]) == [1, 2, 3]
```

### CR-H3: Names Match Bodies
A violation is a test whose name describes a different case or outcome than the body checks, such as a name that says "rejects" over a body that asserts success. The rule is followed when reading only the test name tells you what input the body uses and what it asserts. Code with no tests follows the rule. Why: the test name is what shows up in a failure report, so a wrong name sends the reader to debug the wrong behavior.

Bad:
The name says empty input is rejected, but the body checks a normal value:
```python
def test_parse_port_rejects_empty():
    assert parse_port("8080") == 8080
```

Good:
```python
def test_parse_port_rejects_empty():
    with pytest.raises(ValueError):
        parse_port("")
```

### CR-H4: Observable Behavior
A violation is a test that asserts on how the code works instead of what it produces: call counts on mocks, private attributes, or the order of internal calls. A test that mocks every interesting part and then checks the mocks were called is the same violation. The rule is followed when the test asserts on return values, raised errors, files written, or other output a caller can see. Mocks are fine at the edges, such as a network call. Code with no tests follows the rule. Why: a test tied to internals breaks on every correct refactor and still passes when the output is wrong.

Bad:
This passes even if the total is wrong, and fails if the loop is rewritten:
```python
def test_cart_total():
    with patch("cart.add_price") as add_price:
        cart_total([10, 20])
    assert add_price.call_count == 2
```

Good:
```python
def test_cart_total():
    assert cart_total([10, 20]) == 30
```

### CR-H5: Private Test Files
A violation is a test that writes to a fixed path or reads files another test left behind. The rule is followed when every file the test touches is under its own temp directory. Why: two copies running at once overwrite each other, and a stale file can make a broken test pass.

Bad:
```python
def test_save_results():
    save_results("/tmp/results.json", [1, 2])
    assert json.loads(Path("/tmp/results.json").read_text()) == [1, 2]
```

Good:
```python
def test_save_results(tmp_path):
    results_json = tmp_path / "results.json"
    save_results(results_json, [1, 2])
    assert json.loads(results_json.read_text()) == [1, 2]
```

### CR-H6: No Real Network
A violation is a unit test that makes a real network call. The rule is followed when the call is replaced with a stub that returns a fixed response. Tests marked as integration tests are exempt. Why: the test fails whenever the server is slow or down, which the change did not cause.

Bad:
```python
def test_latest_version():
    assert latest_version("https://example.com/releases") == "2.1.0"
```

Good:
```python
def test_latest_version(monkeypatch):
    monkeypatch.setattr(releases, "fetch_json", lambda url: [{"version": "2.1.0"}])
    assert latest_version("https://example.com/releases") == "2.1.0"
```

### CR-H7: Fixed Clock
A violation is a test whose result depends on today's date, the current time, or how long a step takes. The rule is followed when the test passes the time in or freezes the clock. A test that must check how run time grows compares sizes far apart with a wide ratio, such as allowing 16 times the time for 8 times the input, where quadratic work takes 64 times. Why: a time-dependent test passes today and fails at midnight, at month end, or on a slow machine.

Bad:
This passes until 2030:
```python
def test_is_expired():
    assert not is_expired(expires=datetime(2030, 1, 1))
```

Good:
```python
def test_is_expired():
    assert not is_expired(expires=datetime(2030, 1, 1), now=datetime(2029, 12, 31))
```

### CR-H8: Red-Green Fixes
A violation is a bug fix with no test that fails without it. The rule is followed when the fix is done red-green-refactor: a test that reproduces the bug fails first (red), the fix makes it pass (green), and any cleanup keeps it passing (refactor). Why: a test written after the fix may never have failed, so nobody knows it catches the bug.

Bad:
The empty-input fix ships with no test:
```python
def average(values):
    if not values:
        return 0
    return sum(values) / len(values)
```

Good:
The test was written first and failed with `ZeroDivisionError` until the fix went in:
```python
def test_average_of_empty_list_is_zero():
    assert average([]) == 0
```

### CR-H9: No Leaked State
A violation is a test whose result depends on the host or on what another test left behind: environment variables, the current directory, module globals, or which tools are installed. The rule is followed when the test sets what it needs itself, through fixtures that undo the change afterward. Why: the test passes on the author's machine and fails in CI, or fails only when it runs after one particular test.

Bad:
Fails on any machine that sets `XDG_CACHE_HOME`:
```python
def test_default_cache_dir():
    assert default_cache_dir() == Path.home() / ".cache" / "my-tool"
```

Good:
```python
def test_default_cache_dir(monkeypatch, tmp_path):
    monkeypatch.delenv("XDG_CACHE_HOME", raising=False)
    monkeypatch.setenv("HOME", str(tmp_path))
    assert default_cache_dir() == tmp_path / ".cache" / "my-tool"
```

### CR-H10: Property Tests For Untrusted Input
A violation is code that parses, renders, or sanitizes input from outside the program, such as a Markdown renderer or a query parser, whose tests are only hand-picked example inputs. The rule is followed when a seeded random test also feeds it many generated inputs and asserts a property on every output, such as "never throws" or "every attribute value is quoted and free of markup"; code that handles no outside input follows the rule. Why: each fix for one bad input can open a hole for the next, and hand-picked examples only find the holes someone thought of.

Bad:
Two attacks someone thought of; a third that nests a link inside a URL still gets through:
```python
def test_render_escapes_script():
    assert "<script>" not in render_comment("<script>x</script>")

def test_render_blocks_javascript_links():
    assert 'href="javascript:' not in render_comment("[x](javascript:alert(1))")
```

Good:
```python
COMMENT_PIECES = ["<script>", "[link](", "https://x.com", ")", "`", "**", "\n", "plain text"]

def test_render_output_is_safe_for_any_comment():
    fixed_rng_seed = 42
    generator = random.Random(fixed_rng_seed)
    # 2000 comments render in under a second and cover combinations nobody writes by hand.
    for _ in range(2000):
        comment = "".join(generator.choices(COMMENT_PIECES, k=generator.randint(1, 50)))
        html = render_comment(comment)
        assert is_safe_html(html), f"unsafe output for {comment!r}"
```

### CR-H11: One Test Per Condition
A violation is a check with several conditions, such as an access rule that allows admins, public items, or listed readers, or several filters spread across functions that together keep one user's data from another, whose tests cover only some of them. The rule is followed when each condition has a test that passes only because of that condition, so removing the condition makes that test fail; code with no multi-condition check follows the rule. Why: a dropped condition still leaves a passing suite, so a refactor can quietly remove access, or grant it, with nobody noticing.

Bad:
Deleting `user.is_admin` or `document.is_public` from the rule leaves this test passing:
```python
def can_view(user, document):
    return user.is_admin or document.is_public or user.id in document.reader_ids

def test_can_view():
    assert can_view(reader, private_document)
    assert not can_view(stranger, private_document)
```

Good:
```python
def test_admin_can_view_private_document():
    assert can_view(admin, private_document)

def test_anyone_can_view_public_document():
    assert can_view(stranger, public_document)

def test_listed_reader_can_view_private_document():
    assert can_view(reader, private_document)

def test_stranger_cannot_view_private_document():
    assert not can_view(stranger, private_document)
```

### CR-H12: Tests Fail, They Do Not Hang
A violation is a test that waits forever when the code under test breaks, such as one that runs a command, reads from a pipe or FIFO, or waits on a child process with no deadline. The rule is followed when every step that can block runs under a deadline, and missing the deadline kills what the test started (CR-F12) and fails the test. Tests with no step that can block follow the rule. Why: a hung suite looks like a slow suite, and nobody learns which test broke.

Bad:
If `sync-reports` stops exiting, this test and the whole suite hang:
```python
def test_sync_reports_exits_cleanly(tmp_path):
    result = subprocess.run(["./sync-reports", str(tmp_path)])
    assert result.returncode == 0
```

Good:
```python
# As of 2026-10-21 sync-reports finishes in under 1s; 10s leaves room for a loaded CI host.
SYNC_TIMEOUT_SECONDS = 10

def test_sync_reports_exits_cleanly(tmp_path):
    process = subprocess.Popen(["./sync-reports", str(tmp_path)], start_new_session=True)
    try:
        returncode = process.wait(timeout=SYNC_TIMEOUT_SECONDS)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGKILL)
        process.wait()
        pytest.fail(f"sync-reports did not exit in {SYNC_TIMEOUT_SECONDS}s")
    assert returncode == 0
```

### CR-H13: Match The Stable Part Of Tool Output
A violation is a test that matches another tool's full output word for word, such as a compiler error or a query plan, or a check that output must not contain something, loosened until bad output passes it. The rule is followed when the test matches only the words that carry the meaning, each must-not-contain check still fails on the output it exists to catch, and output from your own program is still matched exactly (CR-H2). Tests that check no other tool's output follow the rule. Why: an exact match on text you don't control breaks on another machine or the next upgrade, and a check loosened too far passes on the bug it was written for.

Bad:
GNU `cp` uses curly quotes in a UTF-8 locale and macOS `cp` uses none, so this passes on one machine only:
```python
def test_copy_reports_missing_file(tmp_path):
    result = run_backup(tmp_path / "missing.txt")
    assert result.stderr == "cp: cannot stat 'missing.txt': No such file or directory\n"
```

Good:
```python
def test_copy_reports_missing_file(tmp_path):
    result = run_backup(tmp_path / "missing.txt")
    assert "missing.txt" in result.stderr
    assert "No such file or directory" in result.stderr
```

### CR-H14: Old-Version Fixtures Come From Old Code
A violation is a test that fakes an older version of saved data, such as a database or config file, by changing the version number on data the current code created. The rule is followed when the fixture is built the way the older version built it, such as running only the migrations up to that version or loading a file the old release wrote. Tests with no old-version fixtures follow the rule. Why: the faked fixture already has everything added since that version, so the upgrade under test runs on data that already has the change and passes whether or not it works.

Bad:
The database already has every column added since version 1, so the upgrade has nothing to do and the test passes either way:
```python
def test_upgrade_from_v1(tmp_path):
    db = create_database(tmp_path / "app.db")
    db.execute("PRAGMA user_version = 1")
    upgrade(db)
    assert "email" in get_column_names(db, "users")
```

Good:
```python
def test_upgrade_from_v1(tmp_path):
    db = create_database(tmp_path / "app.db", up_to_version=1)
    upgrade(db)
    assert "email" in get_column_names(db, "users")
```

### CR-H15: Test Runners Find Tests By Pattern
A violation is a test target, such as a Makefile rule or a CI step, that names each test file it runs. The rule is followed when the target runs every file matching the naming pattern, such as `tests/test_*.py`, so a new test file runs without anyone editing the target. Repos with no test target follow the rule. Why: a list of names silently skips every test file added after it, and the suite keeps passing while new tests never run.

Bad:
`test_upload.py` was added later and never runs:
```make
test:
	python -m pytest tests/test_config.py tests/test_report.py
```

Good:
```make
test:
	python -m pytest tests/
```

### CR-H16: Add Tests To The Existing Suite
A violation is a change that adds a new test file for a small fix or feature when a test file for the same code already exists. The rule is followed when the new cases go into the existing file, and a new file starts only for new code or when the existing file would need setup the new tests don't share. Changes that add no tests follow the rule. Why: a test file per change scatters the tests for one piece of code across the repo, so the next person has to find them all before they can change it.

Bad:
```text
tests/test_report.py
tests/test_report_empty_input.py
tests/test_report_utf8.py
```

Good:
```text
tests/test_report.py
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

### CR-I4: No Nested Repetition In Regexes
A violation is a regex run on input from outside the program that repeats a group which itself repeats, such as `(a+)+` or `([a-z0-9]+\.?)+`, or that repeats alternatives that can match the same text, such as `(a|ab)*`. The rule is followed when every part of the pattern can match a given piece of text in only one way; code with no regex on outside input follows the rule. Why: when such a pattern fails to match, the regex engine tries every way to split the text before giving up, so a short crafted string can take seconds or hang.

Bad:
A 27-character address ending in "!" takes 2 seconds to reject, and each extra character doubles it:
```python
COMPANY_EMAIL_PATTERN = re.compile(r"^([a-z0-9]+\.?)+@example\.com$")
```

Good:
Every repeated part starts with a dot, so a run of letters can only be matched one way:
```python
COMPANY_EMAIL_PATTERN = re.compile(r"^[a-z0-9]+(\.[a-z0-9]+)*@example\.com$")
```

### CR-I5: Linear Work On Untrusted Input
A violation is a loop over input from outside the program that recounts, rescans, or copies the whole input on every pass, or code whose output can grow far faster than its input, such as a table renderer that repeats a wide header for every row, with no cap on the output size. The rule is followed when the loop counts any total once before it starts and updates it as it goes, and output that can grow faster than the input stops at a stated size; code that handles no outside input follows the rule. Why: the work grows with the square of the input, so one oversized message takes seconds to process and stalls everyone who loads it, while tests with normal-sized input never notice.

Bad:
Every pass re-encodes the whole comment to measure it, so trimming a 136 KB comment to a 200-byte preview takes 2 seconds:
```python
def preview(comment, max_bytes):
    while len(comment.encode()) > max_bytes:
        comment = comment[:-1]
    return comment
```

Good:
```python
def preview(comment, max_bytes):
    num_bytes = len(comment.encode())
    end = len(comment)
    while num_bytes > max_bytes:
        end -= 1
        num_bytes -= len(comment[end].encode())
    return comment[:end]
```

### CR-I6: Least-Privilege Credentials
A violation is code that holds a credential with more power than its job needs and limits itself in its own code, such as a report that only reads but logs in to the database as an admin and checks each query itself. The rule is followed when the credential itself is limited, through a token scoped to the job or an account the server restricts; code that holds no credentials follows the rule. Why: a limit in the caller's code disappears with one bug or one tricked agent, while a limit on the credential holds no matter what the code does.

Bad:
The admin login can drop tables; only the prefix check stands in the way, and `SELECT 1; DROP TABLE orders` passes it:
```python
def run_report(query):
    if not query.lstrip().upper().startswith("SELECT"):
        raise PermissionError("reports may only read")
    return connect(user="admin", password=os.environ["ADMIN_PASSWORD"]).execute(query)
```

Good:
The `report_reader` account can only read, and the database refuses anything else:
```python
def run_report(query):
    return connect(user="report_reader", password=os.environ["REPORT_READER_PASSWORD"]).execute(query)
```

### CR-I7: Secrets Out Of Output
A violation is printing a password, token, or other secret to the terminal or a log, including in error messages and debug output. The rule is followed when the output names the account or where the secret is kept but never contains the secret itself; code that prints no secrets follows the rule. Why: terminal scrollback, screen shares, recordings, and CI logs keep whatever was printed, long after the run ends.

Bad:
```python
log.info("connecting to %s with token %s", api_url, api_token)
```

Good:
```python
log.info("connecting to %s as %s", api_url, account_name)
```

### CR-I8: Same Answer For Unknown Accounts
A violation is a login, password reset, or lookup by name that answers an unknown account differently from a real account with a wrong password, whether in the message, the status, the response time, or a lockout only real accounts can reach. The rule is followed when an unknown name gets the same answer, takes as long, and counts toward the same rate limit; code with no lookup by account name follows the rule. Why: any difference tells an attacker which accounts exist, which is the first step to guessing their passwords.

Bad:
Each failure tells the caller something different, and an unknown name returns before the slow password check:
```python
def log_in(username, password):
    user = db.find_user(username)
    if user is None:
        raise Unauthorized("no such user")
    if is_locked_out(user.id):
        raise TooManyRequests("try again later")
    if not bcrypt.checkpw(password, user.password_hash):
        raise Unauthorized("wrong password")
    return user
```

Good:
```python
# Hashed at the same cost as real passwords, so an unknown name takes as long to reject.
UNKNOWN_USER_HASH = bcrypt.hashpw(b"no account has this password", bcrypt.gensalt())

def log_in(username, password):
    account_key = username.lower()
    if is_locked_out(account_key):
        raise TooManyRequests("try again later")
    record_attempt(account_key)
    user = db.find_user(username)
    password_hash = user.password_hash if user else UNKNOWN_USER_HASH
    password_matches = bcrypt.checkpw(password, password_hash)
    if user is None or not password_matches:
        raise Unauthorized("wrong username or password")
    return user
```

### CR-I9: Cap Captured Output
A violation is capturing a child process's output into memory with no size limit, such as `capture_output=True` on a tool the code does not control. The rule is followed when the output goes to a temp file and only up to a stated limit is read back, and anything past the limit is refused with a message saying so. Code that captures no child output follows the rule. Why: one runaway child prints gigabytes and pushes a long-running server out of memory.

Bad:
```python
output = subprocess.run(["./check-tool"], capture_output=True).stdout
```

Good:
```python
# As of 2026-10-21 the largest report check-tool prints is ~40 KB, so 1 MB is far past it.
MAX_OUTPUT_BYTES = 1_000_000

with tempfile.TemporaryFile() as output_file:
    subprocess.run(["./check-tool"], stdout=output_file)
    output_file.seek(0)
    output = output_file.read(MAX_OUTPUT_BYTES + 1)
if len(output) > MAX_OUTPUT_BYTES:
    sys.exit(f"ERROR: ./check-tool printed more than {MAX_OUTPUT_BYTES} bytes; run it by hand to see why")
```

### CR-I10: Build Paths From Stored Names
A violation is a file path built from a name the caller sent, such as `REPORTS_DIR / name`, when the code looked up the record some other way, or a stored name used in a path without checking it is one plain path part. The rule is followed when the path uses the name saved in the record and the code refuses a name that is empty, `.`, `..`, or contains `/`. Code that builds no paths from names follows the rule. Why: a case-insensitive lookup finds `alice` from `Alice` and then reads the wrong folder, and a name like `..` climbs out of the directory.

Bad:
The lookup ignores case, so `Alice` finds user `alice` and then lists an empty `Alice/` folder:
```python
user = db.find_user(name)
report_dir = REPORTS_DIR / name
```

Good:
```python
user = db.find_user(name)
if user.name in ("", ".", "..") or "/" in user.name:
    sys.exit(f"ERROR: user name {user.name!r} is not a plain directory name; rename the account")
report_dir = REPORTS_DIR / user.name
```

### CR-I11: Refuse Links And Special Files In Shared Directories
A violation is opening a file in a directory that other users or processes can write to without refusing symlinks, hard links, and anything that is not a regular file. The rule is followed when the open uses no-follow and non-blocking flags, and a check on the open file confirms it is a regular file with one link and the expected owner. Code that opens no files in shared directories follows the rule. Why: a planted link makes the code read or overwrite any file its account can reach, a hard link gets past no-follow, and a named pipe hangs the reader forever.

Bad:
Anyone who can write to `shared_dir` can make `run.log` a link to a private file, or a pipe that never answers:
```python
log_text = (shared_dir / "run.log").read_text()
```

Good:
A symlink makes the open itself fail; the `fstat` check catches hard links, pipes, and files owned by someone else:
```python
log_fd = os.open(shared_dir / "run.log", os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
log_stat = os.fstat(log_fd)
if not stat.S_ISREG(log_stat.st_mode) or log_stat.st_nlink != 1 or log_stat.st_uid != os.getuid():
    os.close(log_fd)
    sys.exit(f"ERROR: {shared_dir}/run.log is a link or special file, or not yours; delete it and rerun")
with os.fdopen(log_fd) as log_file:
    log_text = log_file.read()
```

### CR-I12: No Wildcards In User Searches
A violation is a value from a user placed inside a pattern language, such as a search term in SQL `LIKE`, a filename in a glob, or text in a regex, where its wildcards still act as wildcards. The rule is followed when the code uses a plain substring or equality match instead, such as SQLite's `instr`, or escapes the value with the library's own function, such as `re.escape` or `glob.escape`. Code that puts no user values into patterns follows the rule. Why: a search for `run_1` also matches `run11`, and a search for `%` matches every row.

Bad:
Searching for `run_1` also matches `run11` and `run21`:
```python
db.execute("SELECT name FROM reports WHERE name LIKE ?", (f"%{search}%",))
```

Good:
```python
db.execute("SELECT name FROM reports WHERE instr(name, ?) > 0", (search,))
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

### CR-J6: Ids That Name Files Are Never Reused
A violation is a file or cache entry named after a row id from a table that can hand a deleted row's id to a new row, such as an SQLite `INTEGER PRIMARY KEY` without `AUTOINCREMENT`. The rule is followed when those ids are never reused, or the name also includes something unique such as a content hash; code that names no files after row ids follows the rule. Why: after a delete, the next insert can get the same id, and cleaning up the old row's file deletes the new row's file.

Bad:
Delete the newest upload and the next one gets its id, so cleaning up the old file can remove the new one:
```sql
CREATE TABLE uploads (id INTEGER PRIMARY KEY, filename TEXT NOT NULL);
-- each file is stored at uploads/<id>
```

Good:
```sql
CREATE TABLE uploads (id INTEGER PRIMARY KEY AUTOINCREMENT, filename TEXT NOT NULL);
-- each file is stored at uploads/<id>
```

### CR-J7: Name A File For Its Purpose
A violation is a file named after how it works instead of what it is for, such as `curl-loop.sh` for a script that waits until a deploy finishes. The rule is followed when someone who has never opened the file can tell from its name why they would run or read it. Changes that add or rename no files follow the rule. Why: the mechanism is the part most likely to change, and a listing of mechanism names makes the reader open every file to find the one they need.

Bad:
```text
scripts/curl-loop.sh
scripts/parse.py
```

Good:
```text
scripts/wait-for-deploy.sh
scripts/extract-build-errors.py
```

### CR-J8: Replace Files By Rename
A violation is code that overwrites a file other code reads, such as a config, a state file, or a published report, by writing to the final name directly. The rule is followed when the content goes to a new temp file in the same directory, is renamed over the final name, and the temp file is removed if anything fails first. When the file is a program or config that a running service loads, the previous copy is kept until the new one has started and stayed up, so a version that crashes at start can be put back. Code that writes no files others read follows the rule. Why: a crash or a full disk halfway leaves half a file under the real name, and a reader that opens it mid-write sees a partial file.

Bad:
```python
state_file.write_text(json.dumps(state))
```

Good:
```python
temp_fd, temp_name = tempfile.mkstemp(dir=state_file.parent)
try:
    # mkstemp creates the file 0600; as of 2026-10-21 other users read this file, so 0644 keeps it readable to them.
    os.fchmod(temp_fd, 0o644)
    with os.fdopen(temp_fd, "w") as temp_file:
        json.dump(state, temp_file)
    os.replace(temp_name, state_file)
finally:
    # After a successful replace the temp name is gone, so this only cleans up a failed write.
    Path(temp_name).unlink(missing_ok=True)
```
