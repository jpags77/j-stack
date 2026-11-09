---
name: prior-art-survey
description: Investigates existing projects, libraries, and patterns before planning non-trivial work.
---

# prior-art-survey

Run after the approach is sufficiently specified and before implementation
planning for non-trivial software. Use Codex-native research capabilities and,
when available, isolated reviewers for OSS, library, and architecture-pattern
scouts. If those capabilities are unavailable, report the limitation clearly.

Synthesize fit, gaps, maintenance, and license into
`.planning/prior-art/<spec-slug>.md`, then obtain an explicit BUILD, ADOPT,
FORK, or HYBRID decision. Record the decision in `.planning/index.md` and
`.planning/log.md`. Do not present a link dump or recommend unverified,
deprecated packages.
