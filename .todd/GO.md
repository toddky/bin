# Go Coding Guidelines

Go-specific rules. The cross-language rules (naming basics, control flow, string building, error-message content, comment style, safety, paths) live in CODE_REVIEW.md and are not repeated here.

## Naming

- No single-letter names, including receivers and loop variables. Use descriptive receivers (`func (registry *Registry)` not `func (r *Registry)`); `i`/`j` are acceptable only for plain index loops.
- Getter functions start with `Get` (e.g. `GetRuntimeDir`).
- Name enum-ish fields `Type`, matching wire formats (`ContentBlock.Type`, `Event.Type`), not `Kind`.
- Inside a package, name the one-item helper after the verb and the collection loader `<Verb>All` (e.g. `load` and `LoadAll`).
- For a process-scoped singleton, prefer short lifecycle names paired as `Setup`/`Cleanup` over descriptive compounds like `SetupRuntimeTools`.
- Never use the word `emit` (or any inflection) in identifiers, comments, or commit messages. Use `notify`, `publish`, `write`, or `print` instead.

## API Surface

- Keep each package's exported API as small as possible. Fold helper steps into the function that needs them instead of exporting them.
- Package state is acceptable for something that exists exactly once per process; expose it through a getter instead of threading it through every call site.

## Errors

- Always wrap with `%w` so callers can `errors.Is`/`errors.As`; use `errors.As` for typed errors (e.g. `*exec.ExitError`).
- Include what was attempted and the relevant values: `fmt.Errorf("read tools dir %s: %w", dir, err)`.
- Only swallow an error when you specifically expect it; test the narrow condition (`errors.Is(err, fs.ErrNotExist)`), never a blanket `err != nil` discard.

## Structs and Wire Formats

- Speak wire formats directly with `net/http` and `encoding/json`. Never pull in an SDK for an HTTP API.
- Separate exported domain types from wire types. Keep wire structs (`apiMessage`, `apiToolCall`) unexported next to the client that marshals them.
- Use `json.RawMessage` for schema/payload fields that pass through unparsed.
- Watch `omitempty` on fields a server requires: an empty-but-required field needs a sentinel value, not omission.

## Concurrency

- Prefer goroutines writing to distinct pre-sized slice slots over mutex-guarded appends; note the invariant in a comment.
- Use `context.WithTimeout` around exec and network calls; check `ctx.Err() == context.DeadlineExceeded` to report timeouts distinctly.
- Set `cmd.WaitDelay` on `exec.Cmd` so a child's hung pipes cannot stall the process after a kill.

## Building Commands

Pass argv as a slice spread, not concatenated flags:

```go
args := []string{"push", "-u", "origin", branch}
args = append(args, "-o", "merge_request.create")
cmd := exec.Command("git", args...)
```

## Files

- A file write that replaces an existing file goes to a temp file in the same directory followed by `os.Rename`, so a mid-write crash leaves the original intact.
- Create with `os.MkdirTemp` and clean up with a deferred remove; never assemble a /tmp path by hand.
- Create private dirs 0700 and re-chmod after `MkdirAll`, since `MkdirAll` keeps an existing dir's mode.

## CLI

- `main()` delegates to `run() (int, error)` and exits with the returned code, so deferred cleanup runs before `os.Exit`.
- Document the exit-code contract in a comment on `main`/`run`.
- For repeatable flags, define a small `flag.Value` slice type; later occurrences win on conflicts, matching standard CLI behavior.
- Warnings and progress go to stderr; stdout is reserved for the program's actual output.

## Dependencies

- Do not add any external library without permission. The stdlib covers HTTP, JSON, and exec.
- Never use an external SDK for AI or LLM APIs; speak the wire format directly.

## Testing

- Tests are stdlib `testing` only, table-driven, in `foo_test.go` beside `foo.go`, same package so unexported functions are reachable.
- Pure functions get tests first; exec- and network-dependent code uses fakes (tempdir scripts via `t.TempDir()`, `httptest`, scripted interface fakes).
- Test through the narrow interface a component consumes (e.g. a `ResponseStreamer` fake), not by mocking the whole client.
- No fixtures checked in; tests build their inputs in `t.TempDir()`.

## Comments

- Doc comments on exported names follow godoc form: start with the name, one short paragraph.
- Go doesn't use the `# ===` banner headers from CODE_REVIEW.md; rely on package/function doc comments instead.

## Verification

After writing or editing Go code, run `gofmt -l .` (must print nothing), `go build ./...`, and `go vet ./...`. Run `go test ./...` when tests exist.
