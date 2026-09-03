#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_home="$(mktemp -d)"
tmp_target="$(mktemp -d)"
dry_home="$(mktemp -d)"
dry_target="$(mktemp -d)"
trap 'rm -rf "$tmp_home" "$tmp_target" "$dry_home" "$dry_target"' EXIT
mkdir -p "$tmp_home/.codex"
global_agents="$tmp_home/.codex/AGENTS.md"

fail() { echo "$*" >&2; exit 1; }
assert_contains() { grep -Fq -- "$2" "$1" || fail "missing $2"; }
assert_not_contains() { ! grep -Fq -- "$2" "$1" || fail "unexpected $2"; }
assert_count() {
  [ "$(grep -Fc -- "$2" "$1")" -eq "$3" ] || fail "wrong count for $2"
}
assert_fails() { "$@" && fail "expected command to fail: $*"; }
run_install() {
  (cd "$tmp_target" && HOME="$tmp_home" bash "$ROOT/install.sh" \
    --codex-only --codex-global --skip-codex --skip-verify)
}
run_dry_install() {
  (cd "$tmp_target" && HOME="$tmp_home" bash "$ROOT/install.sh" \
    --codex-only --codex-global --dry-run --skip-codex --skip-verify)
}
run_fresh_dry_install() {
  (cd "$dry_target" && HOME="$dry_home" bash "$ROOT/install.sh" \
    --codex-only --codex-global --dry-run --skip-codex --skip-verify)
}

dry_before="$(find "$dry_home" -print | sort)"
run_fresh_dry_install >/dev/null
dry_after="$(find "$dry_home" -print | sort)"
[ "$dry_before" = "$dry_after" ] || fail "dry run mutated temporary HOME"
[ ! -e "$dry_home/.codex/skills" ] || fail "dry run created Codex skill directory"

printf '%s\n' '# Personal rules' \
  'Always use my preferred formatter.' \
  '<!-- j-stack:codex-global-policy:start version=0 -->' \
  'old managed content' \
  '<!-- j-stack:codex-global-policy:end -->' > "$global_agents"

run_install
assert_contains "$global_agents" "# Personal rules"
assert_contains "$global_agents" "Always use my preferred formatter."
assert_count "$global_agents" "j-stack:codex-global-policy:start" 1
assert_not_contains "$global_agents" "old managed content"
assert_contains "$global_agents" "j-stack:codex-global-policy:start version=1"

for skill in build-mode poc-wiki-init handoff-snapshot prior-art-survey stakeholder-pack adversarial-review; do
  [ -f "$tmp_home/.codex/skills/$skill/SKILL.md" ] || fail "missing $skill"
done
[ ! -e "$tmp_home/.codex/skills/second-opinion" ] || fail "Claude-only second-opinion copied"
assert_not_contains "$tmp_home/.codex/skills/adversarial-review/SKILL.md" "API key"
assert_not_contains "$tmp_home/.codex/skills/adversarial-review/SKILL.md" "claude"

first="$(cksum "$global_agents")"
run_install
[ "$first" = "$(cksum "$global_agents")" ] || fail "second install changed AGENTS.md"

# No-marker installation appends a single managed block.
: > "$global_agents"
run_install
assert_count "$global_agents" "j-stack:codex-global-policy:start" 1

# Existing mode bits survive an atomic replacement.
chmod 640 "$global_agents"
mode_before="$(stat -f '%Lp' "$global_agents")"
run_install
[ "$mode_before" = "$(stat -f '%Lp' "$global_agents")" ] || fail "mode bits changed"

printf '%s\n' '# Personal rules' \
  '<!-- j-stack:codex-global-policy:start version=1 -->' \
  'unclosed managed content' > "$global_agents"
before="$(cksum "$global_agents")"
assert_fails run_install
[ "$before" = "$(cksum "$global_agents")" ] || fail "malformed layout changed AGENTS.md"

printf '%s\n' '# Personal rules' \
  '<!-- j-stack:codex-global-policy:start version=0 -->' \
  'old managed content' \
  '<!-- j-stack:codex-global-policy:end -->' > "$global_agents"
printf '%s\n' '# Existing project instructions' > "$tmp_target/AGENTS.md"
project_before="$(cksum "$tmp_target/AGENTS.md")"
before="$(cksum "$global_agents")"
dry_output="$(run_dry_install)"
[ "$before" = "$(cksum "$global_agents")" ] || fail "dry run changed AGENTS.md"
[ "$project_before" = "$(cksum "$tmp_target/AGENTS.md")" ] || fail "dry run changed project AGENTS.md"
assert_contains <(printf '%s' "$dry_output") "---"
assert_contains <(printf '%s' "$dry_output") "+++"

assert_fails bash "$ROOT/install.sh" --dry-run

echo "codex global config tests passed"
