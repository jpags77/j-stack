# Project Context

## Stack ownership (skill lane management)

Multiple skill packs are installed. Each owns a specific phase of the workflow:

- **Front-end scoping (Expand phase):** /office-hours, /plan-ceo-review (gstack)
- **Refining (Refine phase):** Superpowers brainstorming
- **Prior art (Survey phase):** prior-art-survey (custom)
- **Planning (Plan phase):** Superpowers writing-plans
- **Building (Build phase):** Superpowers subagent-driven-development, with /design-shotgun + /design-html for UI work
- **Polishing (Polish phase):** /qa, /design-review, /cso (gstack)
- **Defending (Defend phase):** second-opinion, stakeholder-pack (custom)
- **Handoff:** /document-release (gstack), handoff-snapshot (custom)

Run them in order. Do NOT use gstack's /autoplan or /plan-eng-review — they overlap Superpowers' planning lane and create conflicts.

## Wiki

This project's source of truth lives at `.planning/`. Read `.planning/index.md` before any non-trivial work. Check `.planning/handoffs/` for the most recent snapshot — another tool may have left state for you to resume from.

## Cross-tool

When usage limits hit, run `handoff-snapshot` and resume in Codex / Cursor / ChatGPT / Gemini. Each has its own schema file in `.planning/`.

## Work checkpoints

After significant code interactions, create a durable checkpoint before switching tasks: commit the coherent git diff, update `.planning/` with notable decisions or review output, append `.planning/log.md`, and run `handoff-snapshot`. Do not push to GitHub automatically; push only when the user asks or an explicit publish workflow is active.

## Reflection

At the checkpoints above where something was actually learned — a substantial review finished, a hard failure resolved, or a handoff — run `project-reflection` first (Codex: read `~/.claude/skills/project-reflection/SKILL.md` or `~/.codex/skills/project-reflection/SKILL.md` and follow it). It records revisable observations in `.planning/reflections.md`, asks for no approval, and writes nothing when nothing material was learned. Its own edits never trigger another reflection. Observations are advisory: they do not change this file, other skills, or policy.

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
