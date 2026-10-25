#!/usr/bin/env python3
"""j-stack reflection gate: a deterministic, model-free Stop hook.

Runs on every Stop but costs milliseconds and stays silent unless a checkpoint
actually happened since it last looked:
  - a review or handoff file under .planning/ is new or changed, or
  - the session has had many failed tool calls (a rough "hard failure" proxy).
When it fires it blocks the stop once and tells the agent to run
project-reflection on that evidence. On the follow-up Stop it checks the agent
complied (reflections.md changed, or the agent answered NO_REFLECTION_NEEDED),
re-prompts once if not, then records a miss and lets go. It never loops.

It also measures the session (tokens by model, subagents, tool calls, time)
straight from the transcript and appends one record per checkpoint, plus one at
session end, to .planning/metrics.jsonl. The model only interprets these
numbers; it never produces them.

State lives outside the repo (per machine): $J_STACK_STATE_DIR or
~/.j-stack/reflection-state/. The first run in a project only records a
baseline, so existing history is never ingested automatically.
"""
import glob
import hashlib
import json
import os
import sys

SENTINEL = "NO_REFLECTION_NEEDED"
STRUGGLE_THRESHOLD = int(os.environ.get("J_STACK_STRUGGLE_THRESHOLD", "6"))
EVIDENCE_DIRS = ("reviews", "handoffs")
IDLE_GAP_S = 300  # gaps longer than this between records are not counted as active time


def sha(path):
    try:
        with open(path, "rb") as f:
            return hashlib.sha256(f.read()).hexdigest()
    except OSError:
        return None


def find_root(start):
    d = os.path.abspath(start)
    while True:
        if os.path.isdir(os.path.join(d, ".planning")):
            return d
        parent = os.path.dirname(d)
        if parent == d:
            return None
        d = parent


def evidence(root):
    found = {}
    for sub in EVIDENCE_DIRS:
        base = os.path.join(root, ".planning", sub)
        if not os.path.isdir(base):
            continue
        for name in sorted(os.listdir(base)):
            if name.endswith(".md"):
                h = sha(os.path.join(base, name))
                if h:
                    found[f".planning/{sub}/{name}"] = h
    return found


def failed_tool_calls(transcript, offset=0):
    """Count failed tool results after byte `offset`. Returns (count, new_offset); only whole lines are consumed."""
    n = 0
    try:
        size = os.path.getsize(transcript)
        if offset > size:
            offset = 0
        with open(transcript, "rb") as f:
            f.seek(offset)
            for line in f:
                if not line.endswith(b"\n"):
                    break
                offset += len(line)
                if b'"is_error"' not in line:
                    continue
                try:
                    content = json.loads(line).get("message", {}).get("content")
                except ValueError:
                    continue
                if isinstance(content, list):
                    n += sum(1 for b in content if isinstance(b, dict)
                             and b.get("type") == "tool_result" and b.get("is_error") is True)
    except OSError:
        pass
    return n, offset


def _records(path):
    try:
        with open(path) as f:
            for line in f:
                try:
                    yield json.loads(line)
                except ValueError:
                    continue
    except OSError:
        return


def _secs(a, b):
    from datetime import datetime
    f = lambda t: datetime.fromisoformat(t.replace("Z", "+00:00"))
    return (f(b) - f(a)).total_seconds()


def _tally(path, after):
    """Dedupe assistant usage by message id (one API call is logged once per content block)."""
    calls, tool_ids, errors, stamps, version = {}, set(), 0, [], None
    for o in _records(path):
        ts = o.get("timestamp")
        if not ts or (after and ts <= after):
            continue
        stamps.append(ts)
        version = o.get("version") or version
        msg = o.get("message") or {}
        if o.get("type") == "assistant" and msg.get("id") and msg.get("model") != "<synthetic>":
            calls[msg["id"]] = (msg.get("model"), msg.get("usage") or {})
            if isinstance(msg.get("content"), list):
                tool_ids.update(b.get("id") for b in msg["content"] if isinstance(b, dict) and b.get("type") == "tool_use")
        elif o.get("type") == "user" and isinstance(msg.get("content"), list):
            errors += sum(1 for b in msg["content"] if isinstance(b, dict)
                          and b.get("type") == "tool_result" and b.get("is_error") is True)
    return calls, len(tool_ids), errors, stamps, version


def _add(tokens, calls):
    for model, u in calls.values():
        t = tokens.setdefault(model or "unknown", {"in": 0, "out": 0, "cache_read": 0, "cache_write": 0, "calls": 0})
        t["in"] += u.get("input_tokens", 0) or 0
        t["out"] += u.get("output_tokens", 0) or 0
        t["cache_read"] += u.get("cache_read_input_tokens", 0) or 0
        t["cache_write"] += u.get("cache_creation_input_tokens", 0) or 0
        t["calls"] += 1


def measure(transcript, after):
    """Measured figures for everything after timestamp `after`. Returns None if nothing new."""
    calls, tools, errors, stamps, version = _tally(transcript, after)
    if not calls:
        return None
    main_tokens, sub_tokens, subagents = {}, {}, []
    _add(main_tokens, calls)
    for path in sorted(glob.glob(os.path.splitext(transcript)[0] + "/subagents/*.jsonl")):
        c, t, e, st, _ = _tally(path, after)
        if not c:
            continue
        tools, errors = tools + t, errors + e
        _add(sub_tokens, c)
        try:
            with open(path[:-len(".jsonl")] + ".meta.json") as f:
                meta = json.load(f)
        except (OSError, ValueError):
            meta = {}
        sub_only = {}
        _add(sub_only, c)
        subagents.append({"type": meta.get("agentType"), "model": next(iter(sub_only)),
                          "description": (meta.get("description") or "")[:60], "api_calls": len(c),
                          "tokens": sum(v["in"] + v["out"] + v["cache_read"] + v["cache_write"] for v in sub_only.values()),
                          "seconds": round(_secs(min(st), max(st)))})
    active = sum(g for g in (_secs(a, b) for a, b in zip(sorted(stamps), sorted(stamps)[1:])) if g <= IDLE_GAP_S)
    return {"window_start": min(stamps), "window_end": max(stamps),
            "elapsed_s": round(_secs(min(stamps), max(stamps))), "active_s": round(active),
            "main_tokens": main_tokens, "subagent_tokens": sub_tokens, "subagents": subagents,
            "tool_calls": tools, "tool_errors": errors, "claude_code_version": version}


def summarize(m, mid):
    def tok(d):
        return "; ".join(f"{k}: in {v['in']:,} / out {v['out']:,} / cache-read {v['cache_read']:,} / cache-write {v['cache_write']:,} ({v['calls']} calls)"
                         for k, v in d.items()) or "none"
    subs = ", ".join(f"{s['type']}/{s['model']} {s['tokens']:,} tok {s['seconds']}s" for s in m["subagents"]) or "none"
    mmss = lambda x: f"{x//60}m{x%60:02d}s"
    return (f"{mid}: active {mmss(m['active_s'])} of {mmss(m['elapsed_s'])} elapsed; "
            f"main tokens [{tok(m['main_tokens'])}]; subagents [{subs}]; "
            f"tool calls {m['tool_calls']} ({m['tool_errors']} failed); Claude Code {m['claude_code_version']}")


def record_metrics(root, state, data, items):
    """Append one measured record for the unrecorded part of this session. Returns its summary or None."""
    sid, tp = data.get("session_id") or "", data.get("transcript_path")
    if not sid or not tp:
        return None
    cursors = state.setdefault("cursors", {})
    m = measure(tp, cursors.get(sid))
    if not m:
        return None
    counts = state.setdefault("counts", {})
    n = counts[sid] = counts.get(sid, 0) + 1
    mid = f"M-{sid[:8]}-{n}"
    rec = {"id": mid, "session": sid, "items": items, **m}
    path = os.path.join(root, ".planning", "metrics.jsonl")
    with open(path, "a") as f:
        f.write(json.dumps(rec, separators=(",", ":")) + "\n")
    cursors[sid] = m["window_end"]
    return summarize(m, mid)


def block(reason):
    print(json.dumps({"decision": "block", "reason": reason}))


def main():
    try:
        data = json.load(sys.stdin)
    except ValueError:
        return
    root = find_root(data.get("cwd") or os.getcwd())
    if not root:
        return

    state_dir = os.environ.get("J_STACK_STATE_DIR") or os.path.expanduser("~/.j-stack/reflection-state")
    os.makedirs(state_dir, exist_ok=True)
    state_path = os.path.join(state_dir, hashlib.sha1(root.encode()).hexdigest() + ".json")
    try:
        with open(state_path) as f:
            state = json.load(f)
    except (OSError, ValueError):
        state = None

    current = evidence(root)
    refl_hash = sha(os.path.join(root, ".planning", "reflections.md")) or ""

    def save():
        with open(state_path, "w") as f:
            json.dump(state, f, indent=1)

    if state is None:  # first sight of this project: baseline only
        state = {"root": root, "seen": current, "struggle_sessions": [], "pending": None, "missed": [], "cursors": {}}
        save()
        return

    if data.get("hook_event_name") == "SessionEnd":  # flush whatever is unrecorded; never block
        if record_metrics(root, state, data, ["session end"]):
            save()
        return

    pending = state.get("pending")
    if pending and pending.get("session") != (data.get("session_id") or ""):
        state["missed"].append({"items": pending["items"], "why": "session ended first"})
        state["pending"] = pending = None
        save()
    if pending:
        # A reflection was requested on an earlier Stop; verify it happened.
        done = refl_hash != pending["reflections_hash"] or SENTINEL in (data.get("last_assistant_message") or "")
        if done:
            state["pending"] = None
        elif pending["tries"] < 2:
            pending["tries"] += 1
            save()
            return block(pending["reason"] + f"\n\nReminder: end with {SENTINEL} if nothing material was learned.")
        else:
            state["missed"].append({"items": pending["items"]})
            state["pending"] = None
        save()
        return
    if data.get("stop_hook_active"):  # forced by some other hook, not ours
        return

    new = sorted(p for p, h in current.items() if state["seen"].get(p) != h)
    sid = data.get("session_id") or ""
    struggle = 0
    if sid and sid not in state["struggle_sessions"] and data.get("transcript_path"):
        scan = state.setdefault("scan", {}).get(sid, [0, 0])  # [byte offset, failed calls so far]
        delta, offset = failed_tool_calls(data["transcript_path"], scan[0])
        state["scan"][sid] = [offset, scan[1] + delta]
        for k in list(state["scan"])[:-50]:  # keep the 50 most recent sessions
            del state["scan"][k]
        if state["scan"][sid][1] >= STRUGGLE_THRESHOLD:
            struggle = state["scan"][sid][1]
    if not new and not struggle:
        save()  # persists the incremental scan offset
        return

    items = new + ([f"session had {struggle} failed tool calls (possible hard failure)"] if struggle else [])
    measured = record_metrics(root, state, data, items)
    reason = (
        "j-stack checkpoint (automatic): new evidence since the last reflection:\n"
        + "\n".join(f"- {i}" for i in items)
        + "\n\nRun the project-reflection skill now, limited to this evidence and what this session already knows. "
        + (f"\n\nMeasured by the hook and appended to .planning/metrics.jsonl (use these figures only; never estimate or invent any):\n{measured}" if measured else "")
        + f"\n\nAsk the user nothing. If nothing material was learned, write nothing and end your reply with exactly: {SENTINEL}"
    )
    state["seen"].update({p: current[p] for p in new})
    if struggle:
        state["struggle_sessions"].append(sid)
    state["pending"] = {"session": sid, "reflections_hash": refl_hash, "tries": 1, "items": items, "reason": reason}
    save()
    block(reason)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # a hook must never break the session
        print(f"reflection-gate: {e}", file=sys.stderr)
