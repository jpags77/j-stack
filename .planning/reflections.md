# Reflections

Advisory, revisable observations. Chronology lives in log.md; entries here are interpretation only.

## R-stale-heading-assertion: Tests that grep for a template heading go stale when the canonical heading is renamed
- Status: tentative
- Scope: repos where a doc template is single-sourced and tests assert on its section headings; not tested against other assertion styles
- Observed: tests/codex-config.sh still expected `## Codex operating modes` after the canonical section became `## Codex role`; it passed only after the assertion was updated (2026-07-19).
- Explanation: the heading rename landed in the other agent's WIP without a matching test update. (unverified; inferred from the diff state described in the handoff)
- Evidence: `handoffs/2026-07-19T1707-codex-checkpoint.md#codex_changes`; log.md 2026-07-19 13:07 (copy of same incident). Codex agent.
- History:
  - 2026-10-25 tentative: first seen (backfill)

## R-pin-only-on-fresh-clone: A version pin applied only in the fresh-clone branch is bypassed by cached checkouts
- Status: tentative
- Scope: install scripts that reuse a cached clone (e.g. under /tmp) and claim to use a pinned commit; the fix was not exercised against a real stale cache
- Observed: install.sh said it used GSTACK_PIN, but an existing `/tmp/gstack-source` checkout was reused without checking out the pin; the checkout was moved outside the fresh-clone branch (2026-07-19).
- Explanation: the pin checkout sat inside the clone branch, so cached clones kept whatever commit they had. (verified by code inspection only; the passing checks `bash -n`, structure.sh and codex-config.sh do not exercise the cached path)
- Evidence: `handoffs/2026-07-19T1707-codex-checkpoint.md#codex_changes`; log.md 2026-07-19 13:07 (copy). Codex agent.
- History:
  - 2026-10-25 tentative: first seen (backfill)

## R-negative-scenario-vacuous-pass: A "produces nothing" test passes trivially unless the scenario forces something worth recording
- Status: tentative
- Scope: behavioral tests of agent skills whose correct output can be "no change"; seen once, in this repo's reflection tests
- Observed: the first run of `tests/reflection-behavior.sh` passed every check, including the unverified-cause scenario, because the agent wrote no entry at all (2026-10-25). After the scenario was rewritten around a clear successful strategy, the run exercised the uncertainty path.
- Explanation: an "acceptable: no entry" branch made the assertion unfalsifiable for that input. (verified by reading the first run's output directory; why the agent chose to write nothing was not investigated)
- Evidence: `tests/reflection-behavior.sh` scenario 2 (before/after this commit); session 2026-10-25.
- History:
  - 2026-10-25 tentative: first seen
