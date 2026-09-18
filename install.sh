#!/usr/bin/env bash
# j-stack install script
# Sets up the j-stack enterprise PoC workflow:
#   Superpowers + cherry-picked gstack skills + 5 custom skills + prior-art bundle
#   + Claude CLAUDE.md lane config + Codex AGENTS.md runtime config
#   + Claude SessionStart hook
#
# Usage: bash install.sh [--codex-only] [--codex-global] [--dry-run] [--skip-codex] [--skip-verify] [--update]

set -euo pipefail

SKIP_CODEX=false
SKIP_VERIFY=false
UPDATE_GSTACK=false
CODEX_ONLY=false
CODEX_GLOBAL=false
DRY_RUN=false
CODEX_SKILLS=(build-mode poc-wiki-init handoff-snapshot prior-art-survey stakeholder-pack adversarial-review)
for arg in "$@"; do
  case $arg in
    --codex-only)  CODEX_ONLY=true ;;
    --codex-global) CODEX_GLOBAL=true ;;
    --dry-run)     DRY_RUN=true ;;
    --skip-codex)  SKIP_CODEX=true ;;
    --skip-verify) SKIP_VERIFY=true ;;
    --update)      UPDATE_GSTACK=true ;;
    *)             echo "[error] Unknown option: ${arg}" >&2; exit 1 ;;
  esac
done

RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; NC='\033[0m'
info()  { echo -e "${GREEN}[j-stack]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*" >&2; }
halt()  { error "$*"; exit 1; }

if [ "$DRY_RUN" = true ] && { [ "$CODEX_ONLY" = false ] || [ "$CODEX_GLOBAL" = false ]; }; then
  halt "--dry-run requires both --codex-only and --codex-global."
fi

SKILLS_DIR="${HOME}/.claude/skills"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Phase 0: Prerequisites ───────────────────────────────────────────────────

info "Checking prerequisites…"

command -v git    &>/dev/null || halt "git not found."
command -v bash   &>/dev/null || halt "bash not found."

if [ "$CODEX_ONLY" = false ]; then
  command -v claude &>/dev/null || halt "claude not found. Install Claude Code first: https://claude.ai/code"

  # Check Superpowers plugin — claude --help doesn't enumerate installed
  # plugins, so check the plugin cache directory directly instead.
  if ! find "${HOME}/.claude/plugins" -maxdepth 2 -iname "*superpowers*" 2>/dev/null | grep -q .; then
    warn "Superpowers plugin not detected under ~/.claude/plugins/."
    warn "Install it inside Claude Code with:"
    warn "  /plugin marketplace add obra/superpowers-marketplace"
    warn "  /plugin install superpowers@superpowers-marketplace"
    read -rp "Continue anyway? [y/N] " yn
    [[ $yn =~ ^[Yy]$ ]] || halt "Aborted. Install Superpowers first."
  fi
else
  info "Codex-only mode: skipping Claude CLI, plugin, skill, agent, and hook installation."
fi

# prior-art survey skill + scout agents are bundled in this repo — installed in Phase 2.5 below

# ─── Phase 0.5: Codex CLI ─────────────────────────────────────────────────────

if [ "$SKIP_CODEX" = false ] && [ "$CODEX_GLOBAL" = false ]; then
  info "Phase 0 — Codex CLI setup…"
  if command -v codex &>/dev/null; then
    CODEX_VER=$(codex --version 2>/dev/null || echo "unknown")
    info "Codex CLI already installed: ${CODEX_VER}"
  else
    warn "Codex CLI not found."
    warn "The second-opinion skill requires it. Install it per current OpenAI docs:"
    warn "  https://github.com/openai/codex  (verify current install method)"
    warn "Typical install: npm install -g @openai/codex"
    read -rp "Skip Codex CLI setup and continue? [y/N] " yn
    [[ $yn =~ ^[Yy]$ ]] || halt "Aborted. Install Codex CLI, then re-run install.sh."
  fi
fi

if [ "$CODEX_ONLY" = false ]; then

# ─── Phase 1: Cherry-pick gstack skills ───────────────────────────────────────

info "Phase 1 — Cherry-picking gstack skills…"

GSTACK_SCRATCH="/tmp/gstack-source"
# Pinned to a known-good commit (gstack v1.60.1.0, 2026-07-10) so upstream
# changes can't silently break the skill-folder list below. To pick up
# newer gstack releases: run install.sh --update, verify the result, then
# bump this SHA in a commit of its own.
GSTACK_PIN="7c9df1c568a9ea745508f679a329332b2c338063"

if [ "$UPDATE_GSTACK" = true ]; then
  rm -rf "$GSTACK_SCRATCH"
fi

if [ -d "$GSTACK_SCRATCH" ]; then
  info "Reusing existing gstack clone at ${GSTACK_SCRATCH}…"
else
  info "Cloning gstack (pinned ${GSTACK_PIN:0:12})…"
  git clone --quiet https://github.com/garrytan/gstack.git "$GSTACK_SCRATCH"
fi

if ! git -C "$GSTACK_SCRATCH" checkout --quiet "$GSTACK_PIN"; then
  halt "gstack pin ${GSTACK_PIN} not found in ${GSTACK_SCRATCH}. Run install.sh --update, then update GSTACK_PIN if needed."
fi
info "Using gstack pin ${GSTACK_PIN:0:12}."

if [ "$UPDATE_GSTACK" = true ]; then
  latest="$(git -C "$GSTACK_SCRATCH" rev-parse origin/HEAD 2>/dev/null || git -C "$GSTACK_SCRATCH" rev-parse origin/main)"
  warn "install.sh --update fetched gstack, but GSTACK_PIN is still ${GSTACK_PIN:0:12}. Latest is ${latest:0:12} — review the diff, then update GSTACK_PIN by hand and commit."
fi

GSTACK_SKILLS=(cso office-hours plan-ceo-review qa design-shotgun design-html design-review codex document-release freeze guard)

missing=()
for skill in "${GSTACK_SKILLS[@]}"; do
  [ -d "${GSTACK_SCRATCH}/${skill}" ] || missing+=("$skill")
done
if [ ${#missing[@]} -gt 0 ]; then
  halt "Missing gstack skill folders: ${missing[*]}. gstack repo may have changed. Check and update install.sh."
fi

mkdir -p "$SKILLS_DIR"

get_gstack_model() {
  case "$1" in
    cso)             echo opus ;;
    office-hours)    echo opus ;;
    plan-ceo-review) echo opus ;;
    qa)              echo sonnet ;;
    design-shotgun)  echo sonnet ;;
    design-html)     echo sonnet ;;
    design-review)   echo sonnet ;;
    codex)           echo sonnet ;;
    document-release) echo sonnet ;;
    freeze)          echo haiku ;;
    guard)           echo haiku ;;
    *)               echo sonnet ;;
  esac
}

for skill in "${GSTACK_SKILLS[@]}"; do
  dest="${SKILLS_DIR}/${skill}"
  cp -r "${GSTACK_SCRATCH}/${skill}" "${SKILLS_DIR}/"
  model="$(get_gstack_model "$skill")"

  # Find the main skill entry file
  entry=""
  for candidate in "${dest}/SKILL.md" "${dest}/skill.md" "${dest}/README.md"; do
    [ -f "$candidate" ] && entry="$candidate" && break
  done

  if [ -z "$entry" ]; then
    warn "Could not find entry file for gstack/${skill} — skipping model injection"
    continue
  fi

  # Inject model: directive into YAML frontmatter if not already present
  if head -1 "$entry" | grep -q "^---"; then
    if ! grep -q "^model:" "$entry"; then
      # Insert after opening ---
      sed -i.bak "1a\\
model: ${model}" "$entry"
      rm -f "${entry}.bak"
    fi
  else
    # No frontmatter — prepend it
    tmpfile=$(mktemp)
    printf -- "---\nmodel: %s\n---\n" "$model" | cat - "$entry" > "$tmpfile"
    mv "$tmpfile" "$entry"
  fi

  info "  Installed gstack/${skill} (model: ${model})"
done

# ─── Phase 2: Custom skills ────────────────────────────────────────────────────────────────────────────

info "Phase 2 — Installing custom skills…"
CUSTOM_SKILLS=(poc-wiki-init handoff-snapshot second-opinion stakeholder-pack build-mode)

for skill in "${CUSTOM_SKILLS[@]}"; do
  src="${SCRIPT_DIR}/skills/${skill}"
  if [ ! -d "$src" ]; then
    halt "Expected skills/${skill}/ not found in repo. Clone may be incomplete."
  fi
  cp -r "$src" "${SKILLS_DIR}/"
  info "  Installed custom skill: ${skill}"
done

# ─── Phase 2.5: Prior-art research skill + scout agents ───────────────────────

info "Phase 2.5 — Installing prior-art survey skill and scout agents…"

AGENTS_DIR="${HOME}/.claude/agents"

src="${SCRIPT_DIR}/skills/prior-art-survey"
if [ ! -d "$src" ]; then
  halt "Expected skills/prior-art-survey/ not found in repo. Clone may be incomplete."
fi
cp -r "$src" "${SKILLS_DIR}/"
info "  Installed skill: prior-art-survey"

# Scouts are agent definitions, not skills — the Agent tool honors their
# model: sonnet frontmatter, so research runs in the sonnet lane even when
# the orchestrating session is on opus.
mkdir -p "$AGENTS_DIR"
PRIOR_ART_AGENTS=(prior-art-oss-scout prior-art-library-scout prior-art-patterns-scout)

for agent in "${PRIOR_ART_AGENTS[@]}"; do
  src="${SCRIPT_DIR}/agents/${agent}.md"
  if [ ! -f "$src" ]; then
    halt "Expected agents/${agent}.md not found in repo. Clone may be incomplete."
  fi
  cp "$src" "${AGENTS_DIR}/"
  # Remove stale skill-form scout from older installs
  rm -rf "${SKILLS_DIR:?}/${agent}"
  info "  Installed agent: ${agent} (model: sonnet)"
done

# ─── Phase 3: CLAUDE.md configuration ────────────────────────────────────────

info "Phase 3 — Configuring project CLAUDE.md…"

# Sourced from templates/lane-doctrine.md — the single copy of this text.
# Edit that file, not this script, to change the shared doctrine.
CLAUDE_SECTION="$(cat "${SCRIPT_DIR}/templates/lane-doctrine.md")"

PROJECT_CLAUDE="${PWD}/CLAUDE.md"
if [ -f "$PROJECT_CLAUDE" ]; then
  if grep -q "Stack ownership" "$PROJECT_CLAUDE"; then
    info "  CLAUDE.md already contains stack ownership section — skipping"
  else
    printf '\n# Project Context\n\n%s\n' "$CLAUDE_SECTION" >> "$PROJECT_CLAUDE"
    info "  Appended stack ownership section to existing CLAUDE.md"
  fi
else
  printf '# Project Context\n\n%s\n' "$CLAUDE_SECTION" > "$PROJECT_CLAUDE"
  info "  Created CLAUDE.md with stack ownership section"
fi

fi

# ─── Phase 3.25: AGENTS.md configuration ──────────────────────────────────────

info "Phase 3.25 — Configuring project AGENTS.md…"

# Both composed from templates/ — the single copies of this text. Edit
# those files, not this script, to change the shared doctrine or the
# Codex-specific addendum.
LANE_DOCTRINE="$(cat "${SCRIPT_DIR}/templates/lane-doctrine.md")"
CODEX_ROLE="$(cat "${SCRIPT_DIR}/templates/codex-role.md")"
AGENTS_SECTION="${LANE_DOCTRINE}

${CODEX_ROLE}"
AGENTS_CODEX_APPEND="$CODEX_ROLE"

PROJECT_AGENTS="${PWD}/AGENTS.md"

# ─── Phase 3.2: Codex global policy ──────────────────────────────────────────

if [ "$CODEX_GLOBAL" = true ]; then
  info "Phase 3.2 — Configuring global Codex policy…"
  CODEX_GLOBAL_AGENTS="${HOME}/.codex/AGENTS.md"
  CODEX_GLOBAL_TEMPLATE="${SCRIPT_DIR}/templates/codex-global-policy.md"
  PYTHONDONTWRITEBYTECODE=1 python3 - "$CODEX_GLOBAL_AGENTS" "$CODEX_GLOBAL_TEMPLATE" "$DRY_RUN" <<'PYEOF'
import difflib
import os
import re
import shutil
import stat
import sys
import tempfile

path, template_path, dry_run = sys.argv[1], sys.argv[2], sys.argv[3] == "true"
start = "<!-- j-stack:codex-global-policy:start version=1 -->"
end = "<!-- j-stack:codex-global-policy:end -->"
marker_prefix = "<!-- j-stack:codex-global-policy:"
valid_start_re = re.compile(re.escape(start))

try:
    old = open(path, encoding="utf-8", newline="").read() if os.path.exists(path) else ""
    template = open(template_path, encoding="utf-8", newline="").read().rstrip("\r\n")
except OSError as exc:
    print(f"codex global policy: {exc}", file=sys.stderr)
    sys.exit(1)

lines = old.splitlines(keepends=True)
markers = []
for index, line in enumerate(lines):
    if marker_prefix in line:
        marker = line.strip()
        if marker != end and not valid_start_re.fullmatch(marker):
            print("codex global policy: malformed marker line; repair AGENTS.md manually", file=sys.stderr)
            sys.exit(1)
        markers.append((index, marker))

starts = [index for index, marker in markers if marker == start]
ends = [index for index, marker in markers if marker == end]
if len(starts) > 1 or len(ends) > 1 or len(starts) != len(ends) or (starts and starts[0] >= ends[0]):
    print("codex global policy: malformed marker layout; expected one ordered marker pair", file=sys.stderr)
    sys.exit(1)

line_ending = "\r\n" if "\r\n" in old else "\n"
template = template.replace("\r\n", "\n").replace("\n", line_ending)
block = f"{start}{line_ending}{template}{line_ending}{end}{line_ending}"
if not starts:
    prefix = old if not old or old.endswith(("\n", "\r")) else old + line_ending
    new = prefix + block
else:
    new = "".join(lines[:starts[0]]) + block + "".join(lines[ends[0] + 1:])

if dry_run:
    sys.stdout.writelines(difflib.unified_diff(old.splitlines(keepends=True), new.splitlines(keepends=True),
                                               fromfile=path, tofile=path))
    sys.exit(0)

mode = stat.S_IMODE(os.stat(path).st_mode) if os.path.exists(path) else 0o644
directory = os.path.dirname(path) or "."
if os.path.lexists(path) and os.path.islink(path):
    print("codex global policy: refusing to replace symlinked AGENTS.md; repair the symlink and rerun", file=sys.stderr)
    sys.exit(1)
os.makedirs(directory, exist_ok=True)
fd, temporary = tempfile.mkstemp(prefix=".codex-global-policy.", dir=directory)
try:
    os.fchmod(fd, mode)
    with os.fdopen(fd, "w", encoding="utf-8", newline="") as output:
        output.write(new)
    if os.path.exists(path):
        shutil.copystat(path, temporary, follow_symlinks=False)
    os.replace(temporary, path)
except Exception:
    try:
        os.unlink(temporary)
    except OSError:
        pass
    raise
print(f"codex global policy: {'updated' if starts else 'installed'} {path}")
PYEOF

fi

if [ "$DRY_RUN" = true ]; then
  exit 0
fi

if [ "$CODEX_GLOBAL" = true ]; then
  CODEX_SKILLS_DIR="${HOME}/.codex/skills"
  for skill in "${CODEX_SKILLS[@]}"; do
    src="${SCRIPT_DIR}/skills/codex/${skill}"
    if [ ! -d "$src" ]; then
      halt "Expected skills/codex/${skill}/ not found in repo. Clone may be incomplete."
    fi
  done
  mkdir -p "$CODEX_SKILLS_DIR"
  for skill in "${CODEX_SKILLS[@]}"; do
    target="${CODEX_SKILLS_DIR}/${skill}"
    case "$target" in
      "${CODEX_SKILLS_DIR}"/*) ;;
      *) halt "Refusing to remove Codex skill outside allowlisted directory: ${target}" ;;
    esac
    rm -rf -- "$target"
    cp -r "${SCRIPT_DIR}/skills/codex/${skill}" "$CODEX_SKILLS_DIR/"
    info "  Installed Codex skill: ${skill}"
  done
fi

if [ -f "$PROJECT_AGENTS" ]; then
  if grep -q "Codex role" "$PROJECT_AGENTS"; then
    info "  AGENTS.md already contains Codex lane configuration — skipping"
  elif grep -q "Stack ownership" "$PROJECT_AGENTS"; then
    printf '\n%s\n' "$AGENTS_CODEX_APPEND" >> "$PROJECT_AGENTS"
    info "  Appended Codex lane configuration to existing AGENTS.md"
  else
    printf '\n# Project Context\n\n%s\n' "$AGENTS_SECTION" >> "$PROJECT_AGENTS"
    info "  Appended j-stack section to existing AGENTS.md"
  fi
else
  printf '# Project Context\n\n%s\n' "$AGENTS_SECTION" > "$PROJECT_AGENTS"
  info "  Created AGENTS.md with Codex lane configuration"
fi

if [ "$CODEX_ONLY" = false ]; then

# ─── Phase 3.6: SessionStart hook ─────────────────────────────────────────────

info "Phase 3.6 — Installing SessionStart hook…"

# The hook is a gating script: it stays silent unless the project has a .planning/
# wiki, so Q&A and one-off sessions pay no context cost.
mkdir -p "${HOME}/.claude/hooks"
cp "${SCRIPT_DIR}/hooks/build-mode-gate.sh" "${HOME}/.claude/hooks/build-mode-gate.sh"
chmod +x "${HOME}/.claude/hooks/build-mode-gate.sh"
info "  ✓ hooks/build-mode-gate.sh"

SETTINGS_JSON="${HOME}/.claude/settings.json"
HOOK_MARKER="build-mode-gate.sh"

write_session_hook() {
  python3 - "$SETTINGS_JSON" <<'PYEOF'
import json, os, sys

path = sys.argv[1]
marker = "build-mode-gate.sh"
command = os.path.expanduser("~/.claude/hooks/build-mode-gate.sh")
entry = {"hooks": [{"type": "command", "command": command,
                    "statusMessage": "Checking for j-stack engagement..."}]}

data = {}
if os.path.exists(path):
    try:
        with open(path) as f:
            data = json.load(f)
    except Exception:
        print("PARSE_ERROR")
        sys.exit(3)

hooks = data.setdefault("hooks", {})
sessions = hooks.setdefault("SessionStart", [])
if marker in json.dumps(sessions):
    print("ALREADY")
    sys.exit(0)
sessions.append(entry)
os.makedirs(os.path.dirname(path), exist_ok=True)
with open(path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
print("WROTE")
PYEOF
}

if grep -q "$HOOK_MARKER" "$SETTINGS_JSON" 2>/dev/null; then
  info "  SessionStart hook already present — skipping"
elif command -v python3 &>/dev/null; then
  result="$(write_session_hook)"
  case "$result" in
    WROTE)   info "  ✓ SessionStart hook written to ${SETTINGS_JSON}" ;;
    ALREADY) info "  SessionStart hook already present — skipping" ;;
    *)
      warn "  Could not auto-merge ${SETTINGS_JSON} (invalid JSON or write error)."
      warn "  Add the SessionStart hook manually — see README 'Manual hook setup'."
      ;;
  esac
else
  warn "  python3 not found — cannot safely merge ${SETTINGS_JSON}."
  warn "  Add the SessionStart hook manually — see README 'Manual hook setup'."
fi

fi

# ─── Phase 4: Verification ────────────────────────────────────────────────────

if [ "$SKIP_VERIFY" = false ]; then
  info "Phase 4 — Verification…"

  all_ok=true

  if grep -q "Codex role" "$PROJECT_AGENTS" 2>/dev/null; then
    info "  ✓ AGENTS.md Codex runtime config"
  else
    error "  ✗ AGENTS.md missing Codex runtime config"
    all_ok=false
  fi

  if [ "$CODEX_ONLY" = false ]; then
    # Check all skills exist
    ALL_SKILLS=("${GSTACK_SKILLS[@]}" poc-wiki-init handoff-snapshot second-opinion stakeholder-pack build-mode prior-art-survey)
    for skill in "${ALL_SKILLS[@]}"; do
      if [ -d "${SKILLS_DIR}/${skill}" ]; then
        info "  ✓ ${skill}"
      else
        error "  ✗ ${skill} — missing from ${SKILLS_DIR}"
        all_ok=false
      fi
    done

    # Check scout agent definitions exist
    for agent in "${PRIOR_ART_AGENTS[@]}"; do
      if [ -f "${AGENTS_DIR}/${agent}.md" ]; then
        info "  ✓ agent: ${agent}"
      else
        error "  ✗ agent: ${agent} — missing from ${AGENTS_DIR}"
        all_ok=false
      fi
    done
  fi

  # Check codex if not skipped
  if [ "$SKIP_CODEX" = false ]; then
    if command -v codex &>/dev/null; then
      info "  ✓ codex CLI"
    else
      if [ "$CODEX_ONLY" = true ]; then
        error "  ✗ codex CLI not found"
        all_ok=false
      else
        warn "  ✗ codex CLI not found — second-opinion skill will not work until installed"
      fi
    fi
  fi

  if [ "$all_ok" = true ]; then
    info "All checks passed."
  else
    error "Some checks failed. See above."
    exit 1
  fi
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN} j-stack installation complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Next steps:"
if [ "$CODEX_ONLY" = true ]; then
  echo "  1. Open Codex in your project directory"
  echo "  2. Codex reads AGENTS.md plus .planning/index.md, .planning/log.md,"
  echo "     and the latest .planning/handoffs/ snapshot"
  echo "  3. Continue the current phase directly using the Codex behavior mapping"
  echo "  4. Keep .planning/ and local commits as the durable handoff surface"
else
  echo "  1. Open a new Claude Code session in your project directory"
  echo "  2. build-mode fires automatically (SessionStart hook) for projects that"
  echo "     already have .planning/; run /build-mode by hand to start a new one"
  echo "  3. It dispatches to /office-hours to begin EXPAND (founder-lens scoping)"
  echo "  4. Follow the pipeline in the build-mode skill"
fi
echo ""
echo "Each session: build-mode → confirm fidelity → confirm phase → do work → handoff-snapshot (if switching tools)"
echo "Pipeline:     EXPAND → REFINE → SURVEY → PLAN → BUILD → POLISH → DEFEND → HANDOFF"
echo ""
