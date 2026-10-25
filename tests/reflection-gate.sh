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
echo "failure scan is incremental across turns"
python3 - "$W/t3.jsonl" 4 <<'PY'
import json,sys
with open(sys.argv[1],"w") as f:
    for i in range(int(sys.argv[2])): f.write(json.dumps({"type":"user","message":{"content":[{"type":"tool_result","is_error":True,"content":"x"}]}})+"\n")
PY
[ -z "$(gate "$(ev "$P" s3 ",\"transcript_path\":\"$W/t3.jsonl\"")")" ] && ok "4 failures: silent" || bad "fired early"
python3 - "$W/t3.jsonl" 3 <<'PY'
import json,sys
with open(sys.argv[1],"a") as f:
    for i in range(int(sys.argv[2])): f.write(json.dumps({"type":"user","message":{"content":[{"type":"tool_result","is_error":True,"content":"x"}]}})+"\n")
PY
gate "$(ev "$P" s3 ",\"transcript_path\":\"$W/t3.jsonl\"")" | grep -q "7 failed" && ok "4+3 across turns fires" || bad "incremental count wrong"
echo "metrics: measured from the transcript, deduped, windowed, with subagents"
M="${W}/mp"; mkdir -p "$M/.planning/reviews"; TR="${W}/m/sess1.jsonl"; mkdir -p "${W}/m/sess1/subagents"
python3 "$GATE" <<<"$(ev "$M" mx)"   # baseline
python3 - "$TR" "${W}/m/sess1/subagents" <<'PY'
import json,sys
tr,sub=sys.argv[1:3]
def a(f,mid,model,ts,i,o,cr,cw,blocks=1,tool=False):
    for _ in range(blocks):  # the harness logs one record per content block with the same usage
        content=[{"type":"tool_use","name":"Bash","id":"t"}] if tool else [{"type":"text","text":"x"}]
        f.write(json.dumps({"type":"assistant","timestamp":ts,"version":"9.9.9","message":{"id":mid,"model":model,"content":content,"usage":{"input_tokens":i,"output_tokens":o,"cache_read_input_tokens":cr,"cache_creation_input_tokens":cw}}})+"\n")
def u(f,ts,err=False):
    f.write(json.dumps({"type":"user","timestamp":ts,"message":{"content":[{"type":"tool_result","is_error":err,"content":"r"}]}})+"\n")
with open(tr,"w") as f:
    a(f,"m1","model-a","2026-10-25T10:00:00.000Z",10,100,1000,50,blocks=3,tool=True)  # 3 duplicate records, counted once
    u(f,"2026-10-25T10:00:30.000Z",err=True)
    a(f,"m2","model-a","2026-10-25T10:01:00.000Z",5,40,2000,0)
    a(f,"m3","model-b","2026-10-25T10:30:00.000Z",1,10,0,0)   # 29 min idle gap before this
with open(sub+"/agent-x.jsonl","w") as f:
    a(f,"s1","model-h","2026-10-25T10:00:10.000Z",2,3,0,7)
json.dump({"agentType":"general-purpose","description":"probe"},open(sub+"/agent-x.meta.json","w"))
PY
echo "r" > "$M/.planning/reviews/qa-m.md"
OUT="$(gate "$(ev "$M" sess1 ",\"transcript_path\":\"$TR\"")")"
python3 - "$M/.planning/metrics.jsonl" "$OUT" <<'PY' && ok "first window numbers exact" || bad "first window wrong"
import json,sys
r=[json.loads(l) for l in open(sys.argv[1])]; assert len(r)==1, r
m=r[0]; a=m["main_tokens"]["model-a"]; b=m["main_tokens"]["model-b"]
assert (a["in"],a["out"],a["cache_read"],a["cache_write"],a["calls"])==(15,140,3000,50,2), a   # dupes counted once
assert (b["out"],b["calls"])==(10,1)
assert m["subagent_tokens"]["model-h"]["out"]==3 and m["subagents"][0]["type"]=="general-purpose"
assert m["tool_calls"]==1 and m["tool_errors"]==1, (m["tool_calls"],m["tool_errors"])
assert m["elapsed_s"]==1800 and m["active_s"]==60, (m["elapsed_s"],m["active_s"])   # idle 29 min not counted as active
assert m["claude_code_version"]=="9.9.9" and m["id"]=="M-sess1-1"
assert "M-sess1-1" in sys.argv[2] and "never estimate" in sys.argv[2]
PY
echo "metrics: next window only counts new records; SessionEnd flushes the rest quietly"
echo "agent done" >> "$M/.planning/reflections.md"; gate "$(ev "$M" sess1 ',"stop_hook_active":true')" >/dev/null
python3 - "$TR" <<'PY'
import json,sys
with open(sys.argv[1],"a") as f:
    f.write(json.dumps({"type":"assistant","timestamp":"2026-10-25T10:31:00.000Z","message":{"id":"m4","model":"model-b","content":[],"usage":{"input_tokens":1,"output_tokens":5}}})+"\n")
PY
SE="$(gate "$(ev "$M" sess1 ",\"hook_event_name\":\"SessionEnd\",\"transcript_path\":\"$TR\"")")"
[ -z "$SE" ] && ok "SessionEnd prints nothing" || bad "SessionEnd spoke"
python3 - "$M/.planning/metrics.jsonl" <<'PY' && ok "second record covers only new calls" || bad "window overlap"
import json,sys
r=[json.loads(l) for l in open(sys.argv[1])]; assert len(r)==2
assert r[1]["id"]=="M-sess1-2" and r[1]["items"]==["session end"] and r[1]["main_tokens"]["model-b"]["calls"]==1 and "model-a" not in r[1]["main_tokens"]
PY
gate "$(ev "$M" sess1 ",\"hook_event_name\":\"SessionEnd\",\"transcript_path\":\"$TR\"")" >/dev/null
[ "$(wc -l < "$M/.planning/metrics.jsonl")" = 2 ] && ok "no duplicate record when nothing new" || bad "duplicate metrics record"
echo "metrics.jsonl is not evidence (no refire)"
[ -z "$(gate "$(ev "$M" sess1)")" ] && ok silent || bad "fired on metrics change"
echo "garbage stdin never breaks the session"
echo "not json" | python3 "$GATE"; [ $? -eq 0 ] && ok "exit 0" || bad "non-zero exit"
echo; [ "$FAILS" = 0 ] && echo "All gate checks passed." || { echo "$FAILS failed"; exit 1; }
