# Wiki Index

One-line summary of every page in this wiki. Update on every page creation.

## Current State

**Iteration:** 1
**Phase:** BUILD (maintenance) — this is j-stack's own repo under continuous self-improvement, not a single EXPAND→HANDOFF pass. Engagement Context below is the standing spec; the 2026-07-10 self-audit backlog (handoffs/2026-07-10T1803-snapshot.md, N1-N18) is the current unit of work.
**Fidelity target:** C — MVP (production-ready Claude Code skill stack)
**Prior-art:** ✅ complete — BUILD (project-reflection), 2026-10-25. Bounded inline survey; decision delegated by the task brief. The original pipeline design still predates the survey skill.
**Last updated:** 2026-10-25T14:50:00Z

## Iteration Progress

Which phase steps have run in the **current** iteration. Reset all to ⬜ when the iteration bumps (session-start step 6). `[auto]` = session-start can confirm from a wiki artifact; `[confirm]` = no reliable wiki trace, so session-start asks the user and records the answer here.

- [EXPAND] office-hours — ✅  `[auto: vision/]`
- [EXPAND] plan-ceo-review — ⬜  `[confirm]`
- [REFINE] brainstorming — ⬜  `[confirm]`
- [SURVEY] prior-art-survey — ✅  `[auto: Prior-art flag above — authoritative]`
- [PLAN] writing-plans — ✅  `[auto: plans/2026-06-17-ponytail-fixes.md]`
- [PLAN] ponytail-review spec — ⬜  `[confirm]`
- [BUILD] subagent-driven-development — ⬜  `[auto: commits since plan]`
- [POLISH] qa — ⬜  `[auto: reviews/qa-*]`
- [POLISH] design-review — ⬜  `[auto: reviews/design-*]`
- [POLISH] cso — ⬜  `[auto: reviews/security-*]`
- [DEFEND] second-opinion — ⬜  `[auto: reviews/second-opinion-*]`
- [DEFEND] stakeholder-pack — ⬜  `[auto: stakeholder-pack/]`
- [HANDOFF] document-release — ⬜  `[confirm]`
- [HANDOFF] handoff-snapshot — ✅  `[auto: handoffs/2026-07-10T1803-snapshot.md]`

## Engagement Context

**Goal:** Maintain and improve j-stack as a production-ready Claude Code skill stack — keep it lean, current, and well-structured as a reusable foundation for enterprise PoC delivery.
**Constraints:** Must remain a single-command install; no new external dependencies without clear justification; skills-as-files pattern established 2026-06-17 is now the standard.
**Done when:** Pipeline, tooling, and documentation are coherent, tested, and ready for use on new PoC engagements.
**Prior docs:** CLAUDE.md, AGENTS.md, .planning/ wiki, skills/ and agents/ directories.

## vision/
- [understand-anything-integration.md](vision/understand-anything-integration.md) — CLOSED: Understand-Anything integration evaluated and rejected (scope mismatch)
- [codex-integration.md](vision/codex-integration.md) — implemented design for treating Codex as a first-class fallback and review runtime via AGENTS.md + .planning/
- [handoff-blackboard.md](vision/handoff-blackboard.md) — accepted design for structured handoff snapshots with typed state, provenance, conflicts, and checkpoint policy
- [ponytail-integration.md](vision/ponytail-integration.md) — ponytail plugin integration: plan-gate decision, full level, audit findings, /goal and auto-research context
- [graphify-integration.md](vision/graphify-integration.md) — graphify on-demand knowledge graph: session-start detection, existing-repo use case, wiki convention
- [headroom-integration.md](vision/headroom-integration.md) — headroom context compression: global triggers + j-stack pipeline checkpoints

## prior-art/
- [project-reflection.md](prior-art/project-reflection.md) — reflection/memory tools surveyed; decision: BUILD (thin)

## plans/
- [2026-10-25-project-reflection.md](plans/2026-10-25-project-reflection.md) — project-reflection skill, checkpoint wiring, tests
- [2026-06-17-ponytail-fixes.md](plans/2026-06-17-ponytail-fixes.md) — ponytail audit fixes: skill extraction, install.sh shrink (-807 lines), vanilla HTML

## reviews/
(empty — populate after /qa, /design-review, /cso, second-opinion)

## stakeholder-pack/
(empty — populate after stakeholder-pack)

## reflections
- [reflections.md](reflections.md) — advisory observations with evidence and uncertainty (project-reflection); 3 tentative entries, 2 backfilled from the 2026-07-19 handoffs

## handoffs/
- [2026-10-25T1455-project-reflection.md](handoffs/2026-10-25T1455-project-reflection.md) — project-reflection built + tested; install and bounded pilot still required
- [2026-10-25T1600-reflection-hook.md](handoffs/2026-10-25T1600-reflection-hook.md) — reflection trigger is now a model-free Stop hook (supersedes the instruction-based claim in the 1455 snapshot); install and Codex check still required
- [2026-07-10T1803-snapshot.md](handoffs/2026-07-10T1803-snapshot.md) — self-audit findings: 10 furthering ideas + 10 redundancies/inconsistencies to prune, 18 prioritized next actions (N1-N18), none implemented yet
- [2026-07-19T1707-codex-checkpoint.md](handoffs/2026-07-19T1707-codex-checkpoint.md) — Codex sync checkpoint: latest WIP verified, stale Codex config test fixed, cached gstack pin enforcement tightened, tests passing
- [2026-07-19T1715-codex-runtime.md](handoffs/2026-07-19T1715-codex-runtime.md) — Codex runtime split: `install.sh --codex-only`, separate-runtime docs/templates/tests, local Codex/Superpowers presence confirmed
