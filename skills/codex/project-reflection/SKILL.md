---
name: project-reflection
description: Records what finished work taught as short, revisable observations in .planning/reflections.md.
---

# project-reflection

Use at a checkpoint where something was actually learned: a substantial review
finished, a hard failure was resolved, or a handoff is being written. Codex has
no automatic trigger for this, so run it yourself at those moments. Do not run
it per turn, on routine work, or on your own earlier reflection edits. Ask for
no approval. If nothing material was learned, write nothing.

Read `.planning/reflections.md` first, then only the evidence a candidate needs
(the changed review or handoff, one commit, one test result). Keep what happened
(`Observed`) apart from why (`Explanation`); label the cause `unverified` unless
a reproduction, test, or direct inspection confirmed it. A passing command that
did not exercise the claim, or an agent saying "fixed", is not verification.

Write one entry per lesson:

```
## R-<slug>: <one-line claim>
- Status: tentative | supported | narrowed | retracted | superseded
- Scope: <when it applies, and what was not tested>
- Observed: <checkable facts>
- Explanation: <likely cause> (unverified | verified: <how>)
- Evidence: <paths, commit shas, tests, dates, tool/model versions if known>
- Cost: <optional; figures copied from .planning/metrics.jsonl, never estimated>
- History:
  - <YYYY-MM-DD> tentative: first seen
```

One occurrence is always `tentative`; `supported` needs two independent
incidents (copies of one incident in a log, handoff, and review are one).
Contradicting evidence sets `retracted` or `narrowed` and keeps the old text
with a dated History line. If the evidence is already cited, change nothing.
Leave anything that is not an `R-` entry untouched. Reference reusable snippets
by path, not by pasting code. Entries are advisory: never edit `AGENTS.md`,
skills, or policy because of one. Append one `reflection |` line to
`.planning/log.md` only when the file changed.
