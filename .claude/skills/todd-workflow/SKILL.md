---
name: todd-workflow
description: Todd's layout for running teams of agents in tmux, one session per workstream, all under ~/work. Load before setting up ~/work, cloning a repo into ~/work/REPOS, starting or restarting an agent-WORD tmux session, starting or finishing a task (task dir, worktree, branch, window), naming an agent, window, pane, branch or task dir, or writing STATUS.md, TASK.md or DONE.md. Also load after a reboot to rebuild the sessions.
---

# todd-workflow: one tmux session of agents per workstream

Each workstream gets a tmux session with a lead agent, a note taker, and one window per task.
Every task works in its own git worktree, so agents never share a checkout.
All of it lives under `~/work`, and everything an agent needs to resume after a reboot is in files.

```text
~/work -> <large shared disk>
├── REPOS/                                   # one clone per repo, shared by every session
│   ├── webapp/
│   │   ├── .git/                            # bare clone
│   │   └── main/                            # default-branch worktree, read-only reference
│   └── workflow -> ~/workflow               # Todd's private workflow repo
├── AGENTS -> REPOS/workflow/agents          # only files to commit, tracked in the workflow repo
│   └── shop/                                # session agent-shop
│       ├── STATUS.md                        # session header and task table
│       └── 2026-11-16-fix-login/            # task fix-login, window task-fix-login
│           ├── TASK.md                      # status header, goal, MRs
│           └── DONE.md                      # summary, written when the MR merges
└── WORKTREES/                               # checkouts and build output, never committed
    └── shop/
        └── 2026-11-16-fix-login/
            └── webapp/                      # git worktree of REPOS/webapp, branch shop/fix-login
```

`AGENTS/` and `WORKTREES/` share the same `WORD/YYYY-MM-DD-TASK` path, so a task's files and its checkout are easy to find from each other.

## Names

A session has one WORD, a single word with no hyphens. A task has a TASK name, which may contain hyphens. Everything else is built from those two.

| Thing | Pattern | Example |
|---|---|---|
| tmux session | `agent-WORD` | `agent-shop` |
| Window 1 | `lead` | `lead` |
| Task window | `task-TASK` | `task-fix-login` |
| Manual window | any name not starting with `task-` | `build` |
| Lead agent | `agent-WORD-lead` | `agent-shop-lead` |
| Note taker | `agent-WORD-note` | `agent-shop-note` |
| Main writer | `agent-WORD-TASK` | `agent-shop-fix-login` |
| Extra writer | `agent-WORD-TASK.N` | `agent-shop-fix-login.2` |
| Reviewer | `agent-WORD-TASK.review` | `agent-shop-fix-login.review` |
| Task dir | `AGENTS/WORD/YYYY-MM-DD-TASK` | `AGENTS/shop/2026-11-16-fix-login` |
| Worktree | `WORKTREES/WORD/YYYY-MM-DD-TASK/<repo>` | `WORKTREES/shop/2026-11-16-fix-login/webapp` |
| Branch | `WORD/TASK` | `shop/fix-login` |

- WORD has no hyphens, so the first two hyphens of an agent name always split off `agent` and WORD, and the rest is the TASK.
- Helpers use a dot, because TASK may contain hyphens and a hyphen suffix would read as part of it.
- `lead` and `note` are reserved and never a TASK.
- Only the task dir and its worktree dir carry a date. The window, branch and agent names exist only while the task is live, so a reused TASK name cannot collide with an old one.
- If an old `WORD/TASK` branch is still on the remote, pick a new TASK name.

## Panes

Each agent runs in its own pane. The pane title is the agent's name, and so is its name in agent-to-agent messaging (for example Portal in llm-agent), so tmux and the messages agree on who is who.

| Window | Panes |
|---|---|
| `lead` | `agent-WORD-lead` on the left, `agent-WORD-note` on the right |
| `task-TASK` | `agent-WORD-TASK` first, then any `.N` writers and the `.review` agent, plus an optional shell |
| manual | anything; agents never send work to a pane whose title is not an agent name |

## Set up ~/work once

Point `~/work` at a large shared disk, not a machine-local disk that disappears with the host.

```bash
ln -s <large shared disk>/$USER ~/work
mkdir -p ~/work/REPOS ~/work/WORKTREES
ln -s ~/workflow ~/work/REPOS/workflow
ln -s REPOS/workflow/agents ~/work/AGENTS
```

- `~/workflow` is a private repo, because STATUS.md and TASK.md name internal repos, MRs and people.
- `AGENTS/` holds only files to commit. Worktrees and build output never go in it, so the workflow repo stays small enough to live in the home dir.

## Clone a repo once

```bash
cd ~/work/REPOS
git-clone-worktree <clone url>
```

`git-clone-worktree` (in `~/bin`) makes a bare clone in `<repo>/.git`, fixes the fetch refspec so `origin/*` branches exist, and adds a worktree for the default branch. Every session that uses the repo adds its worktrees from this one clone.

## Start a session

```bash
word=shop
home_dir=~/work/AGENTS/$word
mkdir -p "$home_dir"
lead=$(tmux new-session -d -s "agent-$word" -n lead -c "$home_dir" -P -F '#{pane_id}')
note=$(tmux split-window -h -t "$lead" -c "$home_dir" -P -F '#{pane_id}')
tmux select-pane -t "$lead" -T "agent-$word-lead"
tmux select-pane -t "$note" -T "agent-$word-note"
```

Then start an agent in each pane, name it after the pane title, and write the session header in `STATUS.md`.

## Start a task

```bash
word=shop task=fix-login repo=webapp
dated=$(date +%F)-$task
task_dir=~/work/AGENTS/$word/$dated
worktree=~/work/WORKTREES/$word/$dated/$repo
mkdir -p "$task_dir" "$(dirname "$worktree")"
git -C ~/work/REPOS/$repo fetch origin
git -C ~/work/REPOS/$repo worktree add "$worktree" -b "$word/$task" origin/main
pane=$(tmux new-window -t "agent-$word" -n "task-$task" -c "$worktree" -P -F '#{pane_id}')
tmux select-pane -t "$pane" -T "agent-$word-$task"
```

- Base the branch on the repo's working branch, which is not always `main`.
- One task is one MR. If the work splits into several MRs, make several tasks.
- A task that touches several repos gets one `<repo>/` worktree per repo under the same `WORKTREES/WORD/YYYY-MM-DD-TASK/`, all on the same `WORD/TASK` branch name. Its window starts in that dir.
- Write the worktree path into TASK.md, so a restarted agent finds it.

## Finish a task

After the MR merges, the main writer writes `DONE.md`. Then the lead removes the worktree and closes the window.

```bash
git -C ~/work/REPOS/$repo worktree remove "$worktree"
rmdir "$(dirname "$worktree")"
tmux kill-window -t "agent-$word:task-$task"
```

- Never `rm -rf` a `WORKTREES/` dir that still holds a worktree, because git keeps a stale entry. If one is left, `git -C ~/work/REPOS/<repo> worktree prune` cleans it up.
- The task dir in `AGENTS/` stays, holding `TASK.md` and `DONE.md`.
- After moving `REPOS/` or `WORKTREES/`, run `git -C ~/work/REPOS/<repo> worktree repair <each worktree path>`.

## Files every session keeps

STATUS.md, in `AGENTS/WORD/`, is the lead's file. It starts with a session header and ends with the task table.

```markdown
# agent-shop status

Updated: 2026-11-16

| Field | Value |
|---|---|
| Repo | <link>, cloned at `REPOS/webapp` |
| Base branch | `main` |
| Tracking | <epic or ticket link> |
| Discussion | <thread link> |
| Reviewers | <names> |

| Task | Status | Next |
|---|---|---|
| [2026-11-16-fix-login](2026-11-16-fix-login/TASK.md) | MR open | Waiting on review |
```

TASK.md, in the task dir, is the main writer's file. It starts with a status header that a restarted agent reads first.

```markdown
# Task: fix-login

Status: MR open
Branch: `shop/fix-login`
Worktree: `~/work/WORKTREES/shop/2026-11-16-fix-login/webapp`
MR: <link>
Updated: 2026-11-16
Next: address review comments

## Goal

## Where it stopped
```

DONE.md, in the task dir, is written once when the MR merges. It holds what changed, the MR links, the decisions made, and the follow-ups. A task with a DONE.md is finished, so `ls ~/work/AGENTS/*/*/DONE.md` lists every finished task.

## Who does what

- The lead plans, starts task windows, tracks MRs, and tells Todd when an MR is ready for review. It keeps STATUS.md current.
- The note taker reads STATUS.md, TASK.md and DONE.md and turns them into Todd's notes. The lead does not relay every decision to it.
- The main writer owns its task's branch: it commits, pushes, opens the MR, keeps TASK.md current, and writes DONE.md.
- Extra writers edit different files in the same worktree and leave committing to the main writer.
- The reviewer reviews the main writer's changes before the MR goes to Todd.
- No agent merges, approves, or sets auto-merge. Todd merges, or a human reviewer does.

## Commit agent files

Every session shares one checkout of `~/workflow`.
A lead commits only its own `agents/WORD/`, at milestones.
If git reports another commit in progress, it waits and retries.
It runs `git pull --rebase` before every push.

## Restart after a reboot

1. For each dir in `~/work/AGENTS/`, recreate the `agent-WORD` session and its `lead` window as in "Start a session".
2. For each open task in STATUS.md, open a `task-TASK` window in the worktree its TASK.md names, and title the pane.
3. Start the agents. Each one reads its own file first: the lead and note taker read STATUS.md, and each main writer reads its TASK.md.

## Gotchas

- When an agent harness exports `UV_PROJECT_ENVIRONMENT` or `VIRTUAL_ENV` for its own venv, a bare `uv sync` in a worktree installs that repo into the harness's venv. Run uv in worktrees as `env -u UV_PROJECT_ENVIRONMENT -u VIRTUAL_ENV uv ...`.
- A sandboxed agent (for example one under bubblewrap) can have its starting directory mounted inside the sandbox. Renaming or moving that directory from outside then fails, or leaves the agent on the old copy. Quit the agents before moving their directories, and restart them in the new path.
- A session with no repo, such as one that edits dotfiles in place, still gets `AGENTS/WORD/` for its STATUS.md, but its task windows work in those directories directly and have no worktrees.
