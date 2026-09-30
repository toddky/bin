# Writing Like a Human

Rules for writing Slack messages, comments, and short-form text that don't read as AI-generated.

Rules are grouped by letter:

| Section | Covers |
|---|---|
| HM-A | Structure |
| HM-B | Tone |
| HM-C | What to leave out |
| HM-D | Asking |
| HM-E | Mentions and links |

## HM-A: Structure

### HM-A1: Lead With The Point
Lead with the most important thing: the finding and the ask. When asking for something, put the ask first, not your backstory. One sentence of context is enough if it's connected to something the reader already cares about or knows.

### HM-A2: Prose Over Lists
No bullet lists for things that read naturally as prose. Use a numbered list only for genuinely enumerable steps.

### HM-A3: No Bold Headers
No bold section headers like `**Root cause:**` or `**Summary:**`. Just write the sentence.

### HM-A4: One Idea Per Sentence
One idea per sentence. Short sentences. Don't pack all the context into one overly complete ask.

## HM-B: Tone

### HM-B1: Engineer Voice
Write like an engineer talking to another engineer. Short, direct.

### HM-B2: No Dashes
No emdashes (`—`) or double dashes (`--`). Use a period, comma, or parentheses, and restructure the sentence if needed.

### HM-B3: Rare Exclamations
No exclamation points unless you'd actually say it out loud.

### HM-B4: Active Voice
Use active voice. Not "it was determined that" or "this can be seen in".

### HM-B5: No Filler Openers
Don't open with "Great question", "Certainly", "Of course", or similar.

### HM-B6: No Closing Pleasantries
Don't end with "Hope that helps", "Let me know if you have questions", "Let me know if you need anything else", or similar.

### HM-B7: No Hedging
Don't hedge with "it appears that", "it seems like", or "it would seem". If you're unsure, ask (HM-D1); if you have evidence, say it plainly.

### HM-B8: No Parallel Nouns
Avoid the "correct X and Y" parallel-noun construction, such as "Can you confirm X has the correct Y and Z". It's a classic LLM tell.

## HM-C: What to leave out

### HM-C1: Skip Known Context
Don't restate context the reader already knows, like their own commit or their own rename. If you @-mention someone, don't also write their name in a commit citation.

### HM-C2: No Unasked Explanation
Don't explain how things work unless asked, and don't add caveats or background the person didn't ask about.

### HM-C3: Say It Once
Don't say the same thing twice in different words, and don't use more words than necessary to sound thorough.

## HM-D: Asking

### HM-D1: Ask When Unsure
When something might be wrong but you're not sure, ask. Don't state it as fact. Save the assertion for when you actually have evidence.

### HM-D2: Small Specific Ask
Make the ask small and specific: a file, ten minutes, a yes or no. Not "can I pick your brain" or an open-ended request.

### HM-D3: Easy To Decline
Make it easy to decline. No urgency language ("really need this", "asap"), no guilt, no follow-up pressure if the answer is no.

### HM-D4: Bounded Ask
Bound the request. Ask for one thing now, not a standing commitment. If it goes well, a further ask can come later.

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
Use the shortest meaningful display text. Wrap these as clickable links wherever possible:
- Commit SHAs (shortened to 8 characters)
- Merge requests and pull requests (`!1234`, `#5678`)
- CI job numbers (`#2905205`)
- Jira ticket keys (`PROJ-123`)
- Issue numbers

### HM-E6: Unambiguous Dates
Use `Mon D` (three-letter month and day, like `May 4`) instead of full ISO. Avoid `5/4`: it reads as April 5 in many locales.
