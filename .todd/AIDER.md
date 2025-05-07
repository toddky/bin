
# Coding Conventions

## General Guidelines
- Write clean, readable, and maintainable code
- Use meaningful variable and function names

## Python
- Follow PEP 8 for code style
- Use f-strings for string formatting

## Shell Scripts
- Do not use `set -euo pipefail`
- Always quote variables and $()

## Git
- Write clear and concise commit messages
- Use the format: `type: short description` (e.g., `fix: handle edge case in API`)
- Commit related changes together; avoid mixing unrelated changes in a single commit

## Security
- Never hardcode sensitive information like API keys or passwords
- Use environment variables or configuration files for sensitive data
- Validate and sanitize all user inputs

## Documentation
- Use Markdown for README and other documentation files
- Keep documentation up to date with code changes

