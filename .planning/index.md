# Wiki Index

One-line summary of every page in this wiki. Update on every page creation.

## Current State

**Iteration:** 1
**Phase:** BUILD — approved runtime reliability and efficiency plan; baseline capture precedes instruction changes. Implementation uses Luna workers in an isolated worktree.
**Fidelity target:** C — MVP (production-ready Claude Code skill stack)
**Prior-art:** ✅ complete — scoped to runtime reliability and efficiency; HYBRID native-first approach authorized by the user's instruction to proceed. See prior-art/runtime-efficiency.md. A retrospective survey of the entire original pipeline remains outstanding.
**Last updated:** 2026-09-21

## Iteration Progress

Which phase steps have run in the **current** iteration. Reset all to ⬜ when the iteration bumps (session-start step 6). `[auto]` = session-start can confirm from a wiki artifact; `[confirm]` = no reliable wiki trace, so session-start asks the user and records the answer here.

- [EXPAND] office-hours — ✅  `[auto: vision/]`
- [EXPAND] plan-ceo-review — ⬜  `[confirm]`
- [REFINE] brainstorming — ⬜  `[confirm]`
- [SURVEY] prior-art-survey — ✅  `[scope: runtime reliability and efficiency; prior-art/runtime-efficiency.md]`
- [PLAN] writing-plans — ✅  `[scope: plans/2026-09-20-runtime-reliability-efficiency.md; user approved BUILD]`
- [PLAN] ponytail-review spec — ✅  `[scope: simplification gate in runtime reliability and efficiency plan]`
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
- [runtime-reliability-efficiency.md](vision/runtime-reliability-efficiency.md) — approved design for recovery, shared evidence, proportional workflow, and measured efficiency
- [understand-anything-integration.md](vision/understand-anything-integration.md) — CLOSED: Understand-Anything integration evaluated and rejected (scope mismatch)
- [codex-integration.md](vision/codex-integration.md) — implemented design for treating Codex as a first-class fallback and review runtime via AGENTS.md + .planning/
- [handoff-blackboard.md](vision/handoff-blackboard.md) — accepted design for structured handoff snapshots with typed state, provenance, conflicts, and checkpoint policy
- [ponytail-integration.md](vision/ponytail-integration.md) — ponytail plugin integration: plan-gate decision, full level, audit findings, /goal and auto-research context
- [graphify-integration.md](vision/graphify-integration.md) — graphify on-demand knowledge graph: session-start detection, existing-repo use case, wiki convention
- [headroom-integration.md](vision/headroom-integration.md) — headroom context compression: global triggers + j-stack pipeline checkpoints
- [codex-global-runtime.md](vision/codex-global-runtime.md) — approved design for opt-in global Codex policy, Codex-native skills, and fresh-context adversarial review
- [codex-global-runtime checkpoint](../.superpowers/sdd/2026-09-03-codex-native-runtime/task-3-report.md) — implementation verified; real `~/.codex` installation remains explicitly user-controlled

## prior-art/
- [runtime-efficiency.md](prior-art/runtime-efficiency.md) — native capabilities and reuse survey; scoped HYBRID decision, Jev advisory experiment only
- [jev-context-compaction.md](prior-art/jev-context-compaction.md) — Jev extractive compaction survey; recommends optional experimentation plus a deterministic WIP capsule, adoption decision pending

## plans/
- [2026-09-20-runtime-reliability-efficiency.md](plans/2026-09-20-runtime-reliability-efficiency.md) — approved eight-task implementation plan; BUILD underway with Luna and baseline committed
- [2026-06-17-ponytail-fixes.md](plans/2026-06-17-ponytail-fixes.md) — ponytail audit fixes: skill extraction, install.sh shrink (-807 lines), vanilla HTML

## reviews/
- [runtime-baseline.md](reviews/runtime-baseline.md) — pre-change synthetic decision baseline; native token usage unknown
- [2026-09-20-runtime-plan-review.md](reviews/2026-09-20-runtime-plan-review.md) — Luna review findings resolved: baseline sequencing, WIP ownership, filename collisions, and token accounting
- [2026-09-20-j-stack-strategic-review.md](reviews/2026-09-20-j-stack-strategic-review.md) — strategic assessment: recovery within turns, shared state contracts, proportional process, acceptance evidence, and behavioral evaluation; recommendations only

## stakeholder-pack/
(empty — populate after stakeholder-pack)

## handoffs/
- [2026-09-21-runtime-build-resume.md](handoffs/2026-09-21-runtime-build-resume.md) — approved BUILD resumed in isolated worktree after usage interruption; consult task ledger for progress
- [2026-09-20T1807-runtime-plan.md](handoffs/2026-09-20T1807-runtime-plan.md) — written plan ready for review; Luna execution retained; baseline and versioned state are first tasks
- [2026-07-10T1803-snapshot.md](handoffs/2026-07-10T1803-snapshot.md) — self-audit findings: 10 furthering ideas + 10 redundancies/inconsistencies to prune, 18 prioritized next actions (N1-N18), none implemented yet
- [2026-07-19T1707-codex-checkpoint.md](handoffs/2026-07-19T1707-codex-checkpoint.md) — Codex sync checkpoint: latest WIP verified, stale Codex config test fixed, cached gstack pin enforcement tightened, tests passing
- [2026-07-19T1715-codex-runtime.md](handoffs/2026-07-19T1715-codex-runtime.md) — Codex runtime split: `install.sh --codex-only`, separate-runtime docs/templates/tests, local Codex/Superpowers presence confirmed
- [2026-09-18T0000-codex-global-installed.md](handoffs/2026-09-18T0000-codex-global-installed.md) — global Codex policy and native skills installed after reviewed dry run and full verification
- [2026-09-03T1817-codex-global-runtime.md](handoffs/2026-09-03T1817-codex-global-runtime.md) — Codex global runtime checkpoint: tests and dry-run safety verified; real `~/.codex` installation awaits explicit user command
