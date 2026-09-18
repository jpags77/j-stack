#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

assert_contains() {
  local file="$1"
  local pattern="$2"

  if ! grep -Fq -- "$pattern" "$file"; then
    echo "missing pattern in ${file}: ${pattern}" >&2
    exit 1
  fi
}

assert_contains "${ROOT}/install.sh" "Phase 3.25 — Configuring project AGENTS.md"
assert_contains "${ROOT}/install.sh" "--codex-only"
assert_contains "${ROOT}/install.sh" "--codex-global"
assert_contains "${ROOT}/install.sh" "CODEX_SKILLS=(build-mode poc-wiki-init handoff-snapshot prior-art-survey stakeholder-pack adversarial-review)"
assert_contains "${ROOT}/install.sh" 'skills/codex/${skill}'
assert_contains "${ROOT}/install.sh" "codex-global-policy.md"
assert_contains "${ROOT}/install.sh" "Codex-only mode"
assert_contains "${ROOT}/install.sh" "Unknown option"
assert_contains "${ROOT}/install.sh" 'if [ "$SKIP_CODEX" = false ] && [ "$CODEX_GLOBAL" = false ]'
assert_contains "${ROOT}/install.sh" "PROJECT_AGENTS"
assert_contains "${ROOT}/install.sh" "AGENTS_SECTION"
assert_contains "${ROOT}/install.sh" "Created AGENTS.md with Codex lane configuration"

assert_contains "${ROOT}/AGENTS.md" "## Codex role"
assert_contains "${ROOT}/AGENTS.md" "Direct runtime mode"
assert_contains "${ROOT}/AGENTS.md" "Fallback mode"
assert_contains "${ROOT}/AGENTS.md" "Review mode"
assert_contains "${ROOT}/AGENTS.md" "## Claude skill mapping for Codex"

assert_contains "${ROOT}/.planning/AGENTS.md" "EXPAND -> REFINE -> SURVEY -> PLAN -> BUILD -> POLISH -> DEFEND -> HANDOFF"
assert_contains "${ROOT}/.planning/AGENTS.md" "## Codex role"
assert_contains "${ROOT}/.planning/AGENTS.md" "Direct runtime mode"
assert_contains "${ROOT}/.planning/AGENTS.md" "## Claude skill mapping for Codex"

assert_contains "${ROOT}/README.md" "GitHub integration"
assert_contains "${ROOT}/README.md" "Codex runtime"
assert_contains "${ROOT}/README.md" "bash install.sh --codex-only"
assert_contains "${ROOT}/README.md" "--codex-global"
assert_contains "${ROOT}/README.md" "--dry-run"
assert_contains "${ROOT}/README.md" "temporary-HOME"
assert_contains "${ROOT}/README.md" "adversarial-review"
assert_contains "${ROOT}/README.md" "--codex-only --codex-global --dry-run"
assert_contains "${ROOT}/README.md" "managed marker block is the only content j-stack owns"
assert_contains "${ROOT}/README.md" "valid block is replaced in place"
assert_contains "${ROOT}/README.md" "no API key or paid API"
assert_contains "${ROOT}/templates/codex-role.md" "Direct runtime mode"
assert_contains "${ROOT}/skills/codex/adversarial-review/SKILL.md" "fresh-context"
assert_contains "${ROOT}/skills/codex/adversarial-review/SKILL.md" "challenge rubric"
assert_contains "${ROOT}/skills/codex/adversarial-review/SKILL.md" "paid API calls"
assert_contains "${ROOT}/skills/codex/adversarial-review/SKILL.md" 'fork_turns: "none"'
assert_contains "${ROOT}/skills/codex/adversarial-review/SKILL.md" "gpt-5.6-sol"
assert_contains "${ROOT}/skills/codex/adversarial-review/SKILL.md" "high"
assert_contains "${ROOT}/skills/codex/adversarial-review/SKILL.md" "named artifact"
assert_contains "${ROOT}/skills/codex/poc-wiki-init/SKILL.md" ".planning/index.md"
assert_contains "${ROOT}/skills/codex/poc-wiki-init/SKILL.md" ".planning/log.md"
assert_contains "${ROOT}/skills/codex/handoff-snapshot/SKILL.md" "j-stack.handoff.blackboard.v1"
assert_contains "${ROOT}/skills/codex/handoff-snapshot/SKILL.md" "repository_state"
assert_contains "${ROOT}/skills/codex/stakeholder-pack/SKILL.md" "optional"
assert_contains "${ROOT}/skills/codex/build-mode/SKILL.md" "j-stack-governed"
assert_contains "${ROOT}/skills/codex/build-mode/SKILL.md" "workflow does not apply"
