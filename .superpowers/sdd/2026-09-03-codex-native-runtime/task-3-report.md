# Task 3 report — documentation and real-home safety boundary

Date: 2026-09-03

## Outcome

Recorded the durable checkpoint in `.planning/index.md` and `.planning/log.md`, and created `.planning/handoffs/2026-09-03T1817-codex-global-runtime.md`.

The controller's revised ruling required the README safety boundary to be made explicit. README now documents the opt-in `--codex-global` path, the `--codex-only --codex-global --dry-run` preview, the temporary-HOME test-first sequence, managed-marker preservation/replacement, and the no-API-key/paid-API adversarial-review rule.

## Verification evidence

All requested checks passed with exit status 0:

```text
bash tests/codex-global-config.sh
bash tests/codex-config.sh
bash tests/structure.sh
bash -n install.sh
git diff --check
git status --short
```

`codex-global-config.sh` verified preservation, exact managed-block replacement, idempotency, permissions, malformed-marker refusal, dry-run non-mutation/diff output, and the six-skill allowlist in temporary `HOME` directories. `codex-config.sh` passed static checks, including exact README wording for the dry-run command, managed-marker ownership/replacement, and no-API-key/paid-API behavior; `structure.sh` passed its repository-shape checks.

The original documentation assertions produced the expected RED result before the README update. The round-2 exact assertions matched the already-delivered wording immediately; no RED phase was needed for this test-only tightening.

## Real-home boundary

The real `~/.codex` installer was not run. The handoff snapshot records the user-controlled next command (`bash install.sh --codex-only --codex-global`) after review of the passing suite and dry-run diff. No native isolated review was fabricated: `adversarial-review` may use the current host's isolated fresh-context capability when available and must report unavailability without falling back to Claude CLI, an API key, or paid API calls.

## Commit

Prior checkpoint: `13032dd docs: record Codex global runtime safety checkpoint`.

Commit chain: `13032dd` checkpoint, `2f7c0ee` safety documentation, `eeab253` finalized report/handoff metadata, `f3ad610` exact static safety assertions, and `53a5cb1` corrected checkpoint evidence.
