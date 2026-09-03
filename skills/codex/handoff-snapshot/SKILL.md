---
name: handoff-snapshot
description: Records durable j-stack state so another tool or session can resume work.
---

# handoff-snapshot

Use before a planned tool switch, when pausing, when context is filling, or
when the user asks to save state. Verify `.planning/` exists first.

Write `.planning/handoffs/<timestamp>-snapshot.md` using the
`j-stack.handoff.blackboard.v1` schema. Include repository state, iteration and
phase, claims with provenance, decisions, conflicts, open questions, ordered
next actions, touched artifacts, verification, and a continuation prompt.
Append the handoff event to `.planning/log.md` and list the snapshot in
`.planning/index.md`. Never invent provenance or discard unresolved conflicts.
