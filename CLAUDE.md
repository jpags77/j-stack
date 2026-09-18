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

**Prior-art gate (SURVEY before PLAN):** Before invoking `superpowers:writing-plans`, `.planning/index.md` must show `Prior-art: ✅ complete`. If it is `⬜ pending` or missing, run `prior-art-survey` first — it sets the flag once the survey runs and you make a build/adopt/fork/hybrid decision. This matters because `superpowers:brainstorming` hands off directly to planning by default; this gate is what inserts SURVEY between them so prior-art is never silently skipped.

**POLISH report filing (enables auto-detection).** `/qa`, `/cso`, and `/design-review` don't write to the wiki on their own. After running one in this project, save its report to `.planning/reviews/` with a distinguishable name — `/qa` → `qa-<date>.md`, `/cso` → `security-<date>.md`, `/design-review` → `design-<date>.md` — append a line to `.planning/log.md`, and tick that step in the `## Iteration Progress` block of `index.md`. This lets `build-mode` confirm POLISH progress without asking, and feeds `stakeholder-pack` (which expects `security-*` / `design-*`).

## Wiki

This project's source of truth lives at `.planning/`. Read `.planning/index.md` before any non-trivial work. Check `.planning/handoffs/` for the most recent snapshot — another tool may have left state for you to resume from.

## Cross-tool

When usage limits hit, run `handoff-snapshot` and resume in Codex / Cursor / ChatGPT / Gemini. Each has its own schema file in `.planning/`.

## Work checkpoints

After significant code interactions, create a durable checkpoint before switching tasks: commit the coherent git diff, update `.planning/` with notable decisions or review output, append `.planning/log.md`, and run `handoff-snapshot`. Do not push to GitHub automatically; push only when the user asks or an explicit publish workflow is active.
