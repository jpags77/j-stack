#!/usr/bin/env bash
# Deterministic tests for hooks/reflection-gate.py (no model calls).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GATE="${ROOT}/hooks/reflection-gate.py"
W="$(mktemp -d)"; export J_STACK_STATE_DIR="${W}/state"
FAILS=0
ok()  { echo "  ✓ $*"; }
bad() { echo "  ✗ $*" >&2; FAILS=$((FAILS+1)); }
gate() { python3 "$GATE" <<<"$1"; }   # $1 = stdin JSON
ev() { printf '{"cwd":"%s","session_id":"%s"%s}' "$1" "${2:-s1}" "${3:-}"; }
P="${W}/proj"; mkdir -p "$P/.planning/reviews" "$P/.planning/handoffs"
echo "old review" > "$P/.planning/reviews/qa-old.md"

echo "outside a wiki project: silent"
mkdir -p "${W}/plain"; [ -z "$(gate "$(ev "${W}/plain")")" ] && ok silent || bad "spoke outside .planning project"
echo "first run baselines existing history, no ingestion"
[ -z "$(gate "$(ev "$P")")" ] && ok silent || bad "fired on pre-existing history"
echo "no new evidence: silent"
[ -z "$(gate "$(ev "$P")")" ] && ok silent || bad "fired with nothing new"
echo "reflections/log/index edits are not evidence (no recursion)"
echo x > "$P/.planning/reflections.md"; echo x > "$P/.planning/log.md"
[ -z "$(gate "$(ev "$P")")" ] && ok silent || bad "fired on reflections/log change"
echo "new review: blocks once, naming the file"
echo "new review" > "$P/.planning/reviews/qa-new.md"
OUT="$(gate "$(ev "$P")")"
echo "$OUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["decision"]=="block" and "qa-new.md" in d["reason"] and "project-reflection" in d["reason"]' && ok "block + reason" || bad "no block: $OUT"
echo "agent complied (reflections.md changed): verified, then silent"
echo "entry" >> "$P/.planning/reflections.md"
[ -z "$(gate "$(ev "$P" s1 ',"stop_hook_active":true')")" ] && ok "accepted" || bad "re-prompted despite compliance"
[ -z "$(gate "$(ev "$P")")" ] && ok "same evidence never refires" || bad "refired on same evidence"
echo "agent says nothing learned: sentinel accepted"
echo "handoff" > "$P/.planning/handoffs/h1.md"; gate "$(ev "$P")" >/dev/null
[ -z "$(gate "$(ev "$P" s1 ',"stop_hook_active":true,"last_assistant_message":"Checked. NO_REFLECTION_NEEDED"')")" ] && ok "accepted" || bad "sentinel rejected"
echo "agent ignores it: one re-prompt, then released and recorded"
echo "handoff 2" > "$P/.planning/handoffs/h2.md"; gate "$(ev "$P")" >/dev/null
R1="$(gate "$(ev "$P" s1 ',"stop_hook_active":true,"last_assistant_message":"done"')")"
echo "$R1" | grep -q '"block"' && ok "re-prompted once" || bad "no re-prompt"
R2="$(gate "$(ev "$P" s1 ',"stop_hook_active":true,"last_assistant_message":"done"')")"
[ -z "$R2" ] && ok "released after retry (no infinite loop)" || bad "looped"
grep -q '"missed": \[' "$J_STACK_STATE_DIR"/*.json && python3 -c 'import json,glob; assert json.load(open(glob.glob("'"$J_STACK_STATE_DIR"'/*.json")[0]))["missed"]' && ok "miss recorded" || bad "miss not recorded"
echo "hard-failure proxy: many failed tool calls in one session fires once"
python3 - "$W/t.jsonl" <<'PY'
import json,sys
with open(sys.argv[1],"w") as f:
    for i in range(7):
        f.write(json.dumps({"type":"user","message":{"content":[{"type":"tool_result","is_error":True,"content":"boom"}]}})+"\n")
PY
T="$(gate "$(ev "$P" s2 ",\"transcript_path\":\"$W/t.jsonl\"")")"
echo "$T" | grep -q "failed tool calls" && ok "fired on struggle" || bad "no struggle trigger: $T"
echo "x" >> "$P/.planning/reflections.md"; gate "$(ev "$P" s2 ',"stop_hook_active":true')" >/dev/null
[ -z "$(gate "$(ev "$P" s2 ",\"transcript_path\":\"$W/t.jsonl\"")")" ] && ok "once per session" || bad "struggle refired"
echo "garbage stdin never breaks the session"
echo "not json" | python3 "$GATE"; [ $? -eq 0 ] && ok "exit 0" || bad "non-zero exit"
echo; [ "$FAILS" = 0 ] && echo "All gate checks passed." || { echo "$FAILS failed"; exit 1; }
