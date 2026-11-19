---
name: skill-create
description: Use when writing, creating, or scaffolding a new agent skill or SKILL.md for Claude Code, Codex CLI, or OpenCode.
---

# Writing Cross-Tool Agent Skills

Create skills that work with Claude Code, OpenAI Codex CLI, and OpenCode.
Gemini CLI does not support skills natively.

## When Not to Create a Skill

Push back and suggest an alternative when the request is:

- A one-off fix or a story of how something was solved once. Put it in a commit message or notes.
- A rule a script or hook can enforce (path checks, naming, forbidden commands). Write the check instead.
- A preference that applies to every session. Put it in the user's global instructions file or the repo's `AGENTS.md`.
- Already covered by an existing skill. Extend that one with `skill-update`.

## Where to Place Skills

Before creating symlinks, check whether `~/.claude/skills` is itself a symlink to a shared skills directory (run `realpath ~/.claude/skills`). If it is, create the skill directory there directly. Per-skill symlinks would be circular.

For a project, use `.agents/skills/<name>/SKILL.md` (Codex and OpenCode read it natively). If `.claude/skills` is not a symlink to it, symlink or copy the skill there for Claude Code.

For personal (global) skills:
- `~/.agents/skills/<name>/SKILL.md` (Codex and OpenCode)
- `~/.claude/skills/<name>/SKILL.md` (Claude Code)
- `~/.config/opencode/skills/<name>/SKILL.md` (OpenCode)

## SKILL.md Format

Every `SKILL.md` requires YAML frontmatter with `name` and `description`:

```yaml
---
name: my-skill-name
description: One-line explanation of what this skill does and when to use it.
---

Instructions for the agent to follow when this skill is invoked.
```

## Naming Convention

Use a category prefix as the first keyword in the name:

```
<category>-<descriptive-name>
```

The category groups related skills and makes permission patterns easy (for example, `"git-*": "allow"`).

Pick a category from the skills you already have, or start a new one if nothing fits. Put the tool or system first, so related skills sort together.

| Pattern | Use it for | Examples |
|---|---|---|
| `<tool>-basics` | The foundational reference for a tool or system: how to reach it, how to authenticate, where things live, and the shared concepts. Other skills in the family point to it instead of repeating it. `-basics` is always the last word. | `gitlab-basics`, `jira-basics` |
| `<tool>-debug` | Diagnosing failures of that tool. `-debug` is always the last word. | `gitlab-pipeline-debug`, `tmux-debug` |
| `<tool>-<instance>` | A second instance or variant of a tool that behaves differently from the main one, so it gets its own skill. | `gitlab-<instance>` for a second GitLab server, `jira-<project>` for one Jira project's conventions |
| `codebase-<repo>` | Working on one specific repo. Use `codebase-`, not `project-`. | `codebase-myapp` |
| `scripting-<language>` | Conventions for writing in a language. | `scripting-bash`, `scripting-python` |
| `skill-<action>` | Meta-skills for the skill system itself. | `skill-create`, `skill-update` |

Rules that go with the table:
- Don't make a `-basics` skill for something with one workflow. Give that skill a plain descriptive name.
- A `-basics` skill holds what every other skill in the family needs, such as authentication and URL conventions. A workflow skill links to it and doesn't copy it.
- Split a family when a variant behaves differently. For example `gitlab-basics` covers the main server and a second server gets its own skill.

### Name Rules

- Lowercase alphanumeric with single hyphens: `[a-z0-9]+(-[a-z0-9]+)*`
- 1-64 characters
- Must match the containing directory name
- No leading or trailing hyphens, no consecutive hyphens

## Description Rules

- 1-1024 characters
- Start with "Use when..." and list only triggers: tasks, symptoms, error text, tool names, phrases the user would type
- Never summarize the skill's steps in the description. An agent that reads a step summary acts on it and skips the body.
- Put the most likely search terms first, because descriptions are matched by keyword
- Include negative scope ("Not for X") if a nearby skill is easy to confuse with this one

Good: `Use when a CI pipeline failed, a job is red, or the user asks why CI broke.`
Bad: `Checks pipeline status, fetches job logs, and summarizes the root cause.` (describes steps, not triggers)

## Cross-Tool Frontmatter

Universal fields (all tools):
- `name` (required)
- `description` (required)

Claude Code extras (ignored by others):
- `disable-model-invocation`: `true` to prevent auto-invocation
- `user-invocable`: `false` to hide from slash menu
- `allowed-tools`: restrict tool access (for example `Read, Grep, Glob`)
- `context`: `fork` to run in a subagent
- `agent`: subagent type when using `context: fork`

Codex CLI extras (ignored by others):
- `agents/openai.yaml` file for UI metadata and invocation policy

OpenCode extras (ignored by others):
- `license`, `compatibility`, `metadata` fields in frontmatter

## Scripts in Skills

- Prefer Bash for skill scripts over Python or other languages
- Start with `#!/usr/bin/env bash` and `set -euo pipefail`
- Use `[[ ]]` instead of `[ ]`
- Use `mktemp` for temporary files, and never write directly to `/tmp`
- Never put secrets in command arguments. Use environment variables or stdin.
- If a script needs `jq` or another tool, say so in the skill

## Skill Content Best Practices

1. Start with a clear heading explaining the skill's purpose
2. State the goal and the constraints ("always run tests before opening a PR"). Number the steps only when the order matters. If doing step 3 before step 2 breaks things, put the sequence in a script.
3. Use bullet lists for reference and convention skills
4. Keep SKILL.md under 500 lines and use supporting files for details
5. Be imperative: "Do X", not "You should consider doing X"
6. Include examples of expected input and output when relevant
7. When a rule matters, give the reason in the same sentence, so the agent can apply it to cases the skill never named. Not "use model X", but "use model X, because model Y is deprecated and returns errors".

### People, tickets, and other facts that go stale

Don't write facts that stop being true without anyone touching the skill. Write the lookup that finds the current answer instead.

| Don't write | Write instead |
|---|---|
| Who owns, maintains, or reviews a repo, file, or tool ("ask Sam, the maintainer") | The command that lists them, such as a members API call filtered to maintainers |
| CODEOWNERS usernames | Read the `CODEOWNERS` file. On a merge request, the approval API lists who can approve each rule. |
| A ticket as status or tracking ("tracked in PROJ-456", "fixed in PROJ-6645") | A saved search, such as `project = PROJ AND text ~ "login timeout"` |
| The person a document names as the reviewer | A link to that document |

Keep these, because they don't go stale and they save work:

- **Stable lookup tables**: values that never change but cost an extra API call every time, such as account IDs, custom field IDs, and transition IDs.
- **Nicknames**: what the user calls someone, mapped to the real person or account ID.
- **Placeholders** in format examples, such as `PROJ-<n>`, and defaults such as the user's own account ID as the assignee.

## Supporting Files

Skills can include extra files alongside SKILL.md:

```
my-skill/
├── SKILL.md            # Required: main instructions
├── templates/          # Optional: templates to fill in
├── examples/           # Optional: example outputs
├── scripts/            # Optional: executable scripts
└── references/         # Optional: detailed docs
```

Reference supporting files from SKILL.md so the agent knows they exist.

## Scaffolding a New Skill

1. Pick a category prefix and a descriptive kebab-case name (for example, `git-check-ci`).
2. Check for name conflicts. List the skills directory and confirm no skill has the same name. If one does, pick a different name or ask the user before overwriting.
3. Check whether `~/.claude/skills` is a symlink (`realpath ~/.claude/skills`). If it resolves to a shared directory, create the skill there directly.
4. Create the directory `<skills_dir>/<name>/`.
5. Write `SKILL.md` with frontmatter and instructions.
6. If the skill needs scripts, put them in `<skills_dir>/<name>/scripts/` and run `chmod +x` on them.
7. Confirm the skill is discoverable: run `realpath ~/.claude/skills/<name>/SKILL.md`.
8. Run a baseline test before calling the skill done:
   1. Write one or two realistic task prompts the skill should handle. One should trigger it by keyword alone, without naming the skill. Add one prompt that is close to the skill's subject but should not trigger it. For each prompt, write down what a correct result looks like before running it.
   2. Move the skill directory into a `mktemp -d` directory so it is hidden, run each prompt in a fresh subagent, and note what it gets wrong or improvises.
   3. Move the skill directory back and run the same prompts in fresh subagents. Check that the skill triggers, that it fixes the problems from step 2, and that the should-not-trigger prompt does not load it.
   4. If the baseline run had no problems, the skill may not be needed. Tell the user before keeping it.
   5. Report both results to the user in two or three lines each.

## Example: Minimal Skill

```yaml
---
name: git-check-ci
description: Use when verifying the current branch's CI status or debugging a failed pipeline or job.
---

# Check CI Pipeline

1. Run `gh run list --branch "$(git branch --show-current)" --limit 1` to get the latest run.
2. If it failed, run `gh run view <run-id>` to list the jobs.
3. For a failed job, fetch its log with `gh run view <run-id> --log-failed`.
4. Summarize which jobs failed and the root cause.
```
