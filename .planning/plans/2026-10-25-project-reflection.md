# Plan: project-reflection

Spec: task brief (see prior-art/project-reflection.md for the build decision).

1. `skills/project-reflection/SKILL.md` — checkpoint-triggered, silent, no approvals, no quota, backfill only on named records, advisory entries in `.planning/reflections.md`.
2. Trigger (revised after review: standing instructions can be ignored, per-turn model hooks cost too much): `hooks/reflection-gate.py`, a model-free `Stop` hook. It fires only when a review/handoff file is new or changed, or a session has >=6 failed tool calls; it blocks the stop once with the exact instruction, verifies compliance (reflections.md changed or `NO_REFLECTION_NEEDED`), re-prompts once, then records a miss. State is per machine under `~/.j-stack/`; first run baselines only. Installed by install.sh into `~/.claude/hooks/` + settings.json merge.
3. Metrics: the same script writes measured per-window records to `.planning/metrics.jsonl` (checkpoint + SessionEnd); numbers come only from transcripts, never the model.
4. Wiring: `templates/reflection-checkpoint.md` (single source) appended to CLAUDE.md/AGENTS.md as the no-hook fallback; poc-wiki-init copy; Codex mapping row; skill at `~/.claude/skills` and `~/.codex/skills` (`--codex-only`). Codex hook trigger unverified.
5. Tests: `tests/structure.sh`, `tests/codex-config.sh`, `tests/reflection-gate.sh` (deterministic); opt-in `tests/reflection-behavior.sh` (7 skill scenarios) and `tests/reflection-hook-e2e.sh` (real Stop hook in headless Claude Code).
6. Ponytail pass (manual, plugin absent here): removed the skill's duplicate Codex section; no hook, no extra agent, no schema beyond one entry format. Graphify: built (`graphify update .`), used to confirm the only consumers of the shared templates are install.sh, poc-wiki-init, and tests.

Out of scope: central cross-project reflector, J-Vault writer, scheduler, bulk backfill.
