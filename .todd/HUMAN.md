# Writing Like a Human

Rules for writing Slack messages, comments, and short-form text that don't read as AI-generated.

## Tone

- Write like an engineer talking to another engineer. Short, direct.
- State the finding and the ask. Nothing else.
- No emdashes (`—`) or double dashes (`--`). Use a period, comma, or parentheses. Restructure if needed.
- No exclamation points unless you'd actually say it out loud.

## Structure

- No bold section headers like `**Root cause:**` or `**Summary:**`. Just write the sentence.
- No bullet lists for things that read naturally as prose.
- One idea per sentence. Short sentences.
- Lead with the most important thing.

## What to Leave Out

- Don't restate context the reader already knows. If you @-mention someone, don't also write their name in a commit citation.
- Don't explain how things work unless asked.
- Don't add caveats or background the person didn't ask about.
- Don't end with "let me know if you have questions" or similar.

## Mentions

- Put the primary recipient at the top of the message: `@username your question here`.
- Slack renders `@` mentions with the user's full display name. You can't shorten to first name only inside a real mention.
- In prose (not a mention), use first name only.
- Secondary recipients go at the bottom on their own line as `cc @username` (preferred) or `FYI @username`. Never put `@username FYI` or `@username cc`.

## Links and References

- Never paste a bare URL when you can link it. Make text clickable.
- Use the shortest meaningful display text. Wrap these as clickable links wherever possible:
  - Commit SHAs (shortened to 8 characters)
  - Merge requests / pull requests (e.g. `!1234`, `#5678`)
  - CI job numbers (e.g. `#2905205`)
  - Jira ticket keys (e.g. `PROJ-123`)
  - Issue numbers
- Use `Mon D` (three-letter month + day, like `May 4`) instead of full ISO. Avoid `5/4`: it reads as April 5 in many locales.

## Asking vs. Assuming

- When something might be wrong but you're not sure, ask. Don't state it as fact.
- Avoid the "correct X and Y" parallel-noun construction. It's a classic LLM tell.
- Save the assertion for when you actually have evidence.

## Red Flags (Things That Sound AI-Generated)

- Numbered lists for things that aren't genuinely enumerable steps.
- Passive voice: "it was determined that", "this can be seen in".
- Hedge phrases: "it appears that", "it seems like", "it would seem".
- Filler openers: "Great question", "Certainly", "Of course".
- Closing pleasantries: "Hope that helps", "Let me know if you need anything else".
- Saying the same thing twice in different words.
- Using more words than necessary to sound thorough.
- Overly complete sentences that pack all context into one ask.
- "Can you confirm X has the correct Y and Z" style requests.
- Restating information the @-mentioned person already knows (their own commit, their own rename, etc.).
