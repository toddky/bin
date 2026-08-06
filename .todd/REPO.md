# AI-Friendly Repo

## Principles

- **Canonicality.** Every file is either a source of truth about the system today, or a record of intent/history. Never both. Mark which is which.
- **Localization.** Put context as close as possible to where it's used. Move it up to a parent/root file only if it applies broadly.
- **Verifiability.** Agents need a way to check their own work: tests, lint/type checks, pre-commit hooks.
- **Interoperability.** Keep instructions in plain files any agent can read.
- **Default-no.** Load nothing into every session unless it changes behavior for most tasks. Every always-loaded line earns its place.

## Layered Structure

Set these up from the start, not retrofitted later.

1. Root AGENTS.md (or CLAUDE.md/equivalent). Loaded every session: engineering principles, workflow rules, communication patterns. A few hundred lines at most; every line costs tokens for every agent.
2. Nested AGENTS.md files. One per directory that has conventions the root file doesn't cover (import rules, concurrency patterns, dependency rules). Narrow and operational, not descriptive.
3. Skills. A directory of reusable skill packages (backend patterns, testing standards, doc conventions, domain knowledge). Loaded on demand, not by default.
4. Sub-agent roles. Defined roles for narrow jobs (verifier, standards enforcer), each with a clear description of what it checks and reports.
5. Tool/MCP access. Give agents direct access to the systems they need (issue tracker, logs, analytics, dev database) instead of humans copy-pasting context into prompts.
6. Automated enforcement. Linting, formatting, type checking, and pre-commit hooks that catch violations before review. The backstop for everything above; unenforced rules get forgotten.

## Writing AGENTS.md / CLAUDE.md Files

- Instruct, don't describe. An agent knows what `src/` is. Tell it how to behave: "use strict type checking," not "we use TypeScript."
- Directory-specific rules go in that directory's AGENTS.md, not the root file.
- Use resilient references. Describe things by name or purpose, not by exact file paths that will move.
- Text-only. No ASCII art, no formatting that breaks grep or parsing.

## Testing as a First-Class Requirement

- Standardize the testing framework before scaling up agent-written code: unit tests, integration tests, fixtures, CI integration.
- Write a testing skill stating what tests are required, when, and how they're structured. Tune the language until agents stop over-testing and under-testing.
- Treat agent test-writing as a first-class requirement, not a bolt-on after the infrastructure exists.

## Maintenance

- Every canonical file gets an explicit owner in frontmatter. CI fails if a new skill or markdown file is missing one.
- Scan AGENTS.md files and skills periodically for staleness, contradictions, duplicate instructions, and broken references. Canonical files must agree with each other; non-canonical files need not.

## New Repo Checklist

1. Write the root AGENTS.md before any other tooling.
2. Decide canon vs. not-canon locations (`docs/`, `.specs/`, `.notes/`) before the first commit.
3. Add lint, type-check, and pre-commit hooks in the first commit.
4. Add nested AGENTS.md files only where the root doesn't cover a directory's conventions.
5. Add owner frontmatter as you create each canonical file, not retroactively.
6. Write the testing skill alongside the testing framework, not after.

