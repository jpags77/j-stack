---
name: poc-wiki-init
description: Bootstraps the shared .planning markdown wiki for a new PoC engagement.
---

# poc-wiki-init

Use when `.planning/` is absent. If it already exists, read `index.md`, report
the current state, and do not overwrite it.

Ask for the fidelity target (working PoC, polished demo, or MVP), then create
the established `.planning/` directories and schema files for the repository's
supported tools. Initialize `index.md` and `log.md` using the existing schema.
The wiki is the shared source of truth; preserve its files and make reruns
idempotent. Record the initialization decision and next phase in the blackboard.

The minimum compatible layout is `.planning/index.md`, `.planning/log.md`,
`.planning/vision/`, `.planning/prior-art/`, `.planning/plans/`,
`.planning/reviews/`, `.planning/stakeholder-pack/`, and
`.planning/handoffs/`. Use markdown files with the headings and links expected
by the repository's `AGENTS.md`; never overwrite existing files.
