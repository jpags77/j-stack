#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

assert_file() {
  local file="$1"
  [ -f "$file" ] || { echo "missing: ${file}" >&2; exit 1; }
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  grep -Fq "$pattern" "$file" || { echo "missing pattern in ${file}: ${pattern}" >&2; exit 1; }
}

assert_not_contains() {
  local file="$1"
  local pattern="$2"
  ! grep -Fq "$pattern" "$file" || { echo "unexpected pattern in ${file}: ${pattern}" >&2; exit 1; }
}

# ── Skill files must exist ───────────────────────────────────────────────────
for skill in poc-wiki-init handoff-snapshot second-opinion stakeholder-pack build-mode prior-art-survey; do
  assert_file "${ROOT}/skills/${skill}/SKILL.md"
  echo "  ✓ skills/${skill}/SKILL.md"
done

# ── Skill files must have frontmatter ───────────────────────────────────────
for skill in poc-wiki-init handoff-snapshot second-opinion stakeholder-pack build-mode; do
  assert_contains "${ROOT}/skills/${skill}/SKILL.md" "name: ${skill}"
  echo "  ✓ skills/${skill}/SKILL.md has name: frontmatter"
done

# ── build-mode must have Iteration Progress reconciliation (live version) ─
assert_contains "${ROOT}/skills/build-mode/SKILL.md" "Iteration Progress"
assert_contains "${ROOT}/skills/build-mode/SKILL.md" "[auto]"
echo "  ✓ skills/build-mode/SKILL.md is current version (has Iteration Progress)"

# ── install.sh must NOT contain embedded skill heredocs ─────────────────────
assert_not_contains "${ROOT}/install.sh" "install_skill \"poc-wiki-init\""
assert_not_contains "${ROOT}/install.sh" "SKILL_EOF"
echo "  ✓ install.sh has no embedded skill heredocs"

# ── install.sh must use cp -r for custom skills ──────────────────────────────
assert_contains "${ROOT}/install.sh" "CUSTOM_SKILLS="
assert_contains "${ROOT}/install.sh" 'cp -r "$src" "${SKILLS_DIR}/"'
echo "  ✓ install.sh uses cp -r for custom skills"

# ── install.sh must NOT contain Phase 3.5 (GLOBAL_CLAUDE_SECTION) ───────────
assert_not_contains "${ROOT}/install.sh" "Phase 3.5: Global CLAUDE.md"
assert_not_contains "${ROOT}/install.sh" "GLOBAL_CLAUDE_SECTION"
echo "  ✓ install.sh has no Phase 3.5 / GLOBAL_CLAUDE_SECTION"

# ── index.html must NOT load React or Babel from CDN ────────────────────────
assert_not_contains "${ROOT}/index.html" "unpkg.com/react"
assert_not_contains "${ROOT}/index.html" "unpkg.com/@babel"
assert_not_contains "${ROOT}/index.html" "text/babel"
echo "  ✓ index.html loads no React/Babel CDN scripts"

echo ""
echo "All structure checks passed."
