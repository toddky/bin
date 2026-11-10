---
name: todd
description: Todd's coding, review, and writing rules. Load before a code review, a devil's advocate pass, or checking an agent's work for reward hacking; before building or changing an AI agent flow (prompts, agent loops, evals, test harnesses an agent runs against); before writing or editing Bash, Python, Go, Ruby, or JavaScript; and before writing a document, requirements, repo layout, or any text other people will read (commit messages, Slack, PR comments). Also load when the user asks for a "todd review" or says to run todd on an MR, PR, branch, or diff, which means a code review plus a devil's advocate pass.
---

# Todd's rules

The rules live in `references/`, a symlink to `~/bin/.todd`. Read the files for the task before starting, and follow them over your defaults.

## Review shortcut

A "todd review", `/todd review <target>`, or `/todd` with only a target, where the target is an MR, PR, branch, commit, or diff, means run two passes on that change.

With no target named, pick the change this conversation produced or was given: an MR or PR link the user shared, else the commits and uncommitted edits made in this session.
If more than one fits, list them as a numbered list, recommend the most recent, and wait for the user to confirm. If none fits, ask what to review.

Run each pass in its own subagent, both at once, so neither pass sees the other's conclusions:

1. Code review: tell it the target and to read and follow `references/CODE_REVIEW.md` and the language file for each changed language.
2. Devil's advocate: tell it the target and to read and follow `references/DEVILS_ADVOCATE.md`.

Give each subagent the full path to `references/` and the goal of the change, not your own opinion of it.
Report the code review findings first, then the devil's advocate verdict. Report only: do not edit files, post comments, or commit unless asked.

## Which files to read

| File | Read when |
|---|---|
| `CODE_REVIEW.md` | Doing a code review, or writing or editing code in any language |
| `BASH.md` | Writing, editing, or reviewing Bash |
| `PYTHON.md` | Writing, editing, or reviewing Python |
| `GO.md` | Writing, editing, or reviewing Go |
| `RUBY.md` | Writing, editing, or reviewing Ruby |
| `JAVASCRIPT.md` | Writing, editing, or reviewing JavaScript |
| `DEVILS_ADVOCATE.md` | Doing a devil's advocate pass on an implementation, design, or plan |
| `HUMAN.md` | Writing anything people read: commit messages, Slack, PR comments, email, docs |
| `DOCUMENT.md` | Writing notes, design docs, or published pages |
| `REQUIREMENTS.md` | Gathering or writing a requirements document |
| `PROJECT.md` | Laying out a new repo or moving files around in one |
| `REPO.md` | Making a repo easier for agents to work in |
| `REFERENCES.md` | Building something an outside repo already does |
| `REWARD_HACKING.md` | Building an AI agent flow (prompts, agent loops, evals), or checking an agent's work for shortcuts that fake a passing result |

`CODE_REVIEW.md` holds the cross-language rules, and each language file holds only that language's mechanics. Read both, even when the task names one language.

