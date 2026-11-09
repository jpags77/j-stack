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

The RED evidence above is aggregate and stops at the first failing assertion in
each shell test; it does not claim to have exercised every later regression.
The GREEN evidence below is the complete post-fix verification.

## Round 2 hardening (2026-09-18)

### Targeted RED

Round-2 assertions were added for exact managed-marker version ownership,
bundled wiki/blackboard resources, and the explicit adversarial-review API/CLI
boundaries. Before implementation, the targeted run failed as follows:

```text
bash tests/codex-global-config.sh
# expected command to fail: run_install
bash tests/codex-config.sh
# missing pattern ... adversarial-review/SKILL.md: all API calls
```

The first command stopped at the unsupported `version=0` marker assertion, so
this is not evidence that it exercised later round-2 assertions.

### GREEN

After the round-2 fixes, these checks passed:

```text
python3 -m json.tool skills/codex/handoff-snapshot/templates/blackboard.json
bash tests/codex-global-config.sh   # codex global config tests passed
bash tests/codex-config.sh          # passed
bash tests/structure.sh              # All structure checks passed.
bash -n install.sh                   # passed
git diff --check                      # passed
```

The temporary-HOME integration test now leaves unsupported marker versions
untouched, while `version=1` is replaced idempotently. Codex skills now ship
concrete `index.md`, `log.md`, and complete `j-stack.handoff.blackboard.v1`
templates; the static checks verify their presence and nested fields. The
adversarial-review contract explicitly prohibits all API calls and the Claude
CLI, in addition to credentials and paid APIs. No real `~/.codex` installation
was run.
