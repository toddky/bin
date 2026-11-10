---
name: todd
description: Todd's coding, review, and writing rules. Load before a code review, a devil's advocate pass, or checking an agent's work for reward hacking; before building or changing an AI agent flow (prompts, agent loops, evals, test harnesses an agent runs against); before writing or editing Bash, Python, Go, Ruby, or JavaScript; and before writing a document, requirements, repo layout, or any text other people will read (commit messages, Slack, PR comments).
---

# Todd's rules

The rules live in `references/`, a symlink to `~/bin/.todd`. Read the files for the task before starting, and follow them over your defaults.

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

