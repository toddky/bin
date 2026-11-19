---
name: skill-create
description: Use when writing, creating, or scaffolding a new agent skill or SKILL.md for Claude Code, Codex CLI, Gemini CLI, or OpenCode.
---

# Writing Cross-Tool Agent Skills

Create skills that work with Claude Code, OpenAI Codex CLI, Gemini CLI, and OpenCode.

## When Not to Create a Skill

Push back and suggest an alternative when the request is:

- A one-off fix or a story of how something was solved once. Put it in a commit message or notes.
- A preference that applies to every session. Put it in the user's global instructions file or the repo's `AGENTS.md` (in Claude Code, `CLAUDE.md` if the repo has one).
- A rule a script or hook can enforce (path checks, naming, forbidden commands). Write the check instead.
- Already covered by an existing skill. Extend that skill.

## Where to Place Skills

For a project, put the skill in `.agents/skills/<name>/SKILL.md`. Codex, Gemini CLI, and OpenCode read that directory. Claude Code reads only `.claude/skills/`. If `.claude/skills` does not exist yet, make it a symlink to that directory (`ln -s ../.agents/skills .claude/skills`). If the repo already keeps its skills in `.claude/skills/`, leave them there and make `.agents/skills` the symlink.

For a personal (global) skill, write it once in one of these and link it into the other, as described below:
- `~/.agents/skills/<name>/SKILL.md` (Codex, Gemini CLI, OpenCode)
- `~/.claude/skills/<name>/SKILL.md` (Claude Code, and OpenCode also reads it)

`${XDG_CONFIG_HOME:-$HOME/.config}/opencode/skills/` is needed only for a skill that only OpenCode should see.

Before you create anything, check both skills directories for the scope you picked: `.claude/skills` and `.agents/skills` for a project, or `~/.claude/skills` and `~/.agents/skills` for a personal skill. Test each with `[[ -e <dir> ]]`, because `realpath` can print a path for a directory that does not exist. If `[[ -L <dir> ]]` is true for one that fails that test, it is a broken symlink. Create the directory it points to with `(cd "$(dirname <dir>)" && mkdir -p "$(readlink "$(basename <dir>)")")`, because a relative target counts from the link's own directory. Then test again. Run `realpath` on the ones that exist. Then:

- If both resolve to the same directory, create the skill there once and add no symlink.
- If neither exists, create `.agents/skills` (or `~/.agents/skills`), create the skill there, and symlink the `.claude` one to it.
- If only one exists, create the skill there and symlink the missing directory to it.
- If both exist and differ, create the skill in one and link only the skill into the other, as `<other skills dir>/<name>`.

Before any `ln -s`, create the link's parent (for example `mkdir -p .claude`). In a project, use a relative target, because git stores the target as written and an absolute path breaks in every other clone. Use `ln -s ../.agents/skills .claude/skills` for the directory, or `ln -s ../../.agents/skills/<name> .claude/skills/<name>` for one skill. For a personal skill, an absolute target works.

Never run `ln -s` onto a skills directory that already exists, because `ln` then puts the link inside it.

## SKILL.md Format

A cross-tool `SKILL.md` needs YAML frontmatter with `name` and `description`. Codex requires both, and OpenCode does not advertise a skill that has no description. Claude Code falls back to the directory name and the first non-empty line of the body, so a skill without them works fully only there.

```markdown
---
name: my-skill-name
description: Use when <the tasks, symptoms, or phrases that should trigger this skill>.
---

Instructions for the agent to follow when this skill is invoked.
```

## Naming Convention

Use a category prefix as the first keyword in the name:

```
<category>-<descriptive-name>
```

The category groups related skills and lets one permission rule cover a family (for example, a rule on `git-*`).

Pick a category from the skills you already have. If nothing fits, start a new one. Put the tool or system first, so related skills sort together.

| Pattern | Use it for | Examples |
|---|---|---|
| `<tool>-basics` | The foundational reference for a tool or system: how to reach it, how to authenticate, where things live, and the shared concepts. Other skills in the family point to it instead of repeating it. `-basics` is always the last word. | `gitlab-basics`, `jira-basics` |
| `<tool>-debug` or `<tool>-<area>-debug` | Diagnosing failures of that tool, or of one area of it. `-debug` is always the last word. | `tmux-debug`, `gitlab-pipeline-debug` |
| `<tool>-<instance>` | A second instance or variant of a tool that behaves differently from the main one, so it gets its own skill. | `gitlab-<instance>` for a second GitLab server, `jira-<project>` for one Jira project's conventions |
| `codebase-<repo>` | Working on one specific repo. Use `codebase-`, not `project-`, because "project" also means a project in an issue tracker. | `codebase-myapp` |
| `scripting-<language>` | Conventions for writing in a language. | `scripting-bash`, `scripting-python` |
| `skill-<action>` | Meta-skills for the skill system itself. | `skill-create` |

Rules that go with the table:
- A `-basics` skill holds what every other skill in the family needs, such as authentication and URL conventions. A workflow skill links to it and doesn't copy it.
- Don't make a `-basics` skill for something with one workflow. Instead give that skill a descriptive name that starts with the tool.
- Split a family when a variant behaves differently. For example `gitlab-basics` covers the main server and a second server gets its own skill.

### Name Rules

These limits come from the [Agent Skills spec](https://agentskills.io/specification). Not every tool enforces them, so follow them to make the skill load in all of them.

- 1-64 characters
- Lowercase alphanumeric with single hyphens: `[a-z0-9]+(-[a-z0-9]+)*`
- Must match the containing directory name

## Description Rules

- 1-1024 characters (also from the Agent Skills spec)
- If a nearby skill is easy to confuse with this one, include negative scope ("Not for X")
- Never summarize the skill's steps in the description. An agent that reads a step summary acts on it and skips the body.
- Put the words the user is most likely to type first, because the agent picks a skill by reading its description
- Start with "Use when..." and list only triggers: tasks, symptoms, error text, tool names, phrases the user would type

Good: `Use when a CI pipeline failed, a job is red, or the user asks why CI broke.`
Bad: `Checks pipeline status, fetches job logs, and summarizes the root cause.` (describes steps, not triggers)

## Cross-Tool Frontmatter

Fields every tool accepts:
- `name` (needed for a cross-tool skill, see "SKILL.md Format")
- `description` (needed for a cross-tool skill)
- `compatibility`, `license`, `metadata` (optional, and most tools store them without acting on them)

Claude Code fields (other tools may ignore them):
- `agent`: subagent type when using `context: fork`
- `allowed-tools`: tools the skill can use without a permission prompt (for example `Read Grep Glob`, space-separated as the Agent Skills spec defines it, which Claude Code also accepts). The other tools stay available, so this field does not lock a skill down. The Agent Skills spec lists it as experimental, so other tools may honor it.
- `context`: `fork` to run in a subagent
- `disable-model-invocation`: `true` to prevent auto-invocation
- `disallowed-tools`: tools removed while the skill is active. This is the field that restricts.
- `user-invocable`: `false` to hide from slash menu

Codex CLI reads extra settings from a separate file, not from frontmatter:
- `agents/openai.yaml`: UI metadata and invocation policy

## Scripts in Skills

- If a script needs `jq` or another tool, say so in the skill
- Never put secrets in command arguments. Instead use environment variables or stdin.
- Never write directly to `/tmp`. Instead use `mktemp` for temporary files.
- Prefer Bash for skill scripts over Python or other languages, because every one of these tools can run it with nothing to install
- Start with `#!/usr/bin/env bash`. Check each command's exit status, and print an error that says how to fix the problem.
- Use `[[ ]]` instead of `[ ]`

## Skill Content Best Practices

- Be imperative: "Do X", not "You should consider doing X"
- Include examples of expected input and output when relevant
- Keep SKILL.md under 500 lines and use supporting files for details
- Start with a clear heading explaining the skill's purpose
- State the goal and the constraints ("always run tests before opening a PR"). Number the steps only when the order matters. If doing step 3 before step 2 breaks things, put the sequence in a script.
- Use bullet lists for reference and convention skills
- When a rule matters, give the reason in the same sentence, so the agent can apply it to cases the skill never named. Not "use model X", but "use model X, because model Y is deprecated and returns errors".

### People, tickets, and other facts that go stale

Don't write facts that stop being true without anyone touching the skill. Instead write the lookup that finds the current answer.

| Don't write | Write instead |
|---|---|
| Who owns, maintains, or reviews a repo, file, or tool ("ask Sam, the maintainer") | The command that lists them, such as a members API call filtered to maintainers |
| CODEOWNERS usernames | Read the `CODEOWNERS` file. On a merge request, the approval API lists who can approve each rule. |
| A ticket as status or tracking ("tracked in PROJ-456", "fixed in PROJ-789") | A saved search, such as `project = PROJ AND text ~ "login timeout"` |
| The person a document names as the reviewer | A link to that document |

Keep these, because they don't go stale and they save work:

- Nicknames: what the user calls someone, mapped to the real person or account ID.
- Placeholders in format examples, such as `PROJ-<n>`, and defaults such as the user's own account ID as the assignee.
- Stable lookup tables: values that never change but cost an extra API call every time, such as account IDs, custom field IDs, and transition IDs.

## Supporting Files

Skills can include extra files alongside SKILL.md:

```
my-skill/
├── SKILL.md            # Required: main instructions
├── examples/           # Optional: example outputs
├── references/         # Optional: detailed docs
├── scripts/            # Optional: executable scripts
└── templates/          # Optional: templates to fill in
```

Reference supporting files from SKILL.md so the agent knows they exist.

## Creating a New Skill

### Name

1. Pick a category prefix and a descriptive kebab-case name (for example, `github-ci-debug`).
2. Check for name conflicts in the directories from "Where to Place Skills", and in any tool-specific ones that exist, such as `.gemini/skills`, `.opencode/skills`, and their home-directory copies. The tools disagree on which copy wins: in Claude Code a personal skill hides a project skill, and in Gemini CLI the project skill wins. Treat any duplicate as a conflict, and pick a different name or ask the user before overwriting.

### Baseline

Run the baseline before the skill exists, so you can tell what the skill changes:

1. Write one or two realistic task prompts the skill should handle. One should trigger it by keyword alone, without naming the skill. Add one prompt that is close to the skill's subject but should not trigger it. For each prompt, write down what a correct result looks like before running it.
2. Run each prompt in a fresh subagent and note what it gets wrong or improvises.
3. If the baseline run had no problems, the skill may not be needed. Tell the user before creating it.

### Create

1. Pick the skills directory using "Where to Place Skills".
2. Create the directory `<skills_dir>/<name>/`.
3. Write `SKILL.md` with frontmatter and instructions.
4. If the skill needs scripts, put them in `<skills_dir>/<name>/scripts/`, run `chmod +x` on them, and check each Bash script with `bash -n`.
5. Confirm the file exists with `[[ -f <skills_dir>/<name>/SKILL.md ]]`. Then confirm the skill's name and description appear in the tool's skill list. Most tools pick up a new skill without a restart. Two cases need a reload: Gemini CLI (`/skills reload`), and Claude Code when the skills directory itself was created in this session (`/reload-skills`). You cannot type slash commands, so ask the user to run the reload before the Test section.

### Test

1. Run the baseline prompts again in fresh subagents.
2. Check that the skill triggers, that it fixes the problems from the baseline, and that the should-not-trigger prompt does not load it.
3. Report the baseline and test results to the user in two or three lines each.

## Example: Minimal Skill

```markdown
---
name: github-ci-debug
description: Use when verifying the current branch's CI status or debugging a failed pipeline or job.
---

# Debug GitHub CI

1. Run `gh run list --branch "$(git branch --show-current)" --limit 1` to get the latest run.
2. If it failed, run `gh run view <run-id>` to see its jobs.
3. For a failed job, fetch its log with `gh run view <run-id> --log-failed`.
4. Summarize which jobs failed and the root cause.
```
