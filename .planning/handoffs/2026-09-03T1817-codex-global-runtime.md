# Handoff snapshot — Codex global runtime

Date: 2026-09-03T18:17:00Z
Phase: BUILD (maintenance)
Task: Task 3 — documentation and real-home safety boundary

## State

- Approved design: `.planning/vision/codex-global-runtime.md`.
- Task 1 and Task 2 implementation is committed through `b1e55e8` (`fix: harden Codex global dry run`).
- Task 3's README safety boundary is explicit: dry-run command, temporary-HOME test-first sequence, managed-marker ownership, and no-API-key/paid-API review behavior.
- No real `~/.codex` installer invocation was run.

## Verification

All commands exited successfully:

```text
bash tests/codex-global-config.sh
bash tests/codex-config.sh
bash tests/structure.sh
bash -n install.sh
git diff --check
```

The integration test exercised temporary-`HOME` append, replacement, idempotency, mode preservation, malformed-marker refusal, dry-run non-mutation/diff output, and six-skill installation. The static test covered the Codex flags, allowlist, templates, adversarial-review contract, and exact README wording for the dry-run command, managed-marker ownership/replacement, and no-API-key/paid-API behavior. The original assertions first produced the expected RED failure; the round-2 exact assertions matched the delivered wording immediately.

## Commits

- `13032dd docs: record Codex global runtime safety checkpoint`
- `2f7c0ee docs: document Codex global safety boundary` (amended fix commit; README safety boundary and static assertions).
- `eeab253 docs: finalize Codex runtime checkpoint`
- `f3ad610 test: assert Codex safety documentation wording`
- `53a5cb1 docs: correct Codex checkpoint evidence`
- `1787bec docs: close Codex checkpoint lineage` (last recorded checkpoint before this metadata correction).

The commit containing this metadata correction is authoritative in `git log`; its SHA is intentionally not self-embedded.

## Safety boundary and next action

The real-home operation is intentionally user-controlled. After reviewing the passing tests and the dry-run diff, the user may explicitly run:

```bash
bash install.sh --codex-only --codex-global
```

That command is not run by this handoff. The native isolated fresh-context reviewer is available only when the current Codex host exposes that capability; otherwise `adversarial-review` must report that it cannot perform the review, with no Claude CLI, API key, or paid API fallback.

## Continuation

Read `AGENTS.md`, `.planning/index.md`, `.planning/log.md`, and this snapshot before continuing. Review the dry-run output and obtain the user's explicit instruction before any real `~/.codex` installation.
