---
name: build-mode
description: Orients Codex sessions that will produce code, plans, designs, or reviews in a j-stack-governed repository.
---

# build-mode

Use this skill for coding, planning, design, or review work. First classify the
repository: if it is j-stack-governed, it has `AGENTS.md` plus the `.planning/`
blackboard and this workflow applies; if it is not j-stack-governed, report
that the j-stack workflow does not apply and continue under local/user
instructions without requiring `.planning/` reads. Do not activate for pure
Q&A, lookups, or one-off non-coding work.

1. Read `AGENTS.md`, `.planning/index.md`, the last 15 entries of
   `.planning/log.md`, and the newest file in `.planning/handoffs/`.
2. Check `.planning/vision/`, `prior-art/`, `plans/`, `reviews/`, and
   `stakeholder-pack/` to reconcile the phase checklist.
3. State the iteration, phase, fidelity target, current goal, open items, and
   the next pending phase step.
4. Follow `EXPAND → REFINE → SURVEY → PLAN → BUILD → POLISH → DEFEND → HANDOFF`.
   Repository `AGENTS.md` and the `.planning/` blackboard are authoritative.
5. Keep durable decisions and checkpoints in `.planning/`; do not silently
   skip a required phase.
