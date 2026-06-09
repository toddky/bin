# Bash Coding Guidelines

Style rules for all Bash code.

## Naming

- No abbreviated locals. Use `output` not `out`, `last_line` not `last`, `message` not `msg` in new code.
- Never use the `_path` suffix. Use `_file` or `_dir` for path variables, or the extension as the suffix (`_md`, `_txt`, `_json`). Example: `url_file`, `runtime_dir`, `readme_md`, `config_txt`. Not `url_path` or bare `url`.
- Use the `num_` prefix for integer counts: `num_passes`, `num_failures`. Not `<thing>_count` or `<thing>s_seen`.
- Name generic helpers after the binary or concept they wrap: a tmux pass-through is `tmux(...)`, not `run_tmux(...)` or `tmux_cmd(...)`.
- No single-letter variable names. Use descriptive names (e.g., `result` instead of `r`).

## Functions

- Always use the `function` keyword when declaring functions.

  ```bash
  function my_func() {
  	echo "hello"
  }
  ```

  Not:

  ```bash
  my_func() {
  	echo "hello"
  }
  ```

## Conditionals

- Use `[[ ]]` instead of `[ ]`.
- Use guard clauses (early `return` or `continue`) to reduce nesting instead of wrapping the happy path in an `if` block.

## Arrays Over Concatenation

When building a command from multiple parts (flags, arguments, etc.), collect the parts in an array and expand it. Do not concatenate with string interpolation or `\` line continuations.

```bash
git_args=()
git_args+=(-u origin "$branch")
git_args+=(-o merge_request.create)
git_args+=(-o "merge_request.target=${target}")
git push "${git_args[@]}"
```

Not:

```bash
git push -u origin "$branch" \
  -o merge_request.create \
  -o "merge_request.target=${target}"
```

## Shell Strings

- Quote all `$()` command substitutions: `foo="$(bar)"` not `foo=$(bar)`.
- Use `basename` and `dirname` for basename/dirname operations. Prefer these over `${var##*/}` and `${var%/*}` shell parameter expansion.
- Always write stderr redirects as `1>&2`, not `>&2`. Being explicit about the source fd makes the intent obvious.

## Multiline Strings

Use a heredoc to capture multi-line output into a variable:

```bash
read -r -d '' result <<EOF
$first_line
$second_line
EOF
```

Add `IFS=` before `read` to preserve leading/trailing whitespace.

Not:

```bash
result="$first_line
$second_line"
```

## Control Flow

- Check `$?` immediately after a command -- the next `$()` will clobber it.
- Use `trap 'rm -rf "$tmpdir"' EXIT` for temp dir cleanup. Never manually `rm -rf` at the end of a script.
- Hoist loop-invariant values out of the loop. If a value doesn't change between iterations, compute it once above the loop:

  ```bash
  merge_base="$(git merge-base --octopus "${branches[@]}")"
  for branch in "${branches[@]}"; do
      echo "$merge_base $branch"
  done
  ```

  Not:

  ```bash
  for branch in "${branches[@]}"; do
      echo "$(git merge-base --octopus "${branches[@]}") $branch"
  done
  ```

## Output Formatting

- Prefer native formatting options over post-processing. Use `tmux list-panes -F` format strings instead of piping through `cut`/`awk`/`sed` to rearrange fields.
- When a tool supports output formatting (e.g., `-F`, `--format`, `-o`), use it instead of parsing and reassembling the output.

## Traps and exec

If you need a cleanup trap, don't use `exec` — it replaces the shell process so the trap never fires:

```bash
# Good: trap fires when child exits
trap 'rm -f "$marker"' EXIT
"$program" "$@"

# Bad: trap never fires because exec replaces the shell
trap 'rm -f "$marker"' EXIT
exec "$program" "$@"
```

## Command Pipelines

Collect `sed` expressions in an array with `-e` flags instead of piping multiple `sed`s:

```bash
# Good
sed_args=()
sed_args+=(-e 's/^ *//')
sed_args+=(-e 's/  \+v[0-9].*//')
sed "${sed_args[@]}"

# Bad
sed 's/^ *//' | sed 's/  \+v[0-9].*//'
```

## Paths and Environment

- Use `XDG_CONFIG_HOME` (defaulting to `~/.config`) instead of hardcoding home-relative config paths.
- Never write directly to `/tmp`. Always use `mktemp` or `mktemp -d` first.
- On a shared machine, use `realpath` to resolve symlinks instead of `ls -la`. It resolves the full chain.

## Safety

- Never expose secrets (API tokens, passwords, etc.) in command arguments -- they are visible in `ps -ef`. Use environment variables, `stdin`, or config files instead.
- Never run destructive commands (`rm -rf`, `git reset --hard`, etc.) without explicit user instruction.

## Error Handling

- Do not use `set -euo pipefail`. Handle each error explicitly at the call site so failures get a meaningful message instead of a silent abort.
- Check return codes with `if !`, `||`, or explicit `$?` checks. Print a clear error to `>&2` and exit with a non-zero code when something fails.

## New Scripts

Scripts that need to run from a specific directory should start with:

```bash
#!/usr/bin/env bash
# USAGE: script-name [args]
# DESCRIPTION: Brief description.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
```

After writing, always run `chmod +x <script>` and verify syntax with `bash -n <script>`.

## Comments and Section Structure

- Keep comment blocks to max 2 lines. One sentence per line. Write short sentences that fit in 120 columns.
- Comments should explain *why* -- intent, gotchas, non-obvious reasons. Don't narrate what the code does.
- Don't delete existing comments unless they're incorrect or no longer relevant. Update them to match new code behavior.
- Use a small set of standard up-front headers, then describe the steps the code actually performs.
- Standard up-front sections, in this order when present: `ARGUMENTS`, `ENVIRONMENT`, `HELPERS`.
- After those, name each remaining section after the step it performs in the code (`GET MESSAGES`, `SEND MESSAGES`, `POLL`, etc.). If the main section is really small, just call it `MAIN` instead of describing what it does.
- Headers are all caps and no more than three words.
- Keep header order matching reading order.
- Each header is a `#` followed by a space and 78 `=` characters, then the title line, then another `#` and 78 `=` characters:

  ```
  # ==============================================================================
  # ENVIRONMENT
  # ==============================================================================
  ```
