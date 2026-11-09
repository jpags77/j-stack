# Runtime baseline — pre-change decision trial

Eight synthetic cases were presented to a fresh Luna agent at medium effort,
using the existing build-mode, prior-art-survey, handoff-snapshot and poc-wiki-init
skills. The agent was excluded from the proposed design and plan. This tests
stated process decisions, not execution or completed task acceptance.

Sanitized responses: `evals/baseline-decisions.json` (captured before instruction
changes). Native per-agent input, cache, output and reasoning usage were not
available: all usage is unknown. No token or monetary savings can be inferred.
One pass per case; no repeated-run statistics or claim of stable behavior.

Observed decisions:

- Bounded correction and copy edit did not reopen prior-art research.
- New feature reused architecture evidence but retained pending phase checks.
- Unknown integration asked for fidelity and import criteria; full phase flow.
- Changed architecture reopened scope, survey and plan.
- Interrupted mutation inspected surviving files but could not recover unwritten
  intent. It would ask for missing next steps.
- Cross-runtime case correctly treated another dirty worktree as unavailable.
- Absent security reviewer left required review incomplete rather than declaring
  success.

Baseline already shows some proportional judgment. The proposed changes must
improve explicit evidence and durable recovery; they cannot honestly claim these
existing behaviors as new gains. Mechanical and full-task acceptance require
separate tests.

The baseline implementation itself hit a usage limit. Its uncommitted files and
the controller ledger survived in the same worktree; Luna resumed those files on
2026-09-21. This is an observed incident, not evidence that the proposed recovery
utility (not yet implemented) works.

## Instruction inventory before changes

UTF-8 file bytes, not tokens or measured context ingestion:

| File | Bytes |
| --- | ---: |
| AGENTS.md | 3849 |
| templates/lane-doctrine.md | 2658 |
| templates/codex-role.md | 2228 |
| skills/build-mode/SKILL.md | 13039 |
| skills/codex/build-mode/SKILL.md | 1232 |
| skills/prior-art-survey/SKILL.md | 8679 |
| skills/codex/prior-art-survey/SKILL.md | 761 |

These are alternative/runtime and source-template surfaces, not seven files
necessarily read by one agent. Their 32446-byte sum is an inventory only.
