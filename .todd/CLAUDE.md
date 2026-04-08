
# Tone
- NEVER use emdashes.
- Provide succinct and direct answers like speaking to an engineer.
- Don't ask what to do next. If there's an obvious next step, suggest it.
- Date format is always YYYY-MM-DD.

# Workflow
- NEVER COMMIT SECRETS.
- NEVER modify my dotfiles, just tell me what changes to make and I will make them.
- When I ask what changes are required, list each file separately with bullets for each change needed in that file.
- I often commit changes outside of this tool.
- Check for existing implementations first.
- Prefer editing existing files.
- When writing a new script, also run chmod +x on it
- After writing or editing a Python file, always run `python3 -m py_compile <file>` to verify syntax.
- Assume this is a shared machine.
  - NEVER write directly to `/tmp`. Always use `mktemp` or `mktemp -d` first.
  - NEVER expose secrets (API tokens, passwords, etc.) in command arguments. They are visible in `ps -ef`. Use environment variables, stdin, or config files instead.
- When checking for symlinks, use `realpath` instead of `ls -la`. It resolves the full chain.

# Commands
- I have custom scripts prefixed with a comma (e.g. `,claude`). The comma is part of the command name, not a typo.
- Use `jq` for JSON parsing instead of `python3 -c "import json; ..."`.

# Git
- CRITICAL: NEVER run git commit/add/stage unless explicitly ask. A previous request to commit does NOT grant permission to commit again later.
- NEVER undo/reset commits unless explicitly ask.
- When moving or renaming a file, check if the file is tracked by git and do a `git mv`
- When asked to commit, only stage and commit files that were modified during this session. Do not commit unrelated changes.

# Code Style
- Use guard clauses (early continue/return) to reduce nesting
- Use [[ ]] instead of [ ] in Bash
- Prefer native formatting options over post-processing. For example, use `tmux list-panes -F` format strings instead of piping through cut/awk/sed to rearrange fields.
- When a tool supports output formatting (e.g., `-F`, `--format`, `-o`), use it instead of parsing and reassembling the output.
- Quote all `$()` command substitutions: `foo="$(bar)"` not `foo=$(bar)`
- Use `trap 'rm -rf "$tmpdir"' EXIT` for temp dir cleanup -- never manual `rm -rf` at the end of a script
- In Python, inline single-use helper functions unless they have meaningful reuse or the logic is complex enough to warrant a name
- Check `$?` immediately after a command -- the next `$()` will clobber it

# New Script
When I tell you to write a new script, it usually means that it has to run from a specific directory so it should start with:
```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
```
