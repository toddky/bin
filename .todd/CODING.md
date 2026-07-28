# General Coding Guidelines

Rules that hold across languages. Language files (BASH.md, PYTHON.md, GO.md, RUBY.md) add syntax-specific detail on top of this.

## Naming

- No abbreviated locals. Use `output` not `out`, `message` not `msg`, `last_line` not `last` in new code.
- Never use a `path`/`Path` suffix on a variable. Use a `file`/`dir` suffix, or the extension as the suffix (`readme_md`, `config_json`). Not `url_path` or bare `url`.
- Use a `num`/`num_` prefix for integer counts: `num_passes`, `num_failures`. Not `<thing>_count` or `<thing>s_seen`.
- API and wire field names (JSON keys, server fields, struct tags) keep their original spelling even if abbreviated: `jobid`, `sigid`, `tool_use_id`. This keeps grep across server and client code trivial; the no-abbreviation rule does not apply to direct field mirrors.
- Name generic helpers after the binary or concept they wrap: a tmux pass-through is `tmux(...)`, not `run_tmux(...)` or `tmux_cmd(...)`.
- No single-letter variable names. Use descriptive names (`result` not `r`); plain index loops (`i`, `j`) are the only exception.

## Control Flow

- Use guard clauses (early `return`/`continue`) to reduce nesting instead of wrapping the happy path in an `if` block.
- Handle the specific case you care about first, then fall through to a single pass-through path. Test for the case you handle, not its negation — the negated form inverts the logic and reads worse.
- Hoist loop-invariant values out of the loop; compute once above the loop, not on every iteration.
- Hoist nested chains into named locals before use. Each step gets a name instead of one dense expression.

## Building Strings, Args, and Commands

When assembling a string or command from multiple parts (flags, query params, CSV fields), collect the parts in an array/list/slice and join or pass it directly. Do not concatenate with `+`, string interpolation chains, or line-continuation backslashes.

## Code Structure

- Inline single-use helpers unless the logic is genuinely complex or meaningfully reused elsewhere.
- Keep exported/public surface small; fold one-off steps into the function that needs them.

## Error Handling

- Check for the error condition upfront where practical (test for the state, not just catch the failure).
- Fail early and loud with descriptive messages that include what was attempted and the relevant values.
- Error messages say how to fix the problem or what to do next, not just what failed.
- Only swallow an error you specifically expect and have decided is safe; catch/test the narrow condition, never a blanket catch-all, and note why silence is intended if you don't log it.
- Error messages echo the caller's original input (e.g. an unexpanded path), never a derived or expanded value that could leak secrets.

## Paths and Environment

- Use `XDG_CONFIG_HOME`/`XDG_RUNTIME_DIR` (with a documented fallback) instead of hardcoding home-relative paths.
- Never write directly to `/tmp`. Always create a private temp file/dir first (`mktemp`, `tempfile.mkdtemp()`, `os.MkdirTemp`) and clean it up deterministically, not by convention.
- On a shared machine, use `realpath` (or the language equivalent) to resolve symlinks instead of listing and eyeballing.

## Safety

- Never expose secrets (API tokens, passwords) in command arguments — they're visible in `ps -ef`. Use environment variables, stdin, or config files.
- Never run destructive commands (`rm -rf`, `git reset --hard`, force-push, etc.) without explicit user instruction.
- Never commit files that likely contain secrets.

## Comments and Section Structure

- Keep comment blocks to max 2 lines. One sentence per line. Write short sentences that fit in 120 columns.
- Comments explain *why*: intent, gotchas, non-obvious reasons. Don't narrate what the code does.
- If a comment only restates what the code plainly does, delete it — don't just trim it.
- Always explain arbitrary numbers (timeouts, retries, sizes, thresholds): record where the value came from, or that it's a guess.
- Don't delete existing comments unless they're incorrect or no longer relevant; update them to match new code behavior.
- Use a small set of standard up-front headers, then describe the steps the code actually performs.
- Standard up-front sections, in this order when present: `ARGUMENTS`, `ENVIRONMENT`, `HELPERS`.
- After those, name each remaining section after the step it performs (`GET MESSAGES`, `SEND MESSAGES`, `POLL`). If the main section is small, just call it `MAIN`.
- Headers are all caps, no more than three words, and stay in reading order.
- Each header is a comment-marker line of 78 `=` characters, the title line, then another 78 `=` line — see BASH.md/PYTHON.md for the exact banner form in comment-block languages. (Go's `godoc`-style doc comments don't use this banner; see GO.md.)

## New Scripts

Scripts that need to run from a specific directory resolve their own location and `cd` there before doing anything else, rather than assuming the caller's cwd.

## Verification

After writing or editing code, run the language's syntax/format/build check before calling the work done (e.g. `bash -n`, `python3 -m py_compile`, `gofmt`/`go build`). Run the test suite when one exists.
