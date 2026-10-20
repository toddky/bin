# Writing Documents

Rules for long-form writing: notes, published pages, design docs, and anything a reader lands on cold, without the conversation that produced it.

`HUMAN.md` applies here too, and its tone rules hold in a document just as in a message. Two of its structure rules flip. A message leads with the finding (HM-A1) because its reader already knows the subject; a document's reader arrives cold, so it names the subject first (DOC-B1) and reaches the point within the first screen (DOC-B3). A message avoids bullet lists (HM-A2), while a document ends with a list of links (DOC-B9).

| Section | Covers |
|---|---|
| DOC-A | Titles and headings |
| DOC-B | Structure |
| DOC-C | Evidence |
| DOC-D | Revising |
| DOC-E | Diagrams |

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

## DOC-D: Revising

### DOC-D1: Counts Track The Body
Any sentence that counts, orders, or sums up the entries is part of the body. Changing an entry means fixing every "five of the six", "the first of these", and "all but one" that described the old set. These lines are the easiest part of a document to leave stale, and a wrong one makes the reader doubt the rest.

## DOC-E: Diagrams

A diagram here means a block diagram: a map of the parts of a system and what crosses between them.

### DOC-E1: One Diagram Over Many Links
When a set of links exists to show how the parts of a system fit together, draw a diagram instead. The reader gets the shape of the system without opening anything. The links can still go on the diagram's own page.

### DOC-E2: A Map, Not A Flowchart
Lay components out by where they sit, not by the order they run. If the diagram reads top to bottom as step 1, step 2, step 3, it is a flowchart, so redo it. The one exception is a component that runs inside another's loop, which is drawn inside that box rather than as the next one down.

### DOC-E3: Lanes By Kind
Group components into labeled lanes by what they are, such as the processes, the wrappers around them, and the external systems they call. Put the owner of the data where its ownership shows, usually the middle, rather than as one box among peers. Pair related boxes on the same row, so a wrapper sits beside the thing it runs.

### DOC-E4: Start Where The Reader Starts
Put whatever a person touches, such as a browser or the command that starts everything, in the leftmost lane so the diagram reads left to right. Not a launcher in the right lane with an arrow reaching back across the whole diagram, but a launcher on the left beside the browser. A long arrow running against the flow means a box is in the wrong lane.

### DOC-E5: Shared State Gets A Band
Files, caches, databases, and config go in their own band along the bottom, not in a lane with the processes. They are resources every component touches, never steps in a sequence.

### DOC-E6: Label Every Edge
Label each edge with what crosses it, not with a step number. Not "1", "2", "then", but "events", "one session per message", "page and API calls". An unlabeled arrow says two boxes are related and nothing about how.

### DOC-E7: Put The Contract On The Box
When a component has a real contract, such as its inputs, exit codes, or timeouts, write it on the box. That is the part of a diagram worth more than the prose around it.

### DOC-E8: Show How Many
When one box stands for several running processes, say so on the box and name each one. A single box reads as a single process, which hides the most important fact about a launcher that starts three. Not one box labeled "bot", but one box with "lead", "worker", and "reviewer" marked inside it.

### DOC-E9: Edge Style, Direction, And A Caption
Use solid edges for calls between processes and dashed edges for reads and writes on disk. Point each arrow from the side that starts the call rather than putting a head on both ends, since most calls get a reply and two heads hide who started it. Say both in a caption under the diagram, or the reader has to guess.

### DOC-E10: Crossings Are Fine
Leave an edge crossing in place. Bending the layout to avoid one costs more clarity than the crossing does.

### DOC-E11: Outline, Do Not Fill
Draw boxes as outlines with a colored border, one color per kind of component, and leave the inside the background color. Bright solid fills fight the text for attention. Draw a group as a dashed border with no fill.
