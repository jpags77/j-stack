# Task 3 report — documentation and real-home safety boundary

Date: 2026-09-03

## Outcome

Recorded the durable checkpoint in `.planning/index.md` and `.planning/log.md`, and created `.planning/handoffs/2026-09-03T1817-codex-global-runtime.md`.

Per the controller ruling, the README documentation produced and tested by Task 2 was not rewritten or duplicated. The existing README references the opt-in `--codex-global` path, six native skills, and `adversarial-review`; the installer/test behavior remains the authoritative safety boundary for the temporary-home and dry-run guarantees.

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

`codex-global-config.sh` verified preservation, exact managed-block replacement, idempotency, permissions, malformed-marker refusal, dry-run non-mutation/diff output, and the six-skill allowlist in temporary `HOME` directories. `codex-config.sh` and `structure.sh` passed their static and repository-shape checks.

## Real-home boundary

The real `~/.codex` installer was not run. The handoff snapshot records the user-controlled next command (`bash install.sh --codex-only --codex-global`) after review of the passing suite and dry-run diff. No native isolated review was fabricated: `adversarial-review` may use the current host's isolated fresh-context capability when available and must report unavailability without falling back to Claude CLI, an API key, or paid API calls.

## Commit

`499f6a2 docs: record Codex global runtime safety checkpoint`.
