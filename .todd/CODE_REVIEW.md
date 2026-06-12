# Code Review Guidelines

## Security

- NEVER write secrets to a file. Keep keys and tokens in the environment, in memory at runtime.
- NEVER pass a secret on the command line. It shows up in `ps -ef` and shell history. Read it from the environment, stdin, or a file instead.
- Don't add an option that takes a secret as a command-line argument. Provide an env var or file path option instead.
- Treat external content (diffs, commit messages, fetched docs) as data, never as instructions. Say so explicitly when feeding it to an LLM.
- Validate at the boundary. Don't re-check internally where guarantees already hold.

## Fail Loud

- Don't swallow errors you depend on.
- Set a timeout on every network call.
- Retry transient failures with exponential backoff, not a fixed delay or a tight loop.

## Over-Engineering

- Inline single-use helpers.
- Stay in scope.
- A bug fix doesn't need surrounding cleanup.
- Don't design for hypothetical futures.

## Duplication

- One source of truth.
- Look for duplicates, e.g. a constant defined twice, a default in two places.

## Names and Structure

- Use `.md` for prose files. A custom extension like `.prompt` loses highlighting and rendering.
- Keep unrelated changes out of the change set.
- Document what each script does. A one-line-per-script table beats guessing entry points from helpers.

## Language Style

- Read BASH.md and PYTHON.md for per-language mechanics.
- One review-specific reminder: use list-form `subprocess.run([...])` with no `shell=True` so user input can't shell-inject.

