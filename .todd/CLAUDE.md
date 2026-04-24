
# System Prompt
- ALWAYS read ~/LOCAL_CLAUDE.md if it exists.

# Tone
- NEVER use emdashes.
- Provide succinct and direct answers like speaking to an engineer.
- Don't ask what to do next. If there's an obvious next step, suggest it.
- Date format is always YYYY-MM-DD.

# Skills
- ALWAYS check for matching skills in ~/.skills if it exists.

# Workflow
- DO NOT ask for permission to do obvious next steps EXCEPT for git commands. Read the Git section.
- When asked to read a script or file by name, check the current working directory first before looking elsewhere (e.g., ~/.skills).
- NEVER modify my dotfiles, just tell me what changes to make and I will make them.
- When I ask what changes are required, list each file separately with bullets for each change needed in that file.
- I often commit changes outside of this tool.
- Check for existing implementations first.
- Prefer editing existing files.
- When writing a new script, also run chmod +x on it
- When fixing bugs, fix the root cause, not the symptom.
- After writing or editing a Python file, always run `python3 -m py_compile <file>` to verify syntax.
- After writing or editing a Bash file, always run `bash -n <file>` to verify syntax.
- Assume this is a shared machine.
  - NEVER write directly to `/tmp`. Always use `mktemp` or `mktemp -d` first.
  - NEVER expose secrets (API tokens, passwords, etc.) in command arguments. They are visible in `ps -ef`. Use environment variables, stdin, or config files instead.
- When checking for symlinks, use `realpath` instead of `ls -la`. It resolves the full chain.

# Commands
- I have custom scripts prefixed with a comma (e.g. `,claude`). The comma is part of the command name, not a typo.
- Use `jq` for JSON parsing instead of `python3 -c "import json; ..."`.

# Git
- NEVER COMMIT SECRETS.
- CRITICAL: NEVER run git commit/add/stage unless explicitly asked. A previous request to commit does NOT grant permission to commit again later.
- NEVER undo/reset commits unless explicitly asked.
- When moving or renaming a file, check if the file is tracked by git and do a `git mv`
- Before committing, run `realpath` on each file to resolve symlinks and ensure you're committing to the correct repo (it may be in a subrepo or symlinked elsewhere).
- When asked to commit, only stage and commit files that were modified during this session. Do not commit unrelated changes.

# Comments
- Keep comment blocks to max 2 lines. One sentence per line. Write short sentences that fit in 120 columns.
- Comments should explain *why* -- intent, gotchas, non-obvious reasons. Don't narrate what the code does.
- Don't delete existing comments unless they're incorrect or no longer relevant. Update them to match new code behavior.

# Code Style
- No single-letter variable names. Use descriptive names (e.g., `result` instead of `r`).
- Use guard clauses (early continue/return) to reduce nesting
- Inline single-use helper functions unless they have meaningful reuse or the logic is complex enough to warrant a name
- Use `XDG_CONFIG_HOME` (defaulting to `~/.config`) instead of hardcoding home-relative config paths.
- DO NOT write over-engineered code when a simpler approach works (e.g., writing .sh files to disk and re-reading them instead of pipe stdout to stdin).
- Prefer inlining single-use helpers unless the logic is genuinely complex or reused meaningfully.

# Bash
- Use [[ ]] instead of [ ]
- Prefer native formatting options over post-processing. For example, use `tmux list-panes -F` format strings instead of piping through cut/awk/sed to rearrange fields.
- When a tool supports output formatting (e.g., `-F`, `--format`, `-o`), use it instead of parsing and reassembling the output.
- Quote all `$()` command substitutions: `foo="$(bar)"` not `foo=$(bar)`
- Use `trap 'rm -rf "$tmpdir"' EXIT` for temp dir cleanup -- never manual `rm -rf` at the end of a script
- Check `$?` immediately after a command -- the next `$()` will clobber it

# Python
- In Python, use `Path` from `pathlib` for all filesystem paths instead of `os.path`.

# New Script
When I tell you to write a new script, it usually means that it has to run from a specific directory so it should start with:
```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
```

