# Handoff snapshot — Codex global runtime

Date: 2026-09-03T18:17:00Z
Phase: BUILD (maintenance)
Task: Task 3 — documentation and real-home safety boundary

## State

- Approved design: `.planning/vision/codex-global-runtime.md`.
- Task 1 and Task 2 implementation is committed through `b1e55e8` (`fix: harden Codex global dry run`).
- Task 2's README safety documentation is retained unchanged per the controller ruling; this task confirms it rather than duplicating it.
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

The integration test exercised temporary-`HOME` append, replacement, idempotency, mode preservation, malformed-marker refusal, dry-run non-mutation/diff output, and six-skill installation. The static test covered the Codex flags, allowlist, templates, and adversarial-review contract.

## Safety boundary and next action

The real-home operation is intentionally user-controlled. After reviewing the passing tests and the dry-run diff, the user may explicitly run:

```bash
bash install.sh --codex-only --codex-global
```

That command is not run by this handoff. The native isolated fresh-context reviewer is available only when the current Codex host exposes that capability; otherwise `adversarial-review` must report that it cannot perform the review, with no Claude CLI, API key, or paid API fallback.

## Continuation

Read `AGENTS.md`, `.planning/index.md`, `.planning/log.md`, and this snapshot before continuing. Review the dry-run output and obtain the user's explicit instruction before any real `~/.codex` installation.
