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

### RH-A7: Name What You Read
Only say "every file was read", "no findings", or "nothing missing" for a scope you can list. Include the list of files you read in full, and list every file in the scope you skimmed or did not open. A verdict covers only the files on the first list.
For a review, an approval, or a resolved thread, read the diff at the head you judge and name that head. A title, description, commit message, or the author's reply is not a read; if you didn't read the diff, say so instead of posting a verdict.

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

### RH-B11: Check The Read List Against The File List
Before you accept a review, audit, or search verdict from an agent, compare its list of files read against the real file list of the scope, such as `git ls-files` for the directory. Treat every file missing from the agent's list as unreviewed, and a "none found" verdict with no list as no verdict. In one audit an agent wrote "every file was read" above a list naming a third of the package, and the unread part held both high findings.

### RH-B12: Hooks Stop Shortcuts, Not Sabotage
A hook that runs where the agent can run code catches accidents and common shortcuts, such as editing a test or skipping a linter. It can't stop an agent that means to get past it, since the agent can build the change in a string, write files from a script, or forge what the hook reads. Write that scope into the hook's docs. Catch deliberate evasion in a layer the agent can't touch: a clean-checkout CI run (RH-B4), hidden tests (RH-B7), or a person reviewing every change to an existing test.

### RH-B13: Know The Ways Tests Get Tampered With
When checking a diff against RH-A, look for these as well as removed asserts and skips. Each one made a failing pytest suite pass without fixing the code:
- Outcome rewriting: a `pytest_runtest_makereport` hook in a conftest, in a plugin module named by `pytest_plugins`, or in a `pytest11` entry point.
- Collection: `__test__ = False`, `pytest.importorskip`, `raise pytest.skip.Exception` in an autouse fixture, `testpaths = []` or `addopts = "-k never"` in a new nested config, a `.gitignore` that hides a new conftest.
- Replacing the runner: a `pytest.py`, `_pytest/`, `sitecustomize.py`, `usercustomize.py` or `*.pth` next to the tests.
- Ending the run: `os._exit`, `posix._exit`, `os.exec*`, `os.abort`, or `pytest.exit` in a test, often after writing the junit report.
- Changed expectations: an expected value edited to match the broken code, or a setup line that an assert reads.
- Wrapped asserts: `contextlib.suppress(AssertionError)`, `try`/`except`, `pytest.raises(AssertionError)`, `for _ in ():`, `while 0:`, an `if` on the broken value, a no-op decorator.
- The old test no longer runs: a nested def with the same name, an `if/else` pair of defs, a move into a class pytest doesn't collect plus a stub.
- Patching the code under test: module attribute writes in a conftest or any module the suite imports, `monkeypatch` on the code under test, `sys.modules[...]`, `inspect.getmodule(...)`, `__kwdefaults__`, a parameter default, or a fixture named like an imported name.
- Hiding the change from git: `assume-unchanged`, `skip-worktree`, `.git/info/exclude`, or a branch named like the base ref.
- Lint: a nested linter config, a file-level `# ruff: noqa`, `# NOQA`, `# flake8: noqa`, or a lowered version pin.

