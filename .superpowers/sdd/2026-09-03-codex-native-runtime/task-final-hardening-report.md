# Final hardening report

Date: 2026-09-18
Scope: Codex-global runtime hardening only. Claude runtime/session-start/build-mode defaults were not changed, and the real `~/.codex` installer was not run.

## TDD evidence

### RED

Regression tests were added before the implementation changes and run with:

```text
bash tests/codex-global-config.sh
bash tests/codex-config.sh
```

Expected failures observed:

- `codex-global-config.sh`: `unknown flag accepted` (`--dryrun` was silently ignored).
- `codex-config.sh`: `missing pattern ... install.sh: Unknown option`.

These failures demonstrated that the new tests exercised missing behavior.

### GREEN

After the minimal implementation, the required verification commands all passed:

```text
bash tests/codex-global-config.sh   # codex global config tests passed
bash tests/codex-config.sh          # passed
bash tests/structure.sh              # All structure checks passed.
bash -n install.sh                   # passed
git diff --check                      # passed
```

Coverage added includes fail-closed unknown flags, strict marker-prefix syntax,
duplicate/malformed layouts, CRLF preservation, symlink refusal, deterministic
allowlisted skill replacement, native adversarial-review contract assertions,
self-contained planning/handoff contracts, and skipping the Codex CLI
prerequisite when `--codex-global` is selected.

