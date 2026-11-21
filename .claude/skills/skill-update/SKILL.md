---
name: skill-update
description: Use when any other skill is invoked, when the user corrects a skill's result, or when a skill should have triggered but didn't. Also known as "skill update skill" or "skill update".
---

# Updating Skills After They Fall Short

Run this alongside every other skill. When a skill has a gap or a mistake, propose a fix so the same problem does not come back.

## When to Suggest an Update

After a skill is used, suggest an update if any of these happened:

- A command, URL, API, or path in the skill is out of date.
- A skill should have loaded but didn't, because its description lacked the words the user typed.
- The skill assumed something that was false.
- The skill did not cover a case you hit.
- The user corrected the result or asked you to redo it.
- You had to improvise a step the skill should have documented.
- You read an instruction differently than it was meant.

## When Not to Suggest an Update

- The fix would apply to this one case only.
- The problem came from incomplete input from the user, not from a gap in the skill.
- The skill worked and the user is satisfied.

## How to Suggest an Update

1. Check whether the skill was loaded. If it wasn't, fix the description, because the agent never read the body.
2. Decide which file the fix goes in, using "Where the Fix Goes".
3. Read that file.
4. Propose the exact change: what to add, modify, or remove.
5. Say what went wrong and how the change prevents it.
6. If there are several fixes, list them numbered and ask the user to approve them together.

## Where the Fix Goes

Some lessons do not belong in the skill that was running.

- If a skill repeats a rule the user's global rules already have, don't keep both. Instead delete the copy and point to the global rule.
- If the lesson is about how to write, review, or check code or prose in general, put it in the user's global rules: their instructions file, or the rules files one of their skills points to. This holds even when the mistake happened while another skill was running, such as a bad Bash idiom during a deploy skill.
- If the lesson is about one tool, repo, path, command, or workflow, put it in that skill's `SKILL.md`.

If you can't tell which one fits, propose the global rules first.

## Choosing the Form of the Fix

Match the fix to how the skill failed, because the wrong form can make the skill worse.

| What went wrong | Fix with | Not with |
|---|---|---|
| The agent knew the rule and skipped it | A direct prohibition, plus the excuse the agent gave, quoted, and why the excuse is wrong | Soft wording ("prefer", "consider") |
| The agent followed the skill but the output had the wrong shape | A recipe that describes the output: its parts, in order | A list of "don't" rules |
| The agent left out a required part | A required field in the template it fills in | A reminder sentence near the template |
| The behavior should depend on the situation | A condition on something the agent can observe ("if the merge request has conflicts, ...") | A blanket rule plus exceptions |
| The skill didn't load | The user's actual words, added to the description | New body text, because the agent never read the body |

- Don't add a hedge like "unless it matters", because it reopens the rule. Instead write a real exception as its own condition.
- Don't add an exemption like "this doesn't apply to code blocks", because agents stretch it to other cases. Instead restructure the rule so it can't reach the exempt part.

## How to Apply an Update

- Don't commit unless the user asks.
- If the skill has supporting files (data, templates, examples), check whether they need the same change.
- Leave unrelated sections alone.
- Make the smallest change that uses the right form.
- Put a new edge case next to the instructions it relates to.

## Facts That Go Stale

Don't add a fact that stops being true without anyone touching the skill, such as who owns a repo or which ticket tracks a bug. Instead add the lookup that finds the current answer. When you review a skill, flag facts like these.

Keep nicknames, placeholders in format examples, and lookup tables of values that never change, such as account IDs and field IDs.

The `skill-create` skill has the full table under "People, tickets, and other facts that go stale".

## Finding the File to Edit

A skills directory is often a symlink, and one skill inside it can be a symlink into another repo. Before you edit, run `realpath <skills_dir>/<name>/SKILL.md` and edit the path it prints.

When the user asks you to commit:

1. Find the repo with `git -C "$(dirname <resolved path>)" rev-parse --show-toplevel`. If that fails, the file is not in a repo and the edit is all there is.
2. Commit in that repo, and name the resolved path in the commit command. A path that goes through a symlinked directory makes git commit a copy of the file in the wrong repo.
3. Follow that repo's commit message convention.
