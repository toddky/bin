# Writing Like a Human

Rules for writing Slack messages, comments, and short-form text that don't read as AI-generated.

## Tone

- Write like an engineer talking to another engineer. Short, direct.
- State the finding and the ask. Nothing else.
- No emdashes (`--` or `—`). Use a period or restructure the sentence.
- No exclamation points unless you'd actually say it out loud.

## Structure

- No bold section headers like `**Root cause:**` or `**Summary:**`. Just write the sentence.
- No bullet lists for things that read naturally as prose.
- One idea per sentence. Short sentences.
- Lead with the most important thing.

## What to Leave Out

- Don't restate context the reader already knows.
- Don't explain how things work unless asked.
- Don't add caveats or background the person didn't ask about.
- Don't end with "let me know if you have questions" or similar.

## Mentions

- Put the primary recipient at the top of the message: `@username your question here`.
- FYI recipients go at the bottom on their own line: `FYI @username`.
- Never put `@username FYI`. Always `FYI @username`.

## Links

- Make text clickable instead of pasting raw URLs.
- Use the shortest meaningful display text: `!1234`, `#2905205`, commit SHA, etc.
- Never paste a bare URL when you can link it.

## Asking vs. Assuming

- When something might be wrong but you're not sure, ask. Don't state it as fact.
- "Can you confirm X?" instead of "X is likely broken."
- Save the assertion for when you actually have evidence.

## Red Flags (Things That Sound AI-Generated)

- Numbered lists for things that aren't genuinely enumerable steps.
- Passive voice: "it was determined that", "this can be seen in".
- Hedge phrases: "it appears that", "it seems like", "it would seem".
- Filler openers: "Great question", "Certainly", "Of course".
- Closing pleasantries: "Hope that helps", "Let me know if you need anything else".
- Saying the same thing twice in different words.
- Using more words than necessary to sound thorough.
