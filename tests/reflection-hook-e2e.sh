#!/usr/bin/env bash
# Opt-in end-to-end check of the reflection-gate Stop hook inside a real
# headless Claude Code session. Spends model calls; model output varies.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
W="$(mktemp -d)"; export J_STACK_STATE_DIR="${W}/state"
FAILS=0; ok(){ echo "  ✓ $*"; }; bad(){ echo "  ✗ $*" >&2; FAILS=$((FAILS+1)); }
command -v claude >/dev/null || { echo "claude CLI not found" >&2; exit 2; }

P="${W}/proj"; mkdir -p "$P/.planning/reviews" "$P/.claude/skills"
cp -r "${ROOT}/skills/project-reflection" "$P/.claude/skills/"
printf '# Index\n' > "$P/.planning/index.md"; printf '# Activity Log\n' > "$P/.planning/log.md"
( cd "$P" && git init -q && git add -A && git commit -qm init )
cat > "${W}/settings.json" <<JSON
{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"J_STACK_STATE_DIR=${J_STACK_STATE_DIR} python3 ${ROOT}/hooks/reflection-gate.py"}]}],
"SessionEnd":[{"hooks":[{"type":"command","timeout":30,"command":"J_STACK_STATE_DIR=${J_STACK_STATE_DIR} python3 ${ROOT}/hooks/reflection-gate.py"}]}]}}
JSON
run() { ( cd "$P" && timeout 300 claude -p "$1" --settings "${W}/settings.json" --permission-mode acceptEdits \
   --allowedTools "Read Edit Write Bash(git:*) Skill" --output-format stream-json --verbose < /dev/null > "$2" 2>/dev/null ); }

echo '{"cwd":"'"$P"'","session_id":"base"}' | python3 "${ROOT}/hooks/reflection-gate.py"   # baseline

echo "control: ordinary turn, no checkpoint evidence"
run "Reply with the single word OK." "${W}/c.jsonl"
grep -q "j-stack checkpoint" "${W}/c.jsonl" && bad "hook fired on a plain turn" || ok "hook silent"
[ ! -f "$P/.planning/reflections.md" ] && ok "no reflections.md" || bad "reflections.md created"

echo "checkpoint: a QA review file appears"
run "Write .planning/reviews/qa-2026-10-25.md saying: test_export failed 3/3 after test_import; reproduced by running the pair alone; both write tmp/fixture.db; giving each test its own temp dir made the pair pass 10/10 runs (commit abc1234). Then stop." "${W}/t.jsonl"
grep -q "j-stack checkpoint" "${W}/t.jsonl" && ok "hook injected the instruction" || bad "hook did not fire"
if [ -f "$P/.planning/reflections.md" ] && grep -q '^## R-' "$P/.planning/reflections.md"; then ok "reflection entry written"
elif grep -q "NO_REFLECTION_NEEDED" "${W}/t.jsonl"; then ok "agent looked and answered NO_REFLECTION_NEEDED"
else bad "neither an entry nor the sentinel"; fi
python3 - <<PY && ok "pending cleared, nothing missed" || bad "state shows pending/missed"
import json,glob
d=json.load(open(glob.glob("${J_STACK_STATE_DIR}/*.json")[0])); assert d["pending"] is None and not d["missed"], d
PY

echo "metrics: measured record written at the checkpoint and shown to the agent"
grep -q "Measured by the hook" "${W}/t.jsonl" && ok "figures quoted in the instruction" || bad "no figures in instruction"
python3 - "$P/.planning/metrics.jsonl" <<'PY' && ok "metrics.jsonl has a positive, well-formed record" || bad "bad metrics record"
import json,sys
r=[json.loads(l) for l in open(sys.argv[1])]
m=next(x for x in r if any("qa-2026-10-25" in i for i in x["items"]))   # SessionEnd also records after each run
tok=sum(v["out"] for v in m["main_tokens"].values()); assert tok>0 and m["tool_calls"]>=1 and m["elapsed_s"]>=0 and m["claude_code_version"]
PY
python3 - "$P/.planning/metrics.jsonl" <<'PY' && ok "SessionEnd flushed a later record" || echo "  (note: no SessionEnd record; headless mode may not run SessionEnd hooks)"
import json,sys
assert any(json.loads(l)["items"]==["session end"] for l in open(sys.argv[1]))
PY

echo "repeat: same evidence, new turn"
H="$(sha256sum "$P/.planning/reflections.md" 2>/dev/null)"
run "Reply with the single word OK." "${W}/r.jsonl"
grep -q "j-stack checkpoint" "${W}/r.jsonl" && bad "refired on old evidence" || ok "silent"
echo; [ "$FAILS" = 0 ] && echo "E2E passed. Work dir: $W" || { echo "$FAILS failed. Inspect $W"; exit 1; }
