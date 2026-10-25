# Plan: project-reflection

Spec: task brief (see prior-art/project-reflection.md for the build decision).

1. `skills/project-reflection/SKILL.md` — checkpoint-triggered, silent, no approvals, no quota, backfill only on named records, advisory entries in `.planning/reflections.md`.
2. Wiring: `templates/reflection-checkpoint.md` (single source) appended by install.sh to CLAUDE.md/AGENTS.md for new and existing projects; poc-wiki-init copy; `handoff-snapshot` step 1.5 runs reflection first; Codex mapping row; skill installed to `~/.claude/skills` (full) and `~/.codex/skills` (`--codex-only`).
3. Tests: `tests/structure.sh`, `tests/codex-config.sh` (deterministic wiring); `tests/reflection-behavior.sh` (opt-in headless runs, 9 scenarios).
4. Ponytail pass (manual, plugin absent here): removed the skill's duplicate Codex section; no hook, no extra agent, no schema beyond one entry format. Graphify: built (`graphify update .`), used to confirm the only consumers of the shared templates are install.sh, poc-wiki-init, and tests.

Out of scope: central cross-project reflector, J-Vault writer, scheduler, bulk backfill.
