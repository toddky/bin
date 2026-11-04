# References

Outside repos worth reading before building something similar. Read the linked files; do not install anything.
Links are pinned to the commit current on the date added, so they keep working if the repo moves on.

## Nutlope/hallmark

Agent skill for building web pages that don't look AI-generated. Added 2026-11-04, pinned to `de4999e`.
Look at it when building or reviewing a web page, writing a skill that checks its own output, or splitting checks into must-pass and advisory tiers.

| File | What to read it for |
|---|---|
| [SKILL.md](https://raw.githubusercontent.com/Nutlope/hallmark/de4999e0cd7a7a41df0b4e6903fa02fe9f1492a8/skills/hallmark/SKILL.md) | The skill itself: build steps, the three check tiers, and the list of AI design tells. 18 KB. |
| [references/direction.md](https://raw.githubusercontent.com/Nutlope/hallmark/de4999e0cd7a7a41df0b4e6903fa02fe9f1492a8/skills/hallmark/references/direction.md) | How it designs a page from a prompt alone, with no theme. 7.5 KB. |
| [scripts/sloplint.mjs](https://raw.githubusercontent.com/Nutlope/hallmark/de4999e0cd7a7a41df0b4e6903fa02fe9f1492a8/skills/hallmark/scripts/sloplint.mjs) | The linter that checks a rendered page for the tells. 230 KB, so grep it for one check rather than reading it whole. |

Ideas worth copying:
- Checks come in three tiers: a floor that never ships (contrast, focus, invented facts), defaults a build may overrule with a stated reason, and craft notes that never block.
- A reviewer with fresh context gets the last word, so the author's own summary is not trusted.
- A redesign records every link, field, and handler first, then fails if any went missing.
- Nothing is invented: it asks once for real photos, screenshots, and numbers instead of filling in placeholders.
