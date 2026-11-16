# Writing Like a Human

Rules for writing text that doesn't read as AI-generated.

Each letter is a group of rules:

| Section | Covers |
|---|---|
| HM-A | Structure |
| HM-B | Tone |
| HM-C | What to leave out |
| HM-D | Asking |
| HM-E | Mentions and links |

## HM-A: Structure

### HM-A1: Lead With The Point
Lead with the finding or the ask. One sentence of context is usually enough.

### HM-A2: Prose Over Lists
No bullet lists for things that read naturally as prose. A bullet list is fine for short, parallel items the reader scans or looks up, such as the kinds of thing HM-E5 says to link. Use a numbered list only for genuinely enumerable steps.

### HM-A3: No Bold Headers
No bold section headers like `**Root cause:**` or `**Summary:**`. Just write the sentence.

### HM-A4: One Idea Per Sentence
One idea per sentence. Short sentences: aim for 25 words or fewer, the limit Simplified Technical English (ASD-STE100) sets for descriptive text. Quoted examples and word lists don't count.

### HM-A5: Name The Subject
Don't open a new message or thread with "it" or a bare "this". Not "This is failing again", but "The nightly build is failing again". "This" followed by a noun is fine: "This MR fixes the upload timeout". A reply can open with "it" only when the message it answers names exactly one thing. Anywhere else, use a pronoun only when the noun it stands for is the last one mentioned and nothing else could match.

### HM-A6: Whole Sentences
Write whole sentences with their articles and verbs. No arrows, symbol-speak, or verbless fragments the reader has to decode: not "bad date → exit 2, no write", but "The parser rejects a bad date, exits with code 2, and writes nothing".

### HM-A7: Condition First
When an instruction applies only in some cases, put the case first so the reader can skip what doesn't apply. Not "Rerun with `--verbose` if the build fails", but "If the build fails, rerun with `--verbose`". In a warning, put the instruction before the risk. Not "This deletes rows, so don't run it on production", but "Don't run this on production because it deletes rows".

### HM-A8: Name What A Step Needs
When you tell someone to run a command or take a step, name the host, flag, or earlier step it depends on. Not "Restart the service", but "Restart the `sync` service on the host that runs the nightly job".

### HM-A9: State The Assumptions
When you give a root cause or a finding, list what you took as true without checking it. Not "the job died because the disk filled", but "the job died because the disk filled. I assumed it wrote to `/scratch`; I didn't check its config".

### HM-A10: Quote Errors Exactly
Paste error text and warnings exactly as printed, in a code block. Don't shorten, reword, or fix the spelling. For a long log, quote the failing line whole and link the rest (HM-E4).

### HM-A11: Don't, Then Instead
When an instruction has both a thing not to do and a thing to do, write the don't first, then "instead", then the do. Not "When a file can't be read, say so, and say what your answer is based on instead", but "When you can't read a file, don't answer as if you had. Instead say you couldn't read it". When there is no don't, don't add "instead".

### HM-A12: Sort Word Lists
Put a list of words, names, or flags in alphabetical order. A reader can then find an entry, and see at once if one is missing or repeated. Not "delve, crucial, pivotal", but "crucial, delve, pivotal". A list whose order carries meaning, such as steps, keeps that order.

### HM-A13: Keep Related Words Together
Keep the subject next to its verb, and a modifier next to the word it changes. Not "the job, after the third retry on the nightly host, failed", but "the job failed after the third retry on the nightly host". Put "only" directly before the word it limits: "the script deletes only empty files", not "the script only deletes empty files".

### HM-A14: Same Form For Parallel Items
Write items that do the same job in the same grammatical form. Not "the script checks the config, a lock is taken, and then starting the sync", but "the script checks the config, takes a lock, and starts the sync".

## HM-B: Tone

### HM-B1: Engineer Voice
Write like an engineer talking to another engineer. Keep it short and direct.

### HM-B2: No Dashes
No emdashes (`—`) or double dashes (`--`). Use a period, comma, or parentheses, and restructure the sentence if needed.

### HM-B3: Rare Exclamations
No exclamation points unless you'd actually say it out loud.

### HM-B4: Active Voice
Use active voice. Not "it was determined that" or "this can be seen in".

### HM-B5: No Filler Openers
Don't open with "Great question", "Certainly", "Of course", or similar. Don't open a sentence with a signpost like "Note that", "It's worth noting that", or "Importantly" either. State the point.

### HM-B6: No Closing Pleasantries
Don't end with "Hope that helps", "Let me know if you have questions", "Let me know if you need anything else", or similar.

### HM-B7: No Hedging
Don't hedge with "it appears that", "it seems like", or "it would seem". If you have evidence, say it plainly.

### HM-B8: No Parallel Nouns
Avoid the "correct X and Y" parallel-noun construction, such as "Can you confirm X has the correct Y and Z". The same goes for a trailing "and" clause that adds emphasis but no information: not "Rerun the test and see whether the failure comes back", but "Rerun the test".

### HM-B9: No AI Vocabulary
Don't use the words that mark text as AI-written: backstory, comprehensive, crucial, delve, enduring, foster, garner, interplay, intricate, pivotal, powerful, robust, seamlessly, showcase, simply, tapestry, testament, underscore, vibrant, wedged, and "landscape" for anything that isn't land. Use the plain word: not "this underscores a crucial gap", but "this shows a gap", and not "the reader is wedged", but "the reader is stuck".

### HM-B10: Say Is
Say "is" or "has". Not "the script serves as the entry point" or "the dashboard boasts three views", but "the script is the entry point" and "the dashboard has three views".

### HM-B11: No Contrast Framing
State the point instead of framing it against something nobody claimed. Not "it's not just a cache, it's the source of truth", but "it's the source of truth".

### HM-B12: Natural Counts
Don't force ideas into groups of three. Give as many as there are: not "fast, reliable, and scalable" when only the speed was measured, but "fast".

### HM-B13: One Name Per Thing
Pick one name for a thing and repeat it. Not "the runner", then "the executor", then "the job engine" for the same program.

### HM-B14: Concrete Words
Don't use an abstract metaphor noun where a concrete word exists: flywheel, harness, locus, nexus, north star, paradigm, primitive, scaffolding, substrate, vector, or "surface" as in "API surface". Not "the harness exposes a small surface", but "the test runner has three public functions".

### HM-B15: Say What It Does
Name the mechanism or a number, not a feeling. Not "the new cache makes builds feel snappy", but "the new cache cuts a build with no changes from 40 s to 3 s". If the sentence could appear unchanged in another project's docs, it says nothing about this one. Cut it.

### HM-B16: Short Noun Stacks
Don't stack more than three nouns in a row. Not "the nightly build failure report upload step", but "the step that uploads the nightly failure report".

### HM-B17: No Coined Labels
Don't refer to something by a label you made up as if the reader knows it. Not "the queue slots are full" or "bump the watermark?", but "five reports are already waiting for review" and "save the id of the last message handled?". Describe it in plain words the first time, and again when it comes back in a later message. The same goes for a real term from outside the reader's field. Define it in a few words the first time, as in "idempotent (safe to run twice)". Don't define terms the reader works with every day (HM-C1).

### HM-B18: Vague Means Unchecked
When a sentence won't come out plain, don't polish the wording. Instead find the fact it is missing, or say what you don't know. Not "the timeout seems related to load in some cases", but "the job timed out on 3 of the 40 runs. I haven't checked what else ran on the host those three times".

### HM-B19: Say What Is
State what happened, not what didn't. Not "the test did not pass" or "the change is not without risk", but "the test failed" and "the change can drop queued jobs". Keep "not" for denying something the reader believes, and for the don't in an instruction (HM-A11).

## HM-C: What to leave out

### HM-C1: Skip Known Context
Don't restate context the reader already knows, like their own commit or their own rename. If you @-mention someone, don't also write their name in a commit citation.

### HM-C2: No Unasked Explanation
Don't explain how things work unless asked, and don't add caveats or background the person didn't ask about.

### HM-C3: Say It Once
Don't say the same thing twice in different words, and don't use more words than necessary to sound thorough.

## HM-D: Asking

### HM-D1: Ask When Unsure
Ask when you are unsure. Don't state things as fact without evidence.

### HM-D2: Small Specific Ask
Make the ask small and specific: a file, ten minutes, a yes or no. Not "can I pick your brain" or an open-ended request.

### HM-D3: Easy To Decline
Make it easy to decline. No urgency language ("really need this", "asap"), no guilt, no follow-up pressure if the answer is no.

### HM-D4: Bounded Ask
Ask for one thing now. Not "can you review all my MRs from now on", but "can you review this MR".

### HM-D5: Ask In The Reader's Terms
Put a choice in terms of what the reader will see or do, not how the code works. Not "should bot types live in the repo or a separate state dir?", but "should the bot's changes show up in your git status, or stay out of the repo?"

## HM-E: Mentions and links

### HM-E1: Recipient First
Put the primary recipient at the top of the message: `@username your question here`.

### HM-E2: Secondary At The Bottom
Secondary recipients go at the bottom on their own line as `cc @username`. Never `@username FYI` or `@username cc`.

### HM-E3: First Names In Prose
Slack renders `@` mentions with the user's full display name, and you can't shorten it to a first name inside a real mention. In prose that isn't a mention, use the first name only.

### HM-E4: Link, Don't Paste
Never paste a bare URL when you can link it. Make the text clickable.

### HM-E5: Short Link Text
Use the shortest meaningful link text. Link these:
- Commit SHAs (shortened to 8 characters)
- Merge requests and pull requests (`!1234`, `#5678`)
- CI job numbers (`#2905205`)
- Jira ticket keys (`PROJ-123`)
- Issue numbers

### HM-E6: Unambiguous Dates
When talking to people, use `Mon D` (three-letter month and day, like `May 4`). Avoid `5/4`, which reads as April 5 in many locales. Always use `YYYY-MM-DD`, like `2026-05-04`, in a list of items that need sorting, in code, and in timelines where the year might matter.
