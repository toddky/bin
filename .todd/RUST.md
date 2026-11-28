# Rust Coding Guidelines

Rust-specific rules. The cross-language rules (naming basics, control flow, string building, error-message content, comment style, safety, paths) live in CODE_REVIEW.md and are not repeated here.

## Unsafe

- Prefer a safe wrapper over `unsafe`, such as an existing peer-credential helper instead of `File::from_raw_fd`.
- Give every `unsafe` block a `// SAFETY:` comment that names the invariant it relies on.

## Async

- Don't make blocking file, process, or sleep calls inside an `async fn`. Use the runtime's async version or `spawn_blocking`, since a blocking call stalls every task on that worker thread.
