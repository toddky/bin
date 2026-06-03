
# System Prompt
- ALWAYS read ~/LOCAL_CLAUDE.md if it exists.

# Skills
- ALWAYS check for matching skills in ~/.skills if it exists.

# Tone
- NEVER use emdashes or `--` in prose.
- Provide succinct and direct answers like speaking to an engineer.
- Don't ask what to do next. If one step is obvious, suggest it; if several are reasonable, list them numbered and recommend one.
- Number every question that needs a decision or confirmation, even a single one.
- Date format is always YYYY-MM-DD.
- Avoid using these words and all their inflected forms (plurals, tenses, etc.)
  - Disruptive
  - Innovative
  - Leverage
  - Synergy
  - Production-ready
  - Telemetry
  - Emit
  - Re-anchored

# Workflow
- DO NOT ask for permission for obvious next steps that are reversible and have no external side effects (running tests, editing files, building, reading, GET requests, git fetch).
- ALWAYS ask before destructive (rm, delete, git clean), hard-to-reverse (git push, commit, reset --hard), or externally visible (Slack, PR comments, email, POST/PUT/DELETE requests) actions. "Is X safe to delete?" is a question, not permission.
- When asked to read a script or file by name, check the current working directory first before looking elsewhere (e.g., ~/.skills).
- NEVER modify my dotfiles, just tell me what changes to make and I will make them.
- When listing changes (required, remaining, completed, or any other status), list each file separately with bullets for each change in that file.
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
- To find a file in the current repo, use `git ls-files | grep <filename>` instead of find.
- If you must search outside the repo, always use `timeout 10 find <path> -name <filename>`.

# Git
- NEVER run git commit/add/stage unless explicitly asked. A previous request to commit does NOT grant permission to commit again later. A previous request to commit does NOT grant permission to commit again later.
- "Update the script", "fix the script", "edit the file" etc. are NOT permission to commit. Only "commit" or "git commit" counts as explicit permission.
- NEVER undo/reset commits unless explicitly asked.
- When moving or renaming a file, check if the file is tracked by git and do a `git mv`
- Before committing, run `realpath` on each file to resolve symlinks and ensure you're committing to the correct repo (it may be in a subrepo or symlinked elsewhere).
- When asked to commit, only stage and commit files that were modified during this session. Do not commit unrelated changes.

# Comments
- Keep comment blocks to max 2 lines. One sentence per line. Write short sentences that fit in 120 columns.
- Comments should explain *why*: intent, gotchas, non-obvious reasons. Don't narrate what the code does.
- Don't delete existing comments unless they're incorrect or no longer relevant. Update them to match new code behavior.

# Code Style
- No single-letter variable names. Use descriptive names (e.g., `result` instead of `r`).
- Use guard clauses (early continue/return) to reduce nesting
- Inline single-use helper functions unless they have meaningful reuse or the logic is complex enough to warrant a name
- Use `XDG_CONFIG_HOME` (defaulting to `~/.config`) instead of hardcoding home-relative config paths.
- DO NOT write over-engineered code when a simpler approach works (e.g., writing .sh files to disk and re-reading them instead of pipe stdout to stdin).
- Prefer inlining single-use helpers unless the logic is genuinely complex or reused meaningfully.

# Error Handling
- Prefer checking for the error condition upfront (LBYL, look before you leap) over catching the exception (EAFP, easier to ask forgiveness than permission). For example, test for None rather than catching the resulting error. Use exception handling when a check is not practical.
- Fail early and loud with descriptive messages that include context for debugging (what was being attempted, relevant values).
- Error messages should say how to fix the problem or what to do next, not just what failed.
- Only swallow an exception when you specifically expect it and have decided it's safe; catch the narrow type, not bare `except`, and log a warning unless silence is truly intended.

# Bash
- Use [[ ]] instead of [ ]
- Prefer native formatting options over post-processing. For example, use `tmux list-panes -F` format strings instead of piping through cut/awk/sed to rearrange fields.
- When a tool supports output formatting (e.g., `-F`, `--format`, `-o`), use it instead of parsing and reassembling the output.
- Quote all `$()` command substitutions: `foo="$(bar)"` not `foo=$(bar)`
- Use `trap 'rm -rf "$tmpdir"' EXIT` for temp dir cleanup, never manual `rm -rf` at the end of a script
- Check `$?` immediately after a command, since the next `$()` will clobber it

# Commands
- I have custom scripts prefixed with a comma (e.g. `,claude`). The comma is part of the command name, not a typo.
- Use `jq` for JSON parsing instead of `python3 -c "import json; ..."`.

# Python
- Use `Path()` from `pathlib` instead of `os.path`.

# New Script
When I tell you to write a new script, it usually means that it has to run from a specific directory so it should start with:
```bash
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
```

# Hard Rules

**NEVER**:
- NEVER COMMIT SECRETS.
- NEVER use emdashes or `--` in prose.
- NEVER modify dotfiles, tell me what changes to make instead.
- NEVER write directly to `/tmp`, use `mktemp` or `mktemp -d` first.
- NEVER expose secrets (API tokens, passwords, etc.) in command arguments, they are visible in `ps -ef`.
- NEVER run `git commit`, `git add`, or `git stage` unless explicitly asked. "update the script" or "fix the file" is NOT permission.
- NEVER undo or reset commits unless explicitly asked.

**ALWAYS**:
- ALWAYS read `~/LOCAL_CLAUDE.md` if it exists.
- ALWAYS check for matching skills in `~/.skills` if it exists.
- ALWAYS ask before destructive (rm, delete, git clean), hard-to-reverse (git push, commit, reset --hard), or externally visible (Slack, PR comments, email, POST/PUT/DELETE) actions.

