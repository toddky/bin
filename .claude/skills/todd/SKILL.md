---
name: todd
description: Todd's coding, review, and writing rules. Load before a code review, a devil's advocate pass, or checking an agent's work for reward hacking; before building or changing an AI agent flow (prompts, agent loops, evals, test harnesses an agent runs against); before writing or editing Bash, Python, Go, Ruby, or JavaScript; and before writing a document, requirements, repo layout, or any text other people will read (commit messages, Slack, PR comments). Also load when the user asks for a "todd review" or says to run todd on an MR, PR, branch, or diff, which means a code review plus a devil's advocate pass. Also load before proposing changes to these rules, the `.todd` files, or this skill.
---

# Todd's rules

The rules live in `references/`, a symlink to `~/bin/.todd`. Read the files for the task before starting, and follow them over your defaults.

These files are also where a general lesson goes. When a skill falls short and the lesson is about how to write, review, or check code or prose, the fix belongs in the matching file here, even when another skill was running. A lesson about one tool, repo, or workflow belongs in that tool's skill.

## Proposing rule changes

When asked to propose changes to these rules, the `.todd` files, or this skill:

1. Before giving a rule an id, check the target file and every open `PROPOSAL-*.md` for ids already taken, and use the next free one.
2. Write the proposal to a new file, `~/bin/.todd/PROPOSAL-<topic>.md`, where `<topic>` is a short kebab-case name for where the findings came from, such as `PROPOSAL-agent-hooks-review-loop.md`. Pick a name no existing `PROPOSAL-*.md` uses, and never add to or overwrite another proposal file. Don't edit the rules themselves.
3. Follow the shape of the existing proposal files: what was seen and how often, then paste-ready text in the house rule shape, then the findings the current rules already cover.
4. Leave out internal repo names, MR numbers, hostnames, paths, and people's names, since `~/bin` is public.

## Review shortcut

A "todd review", `/todd review <target>`, or `/todd` with only a target, where the target is an MR, PR, branch, commit, or diff, means run two passes on that change.

With no target named, pick the change this conversation produced or was given: an MR or PR link the user shared, else the commits and uncommitted edits made in this session.
If more than one fits, list them as a numbered list, recommend the most recent, and wait for the user to confirm. If none fits, ask what to review.

Run each pass in its own subagent, both at once, so neither pass sees the other's conclusions:

1. Code review: tell it the target and to read and follow `references/CODE_REVIEW.md` and the language file for each changed language. If the change is in a service that has users, accounts, roles, or rooms, tell it to read and follow `references/SECURITY.md` too.
2. Devil's advocate: tell it the target and to read and follow `references/DEVILS_ADVOCATE.md`.

Give each subagent the full path to `references/` and the goal of the change, not your own opinion of it.
Give each subagent its own throwaway worktree (`git worktree add --detach <path> <head>`), removed after the round, so it can run the code without touching the author's checkout. Have it write its full report to a file there.
A reviewer often ends a turn on a progress line; if no report file exists, tell it to finish instead of taking the progress line as the report. If a model refuses a defensive check, rerun that pass on another model and say so.
When the two passes contradict each other on a fact, settle it before reporting: run the command or read the line that decides it, report the answer with its evidence, and say which pass was wrong. Never report both claims.
Report the code review findings first, then the devil's advocate verdict. Report only: do not edit files, post comments, or commit unless asked.

## Looping until /todd passes

"Keep going until /todd passes", "until you pass /todd", or "yes" to a question about fixing review findings means a loop, not one round:

1. Fix every finding from both passes: blocking and recommended, 🔴 and 🟡 alike. A finding is not optional because a reviewer called it recommended.
2. Commit, push, and wait for the pipeline to pass.
3. Run both passes again in fresh subagents. Tell them the previous round's findings, so they can confirm each one, and the findings the repo settles (its formatter, a stated constraint), so they are not raised again.
4. Repeat until the code review lists no findings and the devil's advocate verdict is Keep with no 🔴 or 🟡 items, or until step 5 stops the loop.
5. Stop and bring the user a decision, rather than run another round, when any of these holds: two rounds in a row found only new spellings of kinds already reported (DEVILS_ADVOCATE item 14); the loop has run 5 rounds (a guess: in one 9-round loop, every round after the 4th found only new spellings); or the spend so far is near the budget. Report the findings per round, what each round fixed, and the options: stop here with the remaining risk stated in the description, change the scope, or keep going.

Run steps 1 to 5 back to back, pausing only for a decision only the user can make, such as a force-push, then report the rounds, what each fixed, and anything left for the user.

## Posting a review on an MR or PR

When asked to post the review, the two passes go up in different shapes.

Code review: one line comment per finding, anchored on the line that has to change.
Never post code review findings as one summary note. A finding with no line in the diff, such as a missing test file, goes on the nearest changed line it concerns.

Devil's advocate: one note, shaped like this.

```
## 😈 Devil's Advocate 😈

1. **Verdict: <Keep | Change | Replace | Drop>.** <one or two sentences on why>
2. 🔴 **<finding>** (`<file>:<line>`)
   <risk in one or two sentences>. Fix: <what to change>.
3. 🟡 **<finding>** (`<file>:<line>`)
   <risk>. Fix: <what to change>.
4. 🟢 **No action needed:** <concern>: <evidence it is fine>.

Open questions:
1. <question>: <answer, or what would settle it>
```

- 🔴 marks a change that blocks merge, 🟡 a recommended change that does not block merge, 🟢 a concern that was checked and needs no action.
- The verdict is item 1: Keep (ship as is), Change (ship after the 🔴 fixes), Replace (another approach wins) or Drop (not needed).
- Number every item, and list them in that order: the verdict, all 🔴, then 🟡, then 🟢.

Approve only when the head pipeline has finished green, or when every failure is outside the change, such as a known flaky test in code the change does not touch, and say which in the approval note.
After every push, read the approval and merge state again before relying on it: a push can clear an approval, a rebase that keeps the same tree may keep it, and the MR may merge first. If a posted note no longer matches the MR, reply under it.
Before resolving a thread, check the fix in the code. If the author resolved it without the fix, reopen it and say why.

## Which files to read

| File | Read when |
|---|---|
| `CODE_REVIEW.md` | Doing a code review, or writing or editing code in any language |
| `BASH.md` | Writing, editing, or reviewing Bash |
| `PYTHON.md` | Writing, editing, or reviewing Python |
| `GO.md` | Writing, editing, or reviewing Go |
| `RUBY.md` | Writing, editing, or reviewing Ruby |
| `RUST.md` | Writing, editing, or reviewing Rust |
| `JAVASCRIPT.md` | Writing, editing, or reviewing JavaScript |
| `DEVILS_ADVOCATE.md` | Doing a devil's advocate pass on an implementation, design, or plan |
| `HUMAN.md` | Writing anything people read: commit messages, Slack, PR comments, email, docs |
| `DOCUMENT.md` | Writing notes, design docs, or published pages |
| `REQUIREMENTS.md` | Gathering or writing a requirements document |
| `PROJECT.md` | Laying out a new repo or moving files around in one |
| `REPO.md` | Making a repo easier for agents to work in |
| `REFERENCES.md` | Building something an outside repo already does |
| `REWARD_HACKING.md` | Building an AI agent flow (prompts, agent loops, evals), or checking an agent's work for shortcuts that fake a passing result |
| `JAILBREAKS.md` | Building or reviewing an AI agent flow that reads outside text (web pages, email, issues, chat, tool results), holds private data or credentials, or can send anything out. Check the flow against each attack it lists |
| `SECURITY.md` | Writing, reviewing, or auditing a service that has users, accounts, roles, or rooms. The security rules for any program, including a single script, are CR-I in `CODE_REVIEW.md` |

`CODE_REVIEW.md` holds the cross-language rules, and each language file holds only that language's mechanics. Read both, even when the task names one language.

