# Devil's Advocate

Challenge a proposed implementation, design, or plan before it is accepted.
Generate real alternatives, test every option against the same checklist, then give a Keep, Change, or Replace verdict and answer every open question.
Use it when someone asks to play devil's advocate, challenge this, poke holes in this, or whether there is a better approach.
For a line-by-line defect review of a finished diff, use CODE_REVIEW.md instead.

Decide whether the implementation on the table is the best option, or find a better one.
Treat it as if someone else wrote it, even if you did. It gets no head start over the alternatives.

Report only. Do not edit files, apply the verdict, or commit. Read code and run read-only commands as needed.
Checks that need edits (items 12 and 13) run in a throwaway copy, never in the user's files.

Tags such as (CR-E4) point to the matching rule in CODE_REVIEW.md in this directory.

## Process

1. Identify the subject: the most recent implementation, design, or plan in the conversation, or the file, diff, or text the user points at.
   If there is more than one candidate, ask which one.
   If the change is built on another unmerged change, review only its own commits, and say which commits you reviewed.
2. Restate the goal and constraints in one or two sentences.
   If the goal is unclear, stop and ask. Judging against the wrong goal wastes the whole review.
   Name the concrete case from the request and run it against the change. A change that passes its tests but not the user's own example misses the point.
   Turn the goal into 3 to 6 pass/fail criteria that someone else could check without asking the user.
   Include at least one thing that would make the user reject the change even if it passed the rest.
3. Collect every open question already raised in the conversation about the subject. Each one must get an answer in the output.
4. Check for existing implementations before inventing anything: search the repo, the user's own scripts (such as `~/bin`), and any installed agent skills.
5. Write two or three real alternatives. Include "use what exists" or "do nothing" when either is plausible.
   Each alternative must be one a competent engineer would actually propose, not a strawman.
6. Score the original and every alternative against the criteria from step 2, and run each through the [Checklist](#checklist).
   Back each claim with evidence: a file and line read, a command run, a doc found, or a stated constraint. Mark anything unverified as a guess.
7. Pick a verdict:
   - **Keep:** the original wins. State the strongest objection and why it does not hold.
   - **Change:** the original wins with specific edits. List each edit by file. For a bug fix, list the edits in red-green-refactor order: the test that reproduces the bug and fails first, then the fix that makes it pass, then any cleanup.
   - **Replace:** an alternative wins. Say which and why, and what it costs to switch.
8. Answer every open question from step 3. If one cannot be answered with evidence, say what would settle it.

## Checklist

1. **Problem fit:** Does it solve the problem that was asked, all of it, and not a nearby easier one?
2. **Existing code:** Does the repo, a library, a tool flag, or one of the user's scripts already do this?
   If the change puts one rule in more than one place, such as an access filter in both Go and SQL, compare the copies line by line and report each difference (CR-E4).
3. **Simpler version:** Could it be fewer files, fewer layers, no new abstraction, or a native option instead of parsing?
4. **Assumptions:** List each assumption. Mark it verified or guessed.
   Rerun every speed or size figure the change quotes, such as "renders in under 1 s"; a figure nobody reran is a guess.
   A fact taken from a secondary source, such as a blog post, a screenshot, or a forum answer, is a guess until checked against the primary doc.
5. **Failure modes:** Empty or huge input, concurrent runs, shared machine, missing dependency, partial failure. Does it fail loud with a useful message?
   Name the exact input or condition that triggers each failure. If a read-only command can show it, run it; a demonstrated failure beats an argument.
   For code that handles outside input, time it and measure its output size at input sizes that each double the last; about 4x slower per doubling means quadratic work, and output growing much faster than input needs a cap (CR-I5).
   After an irreversible action such as a post, a send, or a deploy, can a later step report failure and cause a retry that repeats the action (CR-F11)?
   Run it under `LC_ALL=C` with a non-ASCII name or input.
   If it reads an important file, such as a config, a credential, or a script it runs, from a directory other users can write to, ask whether it should read from there at all.
   If a script starts a server and then sends it a password or token, check what it confirms first. Another user can take the port before the server binds it and receive the secret. Answering on the port proves nothing; the script must confirm its own process holds the port.
6. **Blast radius:** What breaks if it is wrong, and how hard is it to undo?
   For any limit, such as an allowlist, a permission check, or a read-only rule, ask what enforces it. A limit only the caller's own code enforces is gone with one bug or one tricked agent; one the server or the credential enforces holds.
   A limit held only by a doc line or a prompt, such as "never run X", is a finding even if nothing breaks it today; propose the code that would hold it.
   For a changed default of a shared function, endpoint, or flag, list every caller and check the change for each (CR-E7).
7. **Cost of change:** If requirements shift a little, how much has to be rewritten?
8. **Fit:** Does it match the surrounding code's idioms, naming, and conventions, or bring in a new pattern?
9. **Testability:** Can it be checked independently, without trusting the author's own summary?
   When you run the change or its tests, read what it prints, not only the exit code. A run that exits 0 while printing errors or warnings is a finding.
   Can its tests be hermetic? A design that reads the clock, the network, environment variables, or fixed paths directly, instead of taking them as inputs, can only be tested by tests that fail for reasons nobody caused.
   Compare what the tests feed it with real use: input size, speed, permissions, network, and data shape. Tests on easier inputs than real use pass while real use fails.
   Run only the fast tests the change adds or touches three extra ways: twice in a row without cleanup, each test alone, and under `TZ=Pacific/Kiritimati`.
   A different result means the test depends on leftover state, test order, or the local date. Skip tests that take more than about a minute each (a guess at where three extra runs stop being cheap).
   Does any test run the startup path, the code that runs once when the program or page first loads? A bug there breaks every run, and tests that start after setup never see it.
10. **Strongest objection:** What would a skeptical senior engineer say first?
11. **Fix of a finding:** If the change fixes an earlier review finding, does the fix open a new hole of the same kind nearby? Ask for a test that covers that whole kind of bug, not just the input that was reported.
12. **Requests at the same time:** Find code that checks a limit before it acts, such as allowing 5 failed logins a minute. Send 40 wrong passwords at once to a throwaway copy. If the code checks more than 5, the limit breaks when requests arrive together.
13. **Tests that guard the change:** Delete each condition the change adds, one at a time, and run the tests. If they still pass, no test guards that condition. Make sure you deleted the code under test, since the same line can appear in more than one place.
    Do this even when the author says they already did; that claim is often wrong.
14. **Shared services under load:** If many copies run at once (CI jobs, hooks, cron, parallel workers), multiply what one run asks of each shared service (git server, NFS, database, license server, API) by the peak number of copies.
    A check that only needs a diff should not fetch the whole history, such as `git fetch --unshallow`.
    Transient server errors should get a bounded retry, such as `GET_SOURCES_ATTEMPTS` in GitLab CI, instead of failing the run.
15. **Frequent or repeated execution:** If this runs every frame, tick, poll, or event, find the work whose input has not changed since the last cycle and cache it or move it out of the loop.
    Time one cycle with history at sizes that each double the last; if the time grows, the loop is redoing old work.
    Keep file writes, log lines, and unindexed queries out of the cycle, since they repeat at the loop's rate.
16. **Loops between automated parts:** If its output can start another run of itself, directly or through another system such as a retry, a webhook, or a job that queues another job, say what stops the loop and what each round costs.
17. **Private data:** For data only some users may see, check every path that can return it, such as search results, caches, exports, notifications, and counts, not just the main page. Check that access ends when someone loses it, and that access is checked when the data is read, not only when it was saved.
18. **State between runs:** If it keeps a file, table, cache, or memory from one run to the next, ask what limits its size and age (CR-F16), who can read it later (item 17), and how someone resets it by hand when an entry goes bad.
    If it saves what the user typed or ran, such as a command line, a URL, or an argument list, check whether a password or token can end up in the saved copy, and whether that file can be committed, synced, or shared.
    A file kept private only by its name or a `.gitignore` entry, such as `settings.local.json`, is one `git add -A` away from public. Pass secrets by reference, such as an environment variable name or a file path, never by value (CR-I1).
    For each file it writes inside a git repo that may hold secrets, machine-local state, or generated output such as build artifacts, caches, logs, or compiled binaries, run `git check-ignore -v <file>`. If the repo's own `.gitignore` does not match it, list the missing entry under Changes as blocks merge. A match in your global ignore does not count, since other clones do not have it.

## Output

Use this shape. Keep it short; include only objections that changed or nearly changed the verdict. List objections you checked and disproved under "Ruled out", one line each, so nobody spends time on them again. Mark every change as blocks merge or can follow, so the merge decision does not need inferring.

```
### Verdict: <Keep | Change | Replace>
<one or two sentences on why>

### Criteria
1. <pass/fail criterion from the goal>

### Options
| Option | C1 | C2 | ... | Simplicity | Risk | Reuses existing | Notes |
|---|---|---|---|---|---|---|---|
| Original: <name> | pass/fail | ... | ... | ... | ... | ... | ... |
| Alt 1: <name> | pass/fail | ... | ... | ... | ... | ... | ... |

### Objections that mattered
- <objection>: <evidence> -> <outcome>

### Ruled out
- <objection>: <evidence it does not hold>

### Changes (Change or Replace only)
- `<file>`
  - <edit> (blocks merge | can follow)

### Decisions for the user
1. <decision>: <options>; recommend <option> because <reason>

### Open questions
1. <question>: <answer, or what would settle it>
```

Questions the reviewer can settle with evidence stay in Open questions; only choices that need the user go in Decisions for the user.

When reviewing fixes to an earlier review, start with a table of the earlier items (Item, Status: Fixed, Partly, or Not fixed, Evidence), then list new findings in the changed lines only.

## Rules

- Do not argue for the original out of momentum. "It already exists" only counts if switching has a real, stated cost.
- Do not pick an alternative just to look rigorous. Keep is a valid verdict when the evidence supports it.
- "Simpler" must say simpler than what, and by how much (files, lines, dependencies, steps).
- If a check needs information you cannot get, or cannot run here (for example, the sandbox blocks it), say so, and give the exact command for the user to run and the output that settles it.
