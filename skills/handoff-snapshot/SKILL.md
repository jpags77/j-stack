---
name: handoff-snapshot
description: Captures current Claude Code session state for cross-tool resumption. Activates when the user is about to hit Anthropic usage limits, deliberately switching tools, or pausing work for an extended period. Writes a continuation snapshot to .planning/handoffs/ that Codex CLI, Cursor, ChatGPT, or Gemini can read to resume work without losing context. Outputs a paste-ready prompt the user can drop into the next tool. Use proactively when context window is filling or limits are imminent.
model: haiku
---

# handoff-snapshot

## When to activate

- User mentions usage limits, hitting cap, switching tools, or pausing work.
- Context window is approaching limits and work is incomplete.
- User explicitly asks to "save state" or "snapshot" or "hand off".
- Before any planned tool switch.

## Process

### 1. Verify wiki exists

Check `.planning/` exists. If not, run poc-wiki-init first, or report that the project isn't wiki-enabled and offer to bootstrap one.

### 2. Generate blackboard snapshot

Write to `.planning/handoffs/<timestamp>-snapshot.md` with this structure:

```markdown
# Handoff Snapshot — <timestamp>

```json
{
  "schema": "j-stack.handoff.blackboard.v1",
  "timestamp": "<ISO timestamp>",
  "agent": "<tool/model/runtime writing this snapshot>",
  "reason": "usage_limits | planned_switch | pause | checkpoint",
  "repo": {
    "branch": "<current branch>",
    "head": "<git rev-parse HEAD>",
    "dirty": true,
    "remote": "<origin URL if present>"
  },
  "state": {
    "iteration": "<from .planning/index.md>",
    "phase": "<from .planning/index.md>",
    "fidelity": "<from .planning/index.md>",
    "current_task": "<one sentence>"
  },
  "claims": [
    {
      "id": "C1",
      "claim": "<important fact a fresh agent should rely on>",
      "status": "confirmed | assumed | stale | needs_verification",
      "confidence": "high | medium | low",
      "provenance": ["<file path, command, commit, PR, URL, or conversation source>"]
    }
  ],
  "decisions": [
    {
      "id": "D1",
      "decision": "<decision made>",
      "rationale": "<why>",
      "provenance": ["<source>"]
    }
  ],
  "conflicts": [
    {
      "id": "X1",
      "description": "<contradiction between sources>",
      "preferred_source": "<source to trust now>",
      "reason": "<why this source wins>"
    }
  ],
  "open_questions": [
    {
      "id": "Q1",
      "question": "<question>",
      "owner": "user | agent | external"
    }
  ],
  "next_actions": [
    {
      "id": "N1",
      "action": "<specific next action>",
      "priority": "high | medium | low",
      "blocked_by": []
    }
  ],
  "artifacts": [
    {
      "path": "<file path>",
      "kind": "plan | review | code | docs | handoff | other",
      "status": "created | modified | referenced"
    }
  ]
}
```

## Human summary
[2-3 sentences: what is happening and what changed since the previous snapshot.]

## Freshness and source of truth
[Name any stale or conflicting source. If a source is known stale, say what supersedes it.]

## Decisions
[Bulleted list. Include decision IDs from the JSON block when useful.]

## Current task
[1-2 sentences: what the user was actively trying to do when this snapshot was taken.]

## Next steps
[Numbered list, ordered by priority. Each item should be specific enough that a fresh agent can act on it.]

## Open questions
[Anything blocked on user input or external answer.]

## Files touched this session
[List of files modified, with one-line summary of each change.]

## Verification
[Commands run and results. If not run, say why.]

## Continuation prompt
[A paste-ready prompt the user can drop into the next tool. Reference this handoff file by path. Keep under 200 words.]
```

The JSON block is the blackboard. Keep it valid JSON, keep IDs stable within the file, and do not invent provenance. Use `needs_verification` when a claim is useful but not yet checked.

### 3. Append to log.md

(Writing the snapshot is itself a checkpoint: the reflection-gate Stop hook notices the new file and asks for `project-reflection` afterwards. Do not run it from here.)


`## [<timestamp>] handoff | <reason: usage_limits / planned_switch / pause>`

### 4. Update index.md

Add the new handoff snapshot to the index with one-line summary.

### 5. Output to user

Show:
- Path to the snapshot file
- The continuation prompt (rendered as a copy-ready code block)

## Output

Snapshot file + paste-ready continuation prompt. User can now switch tools cleanly.