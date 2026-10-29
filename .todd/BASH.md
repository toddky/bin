# Bash Coding Guidelines

Style rules for all Bash code.

## Naming

- No abbreviated locals. Use `output` not `out`, `last_line` not `last`, `message` not `msg` in new code.
- Never use the `_path` suffix. Use `_file` or `_dir` for path variables, or the extension as the suffix (`_md`, `_txt`, `_json`). Example: `url_file`, `runtime_dir`, `readme_md`, `config_txt`. Not `url_path` or bare `url`.
- Use the `num_` prefix for integer counts: `num_passes`, `num_failures`. Not `<thing>_count` or `<thing>s_seen`.
- Name generic helpers after the binary or concept they wrap: a tmux pass-through is `tmux(...)`, not `run_tmux(...)` or `tmux_cmd(...)`.
- No single-letter variable names. Use descriptive names (e.g., `result` instead of `r`).

## Functions

Always use the `function` keyword when declaring functions.

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

## Local Variables

Bash scoping is dynamic, so a `local` is visible to every function it calls and hides any global of the same name from them. Never give a local the name of a global that a called function reads.

```bash
function handle_request() {
    local request_name="$1"
    write_status
}
```

Not:

`write_status` reads the global `name`, so it writes the request name instead of the workflow name:

```bash
name="nightly-build"

function write_status() {
    echo "$name: running" > "$status_file"
}

function handle_request() {
    local name="$1"
    write_status
}
```

## Conditionals

- Use `[[ ]]` instead of `[ ]`.
- Use `(( ))` for integer comparisons (exit codes, counts, flags). Format: `((x == 124))` — spaces around the operator, no spaces inside the parens. Never use `(( ))` for assignment.
- Use guard clauses (early `return` or `continue`) to reduce nesting instead of wrapping the happy path in an `if` block.
- Handle the specific exit code you care about first, then fall through to a single pass-through exit. Test for `== N` (the case you handle), not `!= N`. The `!= N` form inverts the logic and is harder to read:

  ```bash
  # Good: handle 124, then pass through whatever happened
  timeout 15 "$cmd" "$@"
  exit_code=$?
  if ((exit_code == 124)); then
      print_timeout_help 1>&2
  fi
  exit "$exit_code"

  # Bad: inverted test, duplicate exits
  if ((exit_code != 124)); then
      exit "$exit_code"
  fi
  print_timeout_help 1>&2
  exit 124
  ```

## Boolean Flags

Use integer flags checked with `(( ))`, not `true`/`false` strings.

```bash
needs_rebuild=0
if [[ ! -d "$cache_dir" ]]; then
    needs_rebuild=1
fi
if (( needs_rebuild )); then
    rebuild
fi
```

Not:

```bash
needs_rebuild=false
if [[ ! -d "$cache_dir" ]]; then
    needs_rebuild=true
fi
if [[ "$needs_rebuild" == true ]]; then
    rebuild
fi
```

## Associative Array Lookups

Looking up an empty key, such as `${owners[""]}`, prints `bad array subscript` and still returns 0, so the script runs on with a stray error in its output. Check that the key is not empty before the lookup.

```bash
if [[ -z "$user" ]]; then
    echo "ERROR: request has no user; expected a user name" 1>&2
    exit 1
fi
owner="${owners[$user]:-}"
```

Not:

A request with no user prints `bad array subscript` and carries on as if the user has no owner:

```bash
owner="${owners[$user]:-}"
```

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

## Argument Parsing

Loop with `while [[ $# -ge 1 ]]` and shift at the top. Match flags with a `case`. Unknown args print an error and exit. Flags that take a value consume `$1` with a second `shift`; boolean flags just set a variable.

```bash
while [[ $# -ge 1 ]]; do
    arg="$1" && shift
    case "$arg" in
        --dryrun) dryrun=1;;
        --force) force=1;;
        --help) print_usage; exit 0;;
        *) echo "ERROR: unknown argument: $arg" 1>&2; exit 1;;
    esac
done
```

## Shell Strings

- Quote all `$()` command substitutions: `foo="$(bar)"` not `foo=$(bar)`.
- Use `basename` and `dirname` for basename/dirname operations. Prefer these over `${var##*/}` and `${var%/*}` shell parameter expansion.
- Always write stderr redirects as `1>&2`, not `>&2`. Being explicit about the source fd makes the intent obvious.

## Validating Captured Values

`$(...)` strips every trailing newline, so a check on the captured value passes `restart\n\n` as `restart`. When the original value goes on to another program, check it in the tool that reads the original instead.

```bash
if ! jq -e '.action == "restart"' "$request_file" > /dev/null; then
    echo "ERROR: $request_file has an unknown action; expected restart" 1>&2
    exit 1
fi
mv "$request_file" "$queue_dir/"
```

Not:

For `{"action": "restart\n\n"}` the check passes, and the queue gets the action with its newlines:

```bash
action="$(jq -r .action "$request_file")"
if [[ "$action" != "restart" ]]; then
    echo "ERROR: $request_file has an unknown action; expected restart" 1>&2
    exit 1
fi
mv "$request_file" "$queue_dir/"
```

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

## Reading Fields

A tab in `IFS` counts as whitespace, so `read` treats two tabs in a row as one separator. An empty field disappears and every later field moves one place left. Split tab-separated lines with `mapfile -d $'\t'`, which splits on every tab. `printf '%s'` replaces `<<<`, which adds a newline that would end up in the last field.

```bash
mapfile -t -d $'\t' fields < <(printf '%s' "$line")
action="${fields[0]}"
target="${fields[1]}"
scope="${fields[2]}"
```

Not:

For the line `<TAB>restart<TAB>all`, `action` gets `restart` and `target` gets `all`:

```bash
IFS=$'\t' read -r action target scope <<< "$line"
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
- Use `cat <<EOF` instead of multiple `echo` calls for multiline output:

  ```bash
  # Good
  cat 1>&2 <<EOF
  ERROR: something went wrong. Try one of these:

    Option 1: ...
    Option 2: ...
  EOF

  # Bad
  echo "ERROR: something went wrong. Try one of these:" 1>&2
  echo "" 1>&2
  echo "  Option 1: ..." 1>&2
  echo "  Option 2: ..." 1>&2
  ```

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

When you must `exec` but still need a temp file cleaned up, open it on a file
descriptor and unlink it before the `exec`. The kernel reclaims the inode when
the process exits, and the child reads it via `/dev/fd/N`. This also keeps
secret contents off disk for the lifetime of the transfer.

```bash
# Good: file is unlinked up front, fd survives exec, kernel cleans up on exit
config_file="$(mktemp --tmpdir curl-cfg.XXXXXX)"
chmod 600 "$config_file"
printf '%s\n' "${config_lines[@]}" > "$config_file"
exec {config_fd}<"$config_file"
rm -f "$config_file"
exec curl --config "/dev/fd/${config_fd}" "${safe_args[@]}"
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

## Prefer Directory Arguments Over Subshell cd

Many tools take the target directory as an argument. Use it instead of wrapping the call in a `(cd "$dir" && ...)` subshell. The subshell exists only to keep the caller's cwd unchanged, which the flag does for free.

`go build -C <dir>` changes into the directory before building, so `-o` is relative to it and the binary lands in `<dir>`, not the caller's cwd:

```bash
# Good
go build -C "$SCRIPT_DIR" -o mybin .

# Bad
(cd "$SCRIPT_DIR" && go build -o mybin .)
```

`find` takes the search root as its first operand, so pass the directory directly:

```bash
# Good
find "$SCRIPT_DIR" -name '*.go' -newer "$SCRIPT_DIR/mybin" -print -quit

# Bad
(cd "$SCRIPT_DIR" && find . -name '*.go' -newer mybin -print -quit)
```

## Contain State Changes in a Subshell

When a command genuinely needs a changed cwd, `umask`, or other process state that no flag can pass, run it inside a `( ... )` subshell. The change dies with the subshell, so the rest of the script keeps the original state.

```bash
# Good: umask and cwd changes stay inside the subshell
(umask 077 && cd "$build_dir" && ./configure && make)

# Bad: umask leaks into every later file the script creates
umask 077
cd "$build_dir"
./configure && make
```

## Paths and Environment

- Use `XDG_CONFIG_HOME` (defaulting to `~/.config`) instead of hardcoding home-relative config paths.
- Never write directly to `/tmp`. Always use `mktemp` or `mktemp -d` first.
- On a shared machine, use `realpath` to resolve symlinks instead of `ls -la`. It resolves the full chain.

## Safety

- Never expose secrets (API tokens, passwords, etc.) in command arguments -- they are visible in `ps -ef`. Use environment variables, `stdin`, or config files instead.
- To keep a secret off the command line, write it to a `mktemp` file (created owner-only) and remove it in an exit trap:

  ```bash
  header_file="$(mktemp)"
  trap 'rm -f "$header_file"' EXIT
  printf 'PRIVATE-TOKEN: %s' "$api_key" > "$header_file"
  curl --silent --header @"$header_file" "$url"
  ```

- When the script must `exec`, the trap never fires. Unlink the file up front and pass it by descriptor; the kernel reclaims the inode on exit:

  ```bash
  config_file="$(mktemp --tmpdir curl-cfg.XXXXXX)"
  printf '%s\n' "${config_lines[@]}" > "$config_file"
  exec {config_fd}<"$config_file"
  rm -f "$config_file"
  exec curl --config "/dev/fd/${config_fd}" "${safe_args[@]}"
  ```

- Never run destructive commands (`rm -rf`, `git reset --hard`, etc.) without explicit user instruction.

## Error Handling

- Do not use `set -euo pipefail`. Handle each error explicitly at the call site so failures get a meaningful message instead of a silent abort.
- Check return codes with `if !`, `||`, or explicit `$?` checks. Print a clear error to `>&2` and exit with a non-zero code when something fails.

## Testing Scripts

Many bash errors, such as a bad array subscript or a missing command in the middle of a script, print to stderr and let the script run on and exit 0. Tests that run a script also fail when its stderr contains a `<script>: line N:` line.

```bash
"$script" > "$output_file" 2> "$error_file"
exit_code=$?
if grep -E '^[^:]+: line [0-9]+: ' "$error_file"; then
    echo "FAIL: $script printed a bash error" 1>&2
    exit 1
fi
if ((exit_code != 0)); then
    echo "FAIL: $script exited $exit_code" 1>&2
    exit 1
fi
```

Not:

A script that prints `line 4: owners: bad array subscript` and then finishes still passes:

```bash
if ! "$script" > /dev/null; then
    echo "FAIL: $script exited non-zero" 1>&2
    exit 1
fi
```

## Signals and Traps

Bash does not run a trap until the current foreground child finishes, so a long `go build` in the foreground delays shutdown by the whole build. Run long children in the background and `wait` for them. A trapped signal cuts `wait` short, so loop until the child has really exited.

```bash
trap 'shutting_down=1' TERM
go build -o mybin . &
build_pid=$!
wait "$build_pid"
exit_code=$?
# Exit codes above 128 mean wait returned early because a trap fired, not that the build finished.
while ((exit_code > 128)) && kill -0 "$build_pid" 2>/dev/null; do
    wait "$build_pid"
    exit_code=$?
done
```

## Locks

Use `flock -n -E <code>` so a held lock has its own exit code, and test for that code, not just non-zero. Without `-E` a held lock exits 1, which `flock -n "$lock_file" my-command` cannot tell apart from the command itself exiting 1. Check the `exec` that opens the lock file too: when the open fails, bash prints an error and keeps running with the fd unset.

```bash
if ! exec {lock_fd}>"$lock_file"; then
    echo "ERROR: cannot open $lock_file; check the directory exists and is writable" 1>&2
    exit 1
fi
# 75 is EX_TEMPFAIL from sysexits.h; pick a code that neither flock nor the command returns.
flock -n -E 75 "$lock_fd"
exit_code=$?
if ((exit_code == 75)); then
    echo "ERROR: another run holds $lock_file; wait for it to finish or pass --force" 1>&2
    exit 1
fi
if ((exit_code != 0)); then
    echo "ERROR: cannot lock $lock_file (flock exit $exit_code)" 1>&2
    exit 1
fi
```

A lock fd is inherited by every background child, so the lock outlives the script for as long as any child runs. Close it in children, or check the pid as well when the lock is used as proof that the script is still alive.

```bash
# Good
long_job {lock_fd}>&- &

# Bad
long_job &
```

## Replacing a Running Script

Bash reads a script from disk as it runs, so editing a running script in place can make the running copy execute the wrong lines when it reaches them. Write the new content to a separate file and `mv` it over the old name. The rename swaps the inode and the running copy keeps reading the old one.

```bash
# Good
printf '%s\n' "${new_lines[@]}" > "$script_file.new"
chmod --reference="$script_file" "$script_file.new"
mv "$script_file.new" "$script_file"

# Bad
sed -i 's/old-flag/new-flag/' "$script_file"
```

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

---

Don't restate what the code already says. A comment on a self-explanatory line adds nothing:

Bad: narrates what the code plainly does.

```bash
# Loop over every pane and print its title.
for pane_id in $(tmux list-panes -F '#{pane_id}'); do
	tmux display-message -t "%${pane_id}" -p '#{pane_title}'
done
```

Bad: same narration, shortened. Trimming a restatement still leaves a restatement.

```bash
# Print each pane title.
for pane_id in $(tmux list-panes -F '#{pane_id}'); do
	tmux display-message -t "%${pane_id}" -p '#{pane_title}'
done
```

Good: the comment is deleted, because no *why* was hiding in it.

```bash
for pane_id in $(tmux list-panes -F '#{pane_id}'); do
	tmux display-message -t "%${pane_id}" -p '#{pane_title}'
done
```

Shortening applies only to a real *why* that runs long. Bad: four lines to land one idea.

```bash
# We sleep here before checking the lock file because the NFS client caches
# directory entries for a short window, so a lock created by another host may
# not be visible yet. Without this the check below sometimes sees no lock and
# two jobs start at once.
sleep 5
```

Good: same *why*, one line, and the number is accounted for.

```bash
# NFS dentry cache can hide a lock made on another host; 5s is the observed max staleness.
sleep 5
```
