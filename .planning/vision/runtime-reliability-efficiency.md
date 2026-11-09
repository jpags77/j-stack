# Runtime reliability and efficiency design

Date: 2026-09-20. Written design for the user-requested implementation plan.
Goal: preserve unfinished work, make evidence and state consistent, and reduce
total task cost without reducing acceptance quality.
Scope: all six recommendations in the September 20 strategic review.

## Architecture and constraints

Keep markdown as the durable project interface. Add a small standard-library
Python utility for schema normalization, checkpoints, and diagnosis. Keep
measurements in a separate evaluation script. Neither utility schedules agents,
chooses models, rewrites transcripts, calls a model, or stores credentials.

Use existing bash/Python/git dependencies. Single-command installation remains.
No new package dependencies, database, daemon, proxy, or routing service.
Native model controls own execution. Luna implements bounded tasks; the parent
owns integration and reviews. Independent Luna review is used at milestone
boundaries, rather than multiple reviewers per trivial edit.

Existing user edits and personal settings must survive. No automatic push or
real-home installation during implementation. Test installation under isolated
homes. Use explicit, validated paths and never store raw transcripts in the
tracked wiki by default. Never claim automatic recovery on a host lacking hooks.

## State and evidence

Write future handoffs as `j-stack.handoff.blackboard.v2`, preserving the current
Codex template's fields and adding timestamp, session identity, task identity,
current task, WIP reference, and acceptance evidence. Read both legacy v1 shapes
without modifying the historical files; normalize missing fields as unknown.

Each active task has one human-readable `.planning/tasks/<task-id>.md` with a
small JSON block: schema, task ID, iteration, phase, workflow profile, intent,
success criteria, fidelity dimensions, assumption references, gates and next
action. It is the sole authority for task gate status. The index is the catalog
and parent-owned active-task pointer; handoffs are snapshots referencing task
records. Child agents do not edit the shared index or the same task record.
Session capsules carry their own task IDs. Independent parent sessions use
separate task IDs and the doctor surfaces conflicting current-state claims.
Handoff filenames include timestamp, session/task suffix and a random nonce;
create exclusively and retry on collision, never overwrite an existing snapshot.

Gate status is pending/passed/failed/waived/stale. A passed gate records criterion,
evidence path, reviewed revision and relevant file hashes (including dirty files
when applicable). A waiver records scope, rationale and authority. An artifact's
mere existence never passes a gate. Relevant file or assumption changes stale
affected evidence; unrelated documentation changes do not invalidate everything.
Without a declared dependency scope, a changed checkout is conservatively stale.

## Recovery

Two local files per session/agent: `wip.md` (agent-written intent, discoveries, pending
actions, exact next step) and `checkpoint.json` (mechanical state and references).
Store under gitignored `.planning/runtime/<session-agent-key>/`, mode 0700 for directory
and 0600 for files. Safe session IDs are hashes of runtime/root/session inputs,
not user-supplied path fragments. Agent identity distinguishes concurrent agents.
Each agent owns its WIP file and atomically replaces it; hooks only read WIP.
The parent integrates child findings into its own WIP, never shares a writer.

Write intent before substantial work and semantic updates at meaningful state
changes. A host hook captures repository identity, branch/HEAD, dirty/untracked
path inventory, WIP hash and timestamp, event/tool IDs and completion status.
Record command/output references when available, not raw secrets-bearing text.
Working-tree content remains in place; capsules are not file backups. Automatic
discovery is scoped to the same checkout. A fresh worktree or machine cannot see
ignored capsules and must use an explicitly transferred or committed handoff.
WIP timestamp/hash is recorded separately from checkpoint freshness: an API
failure can refresh mechanical facts but cannot refresh the agent's intent.
Completed
handoffs plus commits provide portable recovery. Report missing working trees or
transcripts as unavailable, never imply a diffstat can reconstruct file content.

Claude: prefer PostToolBatch; use supported PostToolUse fallback with serialization
and bounded debounce. Capture mutation batches immediately; refresh read-only
batches after 10 calls or 60 seconds at the next event. Flush on failure,
compaction and stop/end. These are event-bound bounds, not a timer guarantee.
Codex/other: call the utility explicitly at the same semantic boundaries unless
a supported hook is verified. No invented hook, no private log-format dependency.

Atomic replace under a per-session OS-released lock; preserve last good checkpoint
on malformed input or write failure. Fail visibly but do not stop coding due to
a checkpoint failure. Hook-created writes exclude their own runtime directory
from change detection to prevent loops. Fresh agents reconcile side effects
before retrying pending operations; no automatically replayed commands.

## Proportional workflow

Three profiles: maintenance (known bounded correction), feature (bounded change
with new behavior), engagement (new problem/architecture or material uncertainty).
Risk can escalate any profile. Existing phases remain the vocabulary; reduced
paths explicitly mark inapplicable gates with rationale. User intent and valid
existing decisions are reused. Ask only for material missing/conflicting input.

Separate presentation (plain/polished), integration (mock/mixed/real), and
operations (local/sandbox/real-users). These describe acceptance needs, not a
ranking. All profiles protect secrets and data; external effects retain their
normal authority requirements. MVP readiness identifies unproven production
requirements instead of implying blanket production approval.

Prior-art evidence names the assumptions it supports. Dependency, architecture,
licensing or stakeholder constraint changes trigger focused re-evaluation; a
copy edit does not. Reviewers receive a specific failure question and evidence.
Findings record disposition, owner and verification. Lessons stay in-project
unless an explicit user-controlled cross-project destination exists.

## Efficiency and Jev

Measure startup instruction bytes separately from observed tokens. Reuse evidence
references; read current task + newest relevant checkpoint first, loading history
only on conflict. Keep detailed lane instructions on demand. Prefer targeted
queries; preserve the mandatory Graphify BUILD policy. Do not remove safety or
acceptance checks to meet a token target. Do not assume compaction preserves
prompt caches or that fewer messages imply lower total cost.

Luna medium is the initial implementation default, high for recovery/schema edge
cases, low for mechanical doc synchronization. The parent resolves ambiguity;
two failed attempts with the same blocker trigger escalation review, not an
unbounded retry loop or automatic model switch. Preserve explicit user choices.

Use native usage exports where available; otherwise record unknown token fields.
Compare identical synthetic tasks before/after with outcome checks. An optional
Jev shadow trial uses sanitized feature records, not repository transcripts,
with human-labeled workflow and prior-art cases. Its result never changes live
execution. Native-only remains the baseline and default; no live API or plugin
installation is necessary to deliver the six improvements.
