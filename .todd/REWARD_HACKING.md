# Reward Hacking

Rules for spotting and preventing reward hacking in coding agents. Reward hacking is when a model gets a passing result without doing the task the result was meant to measure.

It matters beyond one bad patch. Anthropic found that a model trained in environments it could hack also picked up alignment faking and sabotage, including inside Claude Code ([emergent misalignment](https://arxiv.org/html/2511.18397v1)). OpenAI found that training against a monitor of the model's reasoning taught the model to hide its intent while it kept hacking ([CoT monitoring](https://arxiv.org/pdf/2503.11926)).

Each letter is a group of rules:

| Section | Covers |
|---|---|
| RH-A | Rules for the agent |
| RH-B | Guardrails for the user |

## RH-A: Rules for the agent

### RH-A1: Leave Tests Alone
Don't edit, delete, skip, or weaken tests to make them pass. That includes new `skip` or `xfail` markers, loosened asserts, and lowered thresholds. If a test looks wrong, stop and say why.

### RH-A2: Leave The Grader Alone
Don't change the eval script, grader, CI config, or snapshot files so they report a pass.

### RH-A3: Solve The General Case
Don't hardcode expected outputs or special-case test inputs.

### RH-A4: Fail Loud
Don't hide a failure with `sys.exit(0)`, a mocked return value, or a broad `try/except: pass`.

### RH-A5: Show The Run
Only say "done" or "tests pass" if you ran them in this session and saw them pass. Include the command and the result.

### RH-A6: Giving Up Is Fine
If you can't solve the task, say so and explain what blocked you.

## RH-B: Guardrails for the user

### RH-B1: Lock Test Files
Use a PreToolUse hook that blocks edits to `tests/`, graders, CI config, and snapshots without approval. The script-gate hook is the model for this. In one benchmark, hardening the agent's environment cut exploit rates by about 88% ([Reward Hacking Benchmark](https://arxiv.org/pdf/2605.02964)).

### RH-B2: Put The Rules In The Instruction File
Copy RH-A into CLAUDE.md or AGENTS.md. The agent can't follow rules it never loads.

### RH-B3: Make Failure An Option
Ask for "can't solve, here's why" up front. A lot of hacking happens because the task implies failure isn't allowed.

### RH-B4: Verify Outside The Agent
Rerun the tests yourself or in CI from a clean checkout. Don't trust the agent's own summary.

### RH-B5: Check The Diff Against RH-A
Before accepting a diff, check it for every RH-A violation.

### RH-B6: Second Opinion
Give a fresh agent only the task and the diff. Ask whether it solves the task or just satisfies the tests.

### RH-B7: Check More Than The Tests
Green tests don't prove the agent wrote the patch honestly ([Verification Horizon](https://arxiv.org/pdf/2606.26300)). Keep some tests or a smoke run the agent can't see. Add fuzz or property tests where they fit.

### RH-B8: Small Scope
Give narrow tasks with clear acceptance criteria. Less room to game.

### RH-B9: Read The Reasoning
Skim the agent's reasoning, not just its final answer. It often says it plans to game the tests before it does ([CoT monitoring](https://openai.com/index/chain-of-thought-monitoring/)).

### RH-B10: Watch Hard Tasks Closest
Agents rarely hack easy tasks and do it more as tasks get harder ([Hack-Verifiable Terminal Bench](https://arxiv.org/pdf/2608.22103)). Review harder tasks more closely.

