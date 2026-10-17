# Project Layout

How to lay out a repo so it stays clean: where each kind of file goes and what each directory is
for. The principles behind it are in REPO.md; this file is the concrete layout.

## Directory Layout

```text
my-service/
  README.md            what the project is, how to run it, where everything lives
  docs/                source of truth for how the system works today
    API.md             every endpoint: method, path, who may call it, body, response
    SCHEMA.md          every table and the rules the server enforces on it
  notes/               why: one dated file per decision, never edited afterwards
    README.md          the rules for notes
    2026-01-15-initial-design.md
  server/              one directory per program, each owned by one person or agent
    test/              black-box tests that start the real program
  web/
  worker/
  demo/                starts the real system with sample data in one command
  Makefile             build, test, demo
```

The program directories (`server/`, `web/`, `worker/`) and their names change with the project.
`docs/`, `notes/`, `demo/` and a `test/` inside each program are always there.

## Docs Versus Notes

`docs/` says what is true now and is updated in the same commit as the code that changes it. When
code and a doc disagree, one of them is a bug. `notes/` says why, and is history: when a note and a
doc disagree, the doc wins.

Notes are named `YYYY-MM-DD-short-name.md`, written on the day of the decision, and never edited.
A later decision that reverses an earlier one gets a new note that names the old one. A note holds
the decision, the reason, the alternatives that lost, and what was left out on purpose. It links
to `docs/` instead of repeating it.

Example note entry:

```markdown
## Events

Events are a long poll, `GET /api/events`, not WebSockets. A shell script can follow it with one
`curl`, and the browser uses the same call. WebSockets were rejected because every client would
need a library to read them.
```

## Contract First

Write the doc before the code. `API.md` opens with a summary table of every endpoint, then one
section per group with the request and response shapes. Each program builds against the doc, not
against another program's code, so two programs can be built at the same time.

When building against the contract shows it is wrong, change the doc first and tell the people
who build against it. A shape that changes silently breaks the programs that read it.

## Tests From The Contract

Each program that serves an interface has a `test/` directory of black-box tests. The suite
builds the real binary, starts it on a free port with a throwaway database and config, and calls
it the way a client would. Tests are written from the doc, before the code that passes them.

Every change goes red, green, refactor. Write the test first and watch it fail (red), write the
code that makes it pass (green), then clean up while it keeps passing (refactor). A bug fix starts
with a test that reproduces the bug, so the fix is proven to be what made it pass. A test written
after the code may never have failed, so nobody knows it can catch anything.

Example, for a search bug where a NUL character matched every message:

```text
red       FuzzSearch finds "\x00" returns every message; the case is saved under testdata/fuzz/
green     split the query on NUL and check the full string in Go; the saved case passes
refactor  move the escaping into one helper; the whole suite still passes
```

The suite checks its own coverage. It reads the summary table in `API.md` and fails if any
endpoint was never called successfully, so a new endpoint without a test fails the build.

Example layout:

```text
server/test/
  main_test.go         build the binary, start it, stop it, the coverage check
  client_test.go       helpers: newUser(t, "alice"), user.call(t, "POST", path, body)
  accounts_test.go     one file per section of API.md
  rooms_test.go
  fuzz_test.go         malformed bodies, bad ids, random operations checked against a model
```

## Demo

`make demo` builds the real programs into a temporary directory, starts them with a fresh
database, fills it with sample data through the real API, and prints how to open it and sign in.
Ctrl-C stops everything and deletes the data. It uses the real code, so it cannot drift the way a
mocked demo does, and it doubles as a smoke test: the seeding stops at the first failed call.
