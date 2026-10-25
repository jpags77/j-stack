## Codex role

Codex is a separate j-stack runtime, not the primary Claude skill host. It uses the same `.planning/` blackboard and phase order, but executes the workflow through Codex-native repo work instead of Claude slash commands.

- **Direct runtime mode:** The user opens the repo in Codex to do j-stack work. Start from `AGENTS.md`, `.planning/index.md`, `.planning/log.md`, and the latest `.planning/handoffs/` snapshot, then continue the current phase directly.
- **Fallback mode:** Claude Code hits usage limits or the user deliberately switches tools. Resume from the same `.planning/` state without requiring re-explanation.
- **Review mode:** Claude invokes Codex for an independent `second-opinion` review. Inspect only the requested artifact unless the prompt asks for broader repo context, and return findings suitable for filing under `.planning/reviews/`.

In every mode, keep `.planning/` as the durable source of truth. Notable analysis, decisions, reviews, and handoff state should be written into the appropriate `.planning/` section and logged in `.planning/log.md`.

## Claude skill mapping for Codex

Claude slash commands and skills are the source names for the process. In Codex, follow the same lane semantics even when the command itself is not available:

| Claude surface | Codex behavior |
| --- | --- |
| `/office-hours`, `/plan-ceo-review` | Run EXPAND as a problem/scope challenge before design work. |
| `superpowers:brainstorming` | Refine requirements and approaches before planning or code edits. |
| `prior-art-survey` | Use the bundled prior-art skill files and web/package research where available. |
| `superpowers:writing-plans` | Produce or follow a locked implementation plan before BUILD work. |
| `superpowers:subagent-driven-development` | Keep implementation scoped, isolated, test-driven, and spec-bound. |
| `/qa`, `/design-review`, `/cso` | Treat POLISH as verification, UX review, and security/risk review. |
| `second-opinion` | Usually means Codex is the independent reviewer; produce review artifacts, not edits. |
| `handoff-snapshot` | Write a timestamped `.planning/handoffs/` blackboard snapshot before switching tools, pausing, or checkpointing significant work. |
| `project-reflection` | Follow the skill file named in the Reflection section; write only `.planning/reflections.md`. |
