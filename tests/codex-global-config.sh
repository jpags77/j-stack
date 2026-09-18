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

# Unknown flags fail closed before creating either global policy or skills.
unknown_home="$(mktemp -d)"
unknown_target="$(mktemp -d)"
(cd "$unknown_target" && HOME="$unknown_home" bash "$ROOT/install.sh" \
  --codex-only --codex-global --dryrun --skip-codex --skip-verify) && fail "unknown flag accepted"
[ ! -e "$unknown_home/.codex/AGENTS.md" ] || fail "unknown flag created global policy"
[ ! -e "$unknown_home/.codex/skills" ] || fail "unknown flag created Codex skills"
rm -rf "$unknown_home" "$unknown_target"

printf '%s\n' '# Personal rules' \
  'Always use my preferred formatter.' \
  '<!-- j-stack:codex-global-policy:start version=0 -->' \
  'old managed content' \
  '<!-- j-stack:codex-global-policy:end -->' > "$global_agents"

before="$(cksum "$global_agents")"
assert_fails run_install
[ "$before" = "$(cksum "$global_agents")" ] || fail "unsupported marker version changed AGENTS.md"
assert_contains "$global_agents" "version=0"

printf '%s\n' '# Personal rules' \
  'Always use my preferred formatter.' \
  '<!-- j-stack:codex-global-policy:start version=1 -->' \
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

# Every marker-prefix line must be exact; malformed end syntax and duplicate pairs fail.
printf '%s\n' '<!-- j-stack:codex-global-policy:end extra -->' > "$global_agents"
before="$(cksum "$global_agents")"
assert_fails run_install
[ "$before" = "$(cksum "$global_agents")" ] || fail "malformed end marker changed AGENTS.md"

printf '%s\n' '<!-- j-stack:codex-global-policy:start version=1 -->' \
  '<!-- j-stack:codex-global-policy:start version=1 -->' \
  '<!-- j-stack:codex-global-policy:end -->' > "$global_agents"
before="$(cksum "$global_agents")"
assert_fails run_install
[ "$before" = "$(cksum "$global_agents")" ] || fail "duplicate markers changed AGENTS.md"

# CRLF in unrelated content is preserved byte-for-byte.
printf '# Personal rules\r\nKeep CRLF\r\n' > "$global_agents"
run_install
python3 - "$global_agents" <<'PY'
import sys
data = open(sys.argv[1], 'rb').read()
assert b'# Personal rules\r\nKeep CRLF\r\n' in data
PY

# A symlinked global policy is never replaced.
symlink_target="$tmp_home/.codex/real-AGENTS.md"
printf '%s\n' '# preserve me' > "$symlink_target"
rm -f "$global_agents"
ln -s "$symlink_target" "$global_agents"
before="$(cksum "$symlink_target")"
assert_fails run_install
[ -L "$global_agents" ] || fail "symlink was replaced"
[ "$before" = "$(cksum "$symlink_target")" ] || fail "symlink target changed"
rm "$global_agents"

# Reinstall removes stale files from an allowlisted Codex skill directory.
run_install
printf '%s\n' stale > "$tmp_home/.codex/skills/build-mode/stale.md"
run_install
[ ! -e "$tmp_home/.codex/skills/build-mode/stale.md" ] || fail "stale managed skill file survived reinstall"

printf '%s\n' '# Personal rules' \
  '<!-- j-stack:codex-global-policy:start version=1 -->' \
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
