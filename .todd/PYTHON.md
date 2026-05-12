# Python Coding Guidelines

Style rules for all Python code.

## Naming

- No abbreviated locals. Use `output` not `out`, `last_line` not `last`, `message` not `msg` in new code.
- Never use the `_path` suffix. Use `_file` or `_dir` for path variables, or the extension as the suffix (`_md`, `_txt`, `_json`). Example: `url_file`, `runtime_dir`, `readme_md`, `config_txt`. Not `url_path` or bare `url`.
- Name generic helpers after the binary or concept they wrap: a tmux pass-through is `tmux(...)`, not `run_tmux(...)` or `tmux_cmd(...)`.

## Arguments

- Use argparse instead of manual sys.argv handling.
- Use sensible defaults for optional arguments.
- Prefer system APIs (e.g. `pwd` module) over environment variables where available.

## Paths

- Use `Path` from `pathlib` for all filesystem paths instead of `os.path`.

## Control Flow

- Use explicit `return` statements in helpers. Multiple `return None, False` / `return output, True` paths are preferred over a single trailing expression.
- Hoist loop-invariant values out of the loop. If a value doesn't change between iterations, compute it once above the loop:

  ```python
  messages = result.get('messages') or []
  for message in messages:
      ...
  ```

  Not:

  ```python
  for message in (result.get('messages') or []):
      ...
  ```

- Hoist nested chains into named locals before they're used. Write:

  ```python
  blocks = message.get('blocks') or []
  text = (blocks[0].get('text', {}).get('text') or '') if blocks else ''
  lines = text.splitlines()
  first_line = lines[0].strip() if lines else ''
  ```

  Not:

  ```python
  first_line = ((message.get('blocks') or [{}])[0].get('text', {}).get('text') or '').splitlines()[0].strip()
  ```

## Lists Over Concatenation

When building a string from multiple parts (query params, command flags, CSV fields, etc.), collect the parts in a list and join. Do not concatenate with `\` line continuations or `+`.

```python
params = []
params.append(f"target_branch={target_encoded}")
params.append('state=all')
params.append('per_page=100')
params.append(f"page={page}")
endpoint = f"projects/{PROJECT_ID}/merge_requests?{'&'.join(params)}"

flags = []
flags.append('-v')
flags.extend(['-u', username])
flags.extend(['--timeout', str(timeout)])
result = run(' '.join(flags))
```

Not:

```python
endpoint = (f"projects/{PROJECT_ID}/merge_requests"
            f"?target_branch={target_encoded}"
            f"&state=all")
```

## Defensive Defaults

Apply defaults and conversions at the lookup site, not deferred to a later guard clause.

- `or []` immediately after a dict lookup that may be `None` and is about to be iterated.
- `or ''` immediately after a lookup so subsequent string methods don't blow up on `None`.
- Drop fallbacks when the caller guarantees the value. Use `os.environ['XDG_RUNTIME_DIR']` with no default; let it raise.
- Default and convert at each level that can be `None`, not once at the end.

## Code Structure

- Inline single-use logic instead of creating wrapper functions to keep code simple and avoid unnecessary indirection.

## Comments and Section Structure

- Use a small set of standard up-front headers, then describe the steps the code actually performs.
- Standard up-front sections, in this order when present: `ARGUMENTS`, `ENVIRONMENT`, `HELPERS`.
- After those, name each remaining section after the step it performs in the code (`GET MESSAGES`, `SEND MESSAGES`, `POLL`, etc.). If the main section is really small, just call it `MAIN` instead of describing what it does.
- Headers are all caps and no more than two words.
- Keep header order matching reading order.
- Each header is a `#` followed by a space and 78 `=` characters, then the title line, then another `#` and 78 `=` characters:

  ```
  # ==============================================================================
  # ENVIRONMENT
  # ==============================================================================
  ```
