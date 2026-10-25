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

State lives outside the repo (per machine): $J_STACK_STATE_DIR or
~/.j-stack/reflection-state/. The first run in a project only records a
baseline, so existing history is never ingested automatically.
"""
import hashlib
import json
import os
import sys

SENTINEL = "NO_REFLECTION_NEEDED"
STRUGGLE_THRESHOLD = int(os.environ.get("J_STACK_STRUGGLE_THRESHOLD", "6"))
EVIDENCE_DIRS = ("reviews", "handoffs")


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


def failed_tool_calls(transcript):
    n = 0
    try:
        with open(transcript) as f:
            for line in f:
                if '"is_error"' not in line:
                    continue
                try:
                    msg = json.loads(line).get("message", {})
                except ValueError:
                    continue
                content = msg.get("content")
                if isinstance(content, list):
                    n += sum(1 for b in content if isinstance(b, dict)
                             and b.get("type") == "tool_result" and b.get("is_error") is True)
    except OSError:
        pass
    return n


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
        state = {"root": root, "seen": current, "struggle_sessions": [], "pending": None, "missed": []}
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
        struggle = failed_tool_calls(data["transcript_path"])
        if struggle < STRUGGLE_THRESHOLD:
            struggle = 0
    if not new and not struggle:
        return

    items = new + ([f"session had {struggle} failed tool calls (possible hard failure)"] if struggle else [])
    reason = (
        "j-stack checkpoint (automatic): new evidence since the last reflection:\n"
        + "\n".join(f"- {i}" for i in items)
        + "\n\nRun the project-reflection skill now, limited to this evidence and what this session already knows. "
        f"Ask the user nothing. If nothing material was learned, write nothing and end your reply with exactly: {SENTINEL}"
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
