# Code Review Rules

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
def configure_container():
    """
    Configures and initializes container settings.
    
    This function sets up the default container runtime environment
    and verifies that all prerequisites are satisfied.
    """
    init_runtime()
```

Good:
```python
def configure_container():
    # Container runtime is required across all execution targets.
    init_runtime()
```

### CR-A-5: External Permalinks
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
sig_id, job_id = re.match(r".*?/sigs/([^/]+)/.*?/jobs/([^/]+).*", full_url).groups()
```

Good:
```python
url_path = full_url.split("/sigs/", 1)[-1]
path_tokens = url_path.split("/")
sig_id = path_tokens[0]
job_id = path_tokens[1]
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











