# Writing Documents

Rules for long-form writing: notes, published pages, design docs, and anything a reader lands on cold, without the conversation that produced it.

`HUMAN.md` applies here too, and its tone rules hold in a document just as in a message. Two of its structure rules flip. A message leads with the finding (HM-A1) because its reader already knows the subject; a document's reader arrives cold, so it names the subject first (DOC-B1) and reaches the point within the first screen (DOC-B3). A message avoids bullet lists (HM-A2), while a document ends with a list of links (DOC-B9).

| Section | Covers |
|---|---|
| DOC-A | Titles and headings |
| DOC-B | Structure |
| DOC-C | Evidence |

## DOC-A: Titles and Headings

### DOC-A1: Name First
Lead a title with the name of the thing, then a short gloss after a colon. The gloss is a handle, not a definition, so stop at four or five words. Not "my-chat: a chat server where automated accounts are ordinary users", but "my-chat: Slack for bots".

### DOC-A2: Borrow A Familiar Thing
Describe something new by naming the known thing it resembles. A reader who has used the familiar thing now has a working model of yours and can correct it as they read. An accurate sentence that names nothing familiar leaves them with no starting point.

### DOC-A3: No Filenames In Headings
A heading names its subject, not the file or command that produced it. Repeating the same filename across every heading in a series adds width and tells the reader nothing, since the thing that varies is the subject. Not "Model A: sample-input.sh", but "Model A".

### DOC-A4: Make The Key Word Loud
When one word in a heading is the only thing distinguishing it from its neighbors, give that word weight with bold or color. Readers scan columns and section lists rather than reading them, and the distinguishing word is what they are scanning for.

## DOC-B: Structure

A document runs in three parts, in this order. Each rule below is tagged with the part it belongs to.

1. Intro: what it is (DOC-B1), why it is worth reading (DOC-B2), and the payoff (DOC-B3)
2. Body: the entries, one at a time (DOC-B4 to DOC-B6)
3. Ending: how to try it (DOC-B7), the argument (DOC-B8), and the links (DOC-B9)

### DOC-B1: Say What It Is First (Intro)
Open with what the thing is in one or two sentences, before anything else. A reader who arrives from a link has none of the context you have, and cannot weigh anything that follows until they know what it is about. Do not open with history, motivation, or the problem that led to the work.

### DOC-B2: Then Say Why It Is Worth Reading (Intro)
The second paragraph tells the reader what they get from the rest of the page. Make it a concrete claim about the subject, not a description of the document. Not "This page collects examples of the bot's answers", but "In each of these the bot did not know the answer, so it went and looked."

### DOC-B3: Show The Payoff Early (Intro)
Put the thing that delivers the value directly after the opening, so the reader gets something useful on the first screen. What that is depends on the document: for a command-line tool it is the commands a user runs and their output, which shows how little it takes; for a system it is the diagram; for a collection it is the strongest entry. Not a README that opens with installation and design notes, but one whose first code block is the command people will actually type.

### DOC-B4: Same Shape Every Entry (Body)
Every entry in a repeated series carries the same parts in the same order. Once a reader learns the shape from the first entry they can skip to the part they want in all the rest. An example that can't fill every part should be replaced, not kept with a caveat explaining the gap.

### DOC-B5: Mark The Roles (Body)
When a document quotes a conversation or a sequence of actors, give each role a consistent visual marker and use it everywhere. The marker is what lets a reader skim to the answer, or to the question, without reading the surrounding prose.

### DOC-B6: Divide Sections Visibly (Body)
Published documents use a horizontal rule between major sections. A document is scrolled and skimmed, and the divider is what tells the eye a new entry has started.

### DOC-B7: Show How To Try It (Ending)
When the payoff was something other than a command, such as a diagram or a set of examples, and the reader can still run the thing, give the one command that starts it right after the body. Pick the command that shows the most with the least setup, and say in a sentence what it does. A tool's README skips this step, because its commands already came first (see DOC-B3).

### DOC-B8: End On The Argument (Ending)
Finish with the section that makes the point, not a summary of what was already read. If the document exists to argue something, the last section before the links is where the argument goes. A recap at the end says the reader was not trusted to follow the body.

### DOC-B9: Links Last (Ending)
Put reference links in one final section, each labeled by kind, such as `Notes:` or `Repository:`. Links in the body point at the evidence for a specific claim. Links for further reading go at the bottom, where a reader who finished the page looks for them.

## DOC-C: Evidence

### DOC-C1: Quote, Do Not Paraphrase
Use the exact words of whoever said it, in a block quote. A paraphrase hides what was actually said and reads as your claim rather than theirs. Trim with an ellipsis rather than rewording.

### DOC-C2: Link The Exact Thing
Link to the specific message, line, or commit, not to the thread, file, or branch that contains it. A reader who has to search inside your link for the thing you meant will stop following links. Not "the discussion is in the review thread", but a link on "the reviewer's objection" that lands on that one comment.

### DOC-C3: Name What Was Looked Up
When a conclusion came from a query, say which query and what it returned. The reader can then run the same check instead of taking your word for it. Not "worked out the cause", but "checked the job record and found it was killed for exceeding its memory limit".

### DOC-C4: Say Where It Came From
When evidence is rebuilt from a result rather than taken from a record, say so once, near the top. A list pieced together from what a reply cites is weaker than one copied from a log, and a reader who assumes the stronger one will be misled. One sentence is enough.
