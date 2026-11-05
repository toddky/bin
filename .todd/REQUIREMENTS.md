# Writing Requirements

Rules for gathering and writing a requirements document. A requirements document is the spec a piece of work is built and accepted against, such as a service, a tool, or a library.

`DOCUMENT.md` and `HUMAN.md` apply too. A requirements document differs from other documents in one way: a reader uses it as a checklist, not as a story. Every statement must be findable by its ID, testable on its own, and traceable to a reason and a source.

| Section | Covers |
|---|---|
| REQ-A | Gathering |
| REQ-B | Document structure |
| REQ-C | Writing statements (EARS) |
| REQ-D | Groups, IDs, and priorities |
| REQ-E | Completeness checks |
| REQ-F | Not supported |
| REQ-G | Gaps, assumptions, and decisions |
| REQ-H | Revising and publishing |

## REQ-A: Gathering

Gathering is most of the work. A requirement written from a guess costs more later than a gap written down now.

### REQ-A1: Start From The Concrete Case
Before writing any requirement, name the real case they must handle. It can be the failure that started the work, the test that must pass, or the user's own example. Check the finished document against that case (REQ-E4). A spec that covers the category but not the case misses the point.

### REQ-A2: Facts Before Requirements
Collect the facts the requirements depend on into a numbered table (`F-1`, `F-2`, ...). Give each fact its evidence: a file and line, a command and its output, or a document and page. Requirements cite facts by ID. A requirement with no fact behind it is an opinion, and a reviewer cannot check it.

### REQ-A3: Mark Every Guess
Tag anything unverified as **GUESS** where it appears, and list it again as a knowledge gap (REQ-G1). A guess that reads like a fact is the most expensive line in a spec.

### REQ-A4: Primary Sources Win
Check each fact against the primary source: the code, the config, the logs, the data. Guides, slides, and summaries are secondary. When two sources disagree, record both and the disagreement, and settle it by measurement rather than by picking one.

### REQ-A5: Record What The Old System Does
When a working implementation already exists, record what it actually does for a set of inputs and require the new one to match. Documentation describes intent; a recording shows behavior, including the parts nobody wrote down.

### REQ-A6: Read The Bugs That Got Through
Read the bugs in the same area that reached users despite testing. Each one is a requirement the old process missed: the new work must catch it, or the spec must say why it cannot. A check that accepts every input would have caught none of them.

### REQ-A7: Find Prior Attempts And Owners
Search for earlier efforts on the same problem, why they stalled, and who owns each piece. A stalled attempt names a risk; an owner answers a gap in one message.

### REQ-A8: One Owner Per Research Scope
Split the research into scopes that do not overlap, such as the user-facing flow, the interfaces, the platform it runs on, third-party documentation, and history. Give each scope one owner, person or agent. Ask every owner for the same three things: facts with evidence, the requirements they imply, and the gaps they could not close.

## REQ-B: Document Structure

Sections run in this order:

1. Title, then status, owner, and reviewers
2. Requirements at a glance: a table of areas with statement counts and the priority totals
3. Priority definitions and an ID legend
4. Plain-language summary: the problem, why it hurts, what gets built, and any term the rest depends on
5. Goals, non-goals, and scope
6. The design the requirements assume
7. Facts (REQ-A2)
8. Requirements (REQ-C, REQ-D)
9. Not supported (REQ-F)
10. Assumptions, decisions, and questions (REQ-G2)
11. Knowledge gaps (REQ-G1)
12. Phases and gates (REQ-G3)
13. Sources

### REQ-B1: Lead With The Table
The at-a-glance table is the payoff (DOC-B3). A reviewer sees the size and shape of the spec before reading any statement, and can jump to the area they own.

### REQ-B2: Legend Near The Top
Define every ID prefix in one table near the top. The usual set: `G` goal, `F` fact, `R-AREA-n` requirement group, `R-AREA-nx` statement, `N` not supported, `A` assumption, `D` decision, `Q` question, and `K` knowledge gap. A reader who meets "K-17" with no legend has to search for it.

### REQ-B3: Non-Goals Are Requirements Too
List what the work will not do as explicitly as what it will. Unstated non-goals come back as review comments and scope creep.

### REQ-B4: Define The Words The Spec Leans On
When the requirements depend on a term such as "reference run", "cold start", or "the platform", define it in the summary. One undefined word can make a whole area untestable.

### REQ-B5: Name The Systems
List every system that statements are about, with one line each, such as the service, its build, a code generator, and the deploy pipeline. Each statement then names which one owes the behavior (REQ-C3).

### REQ-B6: Scale Down For Small Work
A spec for a small change keeps four parts: the plain-language summary, the requirements, what is not supported, and the knowledge gaps. Add the other sections only when the work has facts to cite, decisions to record, or phases to gate. A five-statement change wrapped in thirteen sections hides its five statements.

## REQ-C: Writing Statements (EARS)

Write each requirement as one statement in EARS (Easy Approach to Requirements Syntax) form:

| Form | Template | Use |
|---|---|---|
| Ubiquitous | The `<system>` shall `<response>`. | Always true |
| Event-driven | WHEN `<trigger>`, the `<system>` shall `<response>`. | Reaction to an event |
| State-driven | WHILE `<state>`, the `<system>` shall `<response>`. | True while in a state |
| Unwanted behavior | IF `<condition>`, THEN the `<system>` shall `<response>`. | Faults, violations, misuse |
| Optional feature | WHERE `<feature is enabled>`, the `<system>` shall `<response>`. | Configurable behavior |
| Complex | WHERE ... WHILE ... WHEN ... | Several conditions at once |

### REQ-C1: One Obligation Per Statement
A statement holds one thing a test can pass or fail. If it has "and" between two behaviors that could be tested separately, split it. Not "the scheduler shall retry a failed job and alert after five failures", but one statement for the retry and one for the alert.

### REQ-C2: Shall, And Nothing Softer
Use "shall" for every obligation. Never write "may", "should", "as needed", "as appropriate", "etc.", or "and so on": each one leaves the reader to decide what is required. If a behavior is optional, make it a WHERE statement (REQ-C6).

### REQ-C3: Name The Subject
Start the response clause with the system that owes the behavior, from the list in REQ-B5. Not "errors shall be logged", but "the service shall log each rejected request with its client ID".

### REQ-C4: Make It Measurable
Use real names and numbers: the endpoint, the field, the limit, the unit. A configurable value names its default and where the default came from. Not "the service shall respond quickly", but "the service shall return a response within 200 ms of receiving a request".

### REQ-C5: Condition First
The EARS keyword and its condition come before "shall", as in HM-A7. A reader scanning for the case they care about reads only the start of each line.

### REQ-C6: Optional Behavior Gets WHERE And A Default
Every WHERE statement names the option and its default state. A feature with no stated default gets a different default in every deployment.

### REQ-C7: Faults Say What Gets Reported
An IF statement says what the system does and how it reports it: the error code, the counter, the log line, the alert. "Shall handle the error" is not testable.

### REQ-C8: What, And How Only With A Reason
State what the system must do, not how to build it. Write a how only when it is itself a constraint, and give the reason in the group's Why. An example is "generated from the schema file, so the next service reuses the generator".

## REQ-D: Groups, IDs, And Priorities

### REQ-D1: Group Shape
Put related statements under one group, in this shape every time (DOC-B4):

```markdown
**R-QUEUE-2: Job retry (P0).** *Why:* a failed job that is never retried blocks the jobs queued behind it. *Source:* F-4, F-7.
- **R-QUEUE-2a.** WHEN a job fails with a transient error, the scheduler shall requeue it after 30 seconds.
- **R-QUEUE-2b.** IF a job has failed 5 times, THEN the scheduler shall move it to the dead-letter queue.
- **R-QUEUE-2c.** WHEN the scheduler moves a job to the dead-letter queue, the scheduler shall record the job's last error with it.
```

### REQ-D2: Stable IDs
An ID is `R-<AREA>-<n>` for a group and `R-<AREA>-<n><letter>` for a statement. Never renumber: reviews, tests, and tickets cite the IDs. A new statement takes the next letter, a new group the next number, and a deleted one leaves its number unused.

### REQ-D3: Priorities
Use three levels and define them in the document. P0 means the work is meaningless without it, P1 means it is needed to be useful, and P2 means later. Set the priority on the group; a statement that differs says so in its own label.

### REQ-D4: Every Group Has A Why
Give each group one sentence on why it exists, preferably tied to a fact or a bug that got through. A requirement nobody can justify gets cut, not kept.

### REQ-D5: Every Group Has A Source
Point each group at the facts (F-n), gaps (K-n), or evidence behind it. Reviewers check the source, not the author.

## REQ-E: Completeness Checks

### REQ-E1: Ask What Happens Otherwise
For each WHEN statement, write the IF statement for the trigger arriving at the wrong time, twice, or never. Most missing requirements are the "otherwise" of one that exists.

### REQ-E2: Walk The Standard Faults
Check every area against this list:

- A restart in the middle of an operation
- Input that matches nothing known
- A value outside the valid range
- A full queue or buffer
- A response that never arrives
- A repeated request
- A request before the system is ready
- A version mismatch between the system and the data it was built from

### REQ-E3: Every Statement Maps To A Test
Keep a table from statement ID to the test, check, or review item that proves it. Every rule-style statement also needs a negative test that breaks the rule and checks that the violation is reported.

### REQ-E4: Run The Concrete Case
Walk the case from REQ-A1 through the finished requirements, step by step. Every step must be covered by a statement, a non-goal, or a gap.

### REQ-E5: Devil's Advocate Before Review
Run `DEVILS_ADVOCATE.md` on the draft and fold in its Change items before sending it to reviewers. The cheapest objection is the one you raised yourself.

## REQ-F: Not Supported

### REQ-F1: List It, Say Why, Say What Happens Instead
Write the things the system will not do as a table. After the ID, give three columns: what is not supported, why not, and what the system does instead. "Why not" stops the same request coming back in every review, and "instead" tells the reader the behavior is defined rather than forgotten.

## REQ-G: Gaps, Assumptions, And Decisions

### REQ-G1: Knowledge Gaps Carry Their Own Plan
Give each unknown an ID (`K-n`) and say why it matters. Say how to settle it (a command, a run, a person to ask) and which requirements it blocks. When that table runs past four text-heavy columns, split it into an overview (ID, gap, blocks) and a detail table (ID, why, how to settle).

### REQ-G2: Assumptions, Decisions, And Questions
Keep three short lists. Assumptions (`A-n`) are what the spec takes as true until someone confirms it. Decisions (`D-n`) are already made, each with its reason. Questions (`Q-n`) need an answer from a named person or group, each with a recommended answer so the reply can be one word.

### REQ-G3: The First Gate Settles The Killers
Order the phases so the first gate answers the gaps that could end the project. Typical ones are capacity, licensing, and whether the reference behavior can be recorded at all. Each phase names its exit gate and the gaps it settles.

## REQ-H: Revising And Publishing

### REQ-H1: Counts Track The Body
The at-a-glance table, the priority totals, and any "N statements" in the text are part of the body (DOC-D1). Regenerate them after every edit rather than editing them by hand.

### REQ-H2: No Dangling References
Every requirement ID the document mentions must be defined in it. Check after each edit:

```bash
doc=REQUIREMENTS.md
comm -23 \
  <(grep -o -E 'R-[A-Z]+-[0-9]+[a-z]?' "$doc" | sort -u) \
  <(grep -o -E '^\*\*R-[A-Z]+-[0-9]+|^- \*\*R-[A-Z]+-[0-9]+[a-z]' "$doc" | sed 's/^[-* ]*//' | sort -u)
```

The command prints each ID that is mentioned but never defined, and nothing when every reference is defined.

### REQ-H3: Edit Markers Stay In The Draft
Markers such as "(new)" or "changed since v2" help reviewers of a draft. Strip them from any published copy, whose readers never saw the earlier version.

### REQ-H4: One Source For Rules That Become Code
When statements will be compiled into checks or tests, keep the statement text as the input to the generator. Two copies of a rule, one in the spec and one in the code, drift apart within a release.
