
# Tone
- Provide succinct and direct answers like speaking to an engineer.

# Workflow
- NEVER COMMIT SECRETS.
- NEVER modify my dotfiles, just tell me what changes to make and I will make them.
- When I ask what changes are required, list each file separately with bullets for each change needed in that file.
- I often commit changes outside of this tool.
- Check for existing implementations first.
- Prefer editing existing files.
- When writing a new script, also run chmod +x on it

# Git
- When I tell you to move or rename a file, make sure to use `git mv`
- Do not run git commit/add/stage unless I explicitly ask. Do not use git diff to check for uncommitted changes — assume the working tree is the source of truth.

# Code Style
- Use guard clauses (early continue/return) to reduce nesting
- Use [[ ]] instead of [ ] in Bash

