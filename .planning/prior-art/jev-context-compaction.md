# Prior Art Survey: Jev Context Compaction and Durable WIP Recovery

Date: 2026-09-20  
Status: survey complete; adoption decision pending  
Candidate: [tamaratran/fast-jev-compaction](https://github.com/tamaratran/fast-jev-compaction)

## Question

Can Jev-style extractive context compaction improve j-stack, and can it prevent
in-progress work from disappearing when an agent hits a usage limit?

## Executive finding

The ideas are useful, but the repository is not ready to become a j-stack core
dependency. Jev-style compaction and durable recovery solve different problems:

- **Compaction** keeps a live conversation below its context limit by selecting
  which tool calls and results remain useful.
- **Recovery** preserves work outside the conversation so another session or
  tool can resume after a rate limit, crash, or forced stop.

The recommended direction is **HYBRID**: borrow the extractive, scored-selection
model as an optional experiment, while building j-stack's reliability around a
provider-neutral, deterministic WIP capsule plus the existing curated wiki and
handoff blackboard. Do not make Jev or TypeSafe availability a prerequisite for
recovery.

## What the repository does

`fast-jev-compaction` replaces Claude Code's normal generated compaction summary
with an extractive transcript:

1. Pair each completed tool call with its result.
2. Keep the first and most recent messages pinned.
3. Send a fitted representation of the conversation to TypeSafe's Jev API.
4. Ask two probabilistic yes/no questions for each older call: whether the call
   and whether its full result should remain.
5. Keep the pair, keep the call and truncate its result, or drop both.
6. Fall back to Claude Code's normal summary when Jev fails or reduction is too
   small.

User and assistant prose remains verbatim in the resulting transcript. Tool
outputs are the primary deletion target. The implementation is a TypeScript
library plus a Claude Code function-hook adapter.

Primary sources:

- [Repository and README](https://github.com/tamaratran/fast-jev-compaction)
- [TypeSafe's Jev announcement](https://typesafe.ai/blog/introducing-system-one-models-and-jev)
- [Claude Code hooks reference](https://code.claude.com/docs/en/hooks)

## Verification performed

The survey inspected commit `e3f262a` (2026-09-17) and ran the repository locally:

- `npm ci`: completed; npm reported five audit findings in the installed tree.
- `npm test`: 29 tests passed.
- `npm run typecheck`: passed for the library and hook.
- `npm run build`: passed.
- `npm view fast-jev-compaction ...`: returned npm registry `E404`; despite the
  README's `npm install fast-jev-compaction` instructions, the package was not
  publicly available under that name when checked.
- License: MIT.

The repository is only a few days old: the inspected main history contains 30
commits, with the latest visible commit dated 2026-09-17. Its large early star
count is interest, not evidence of operational maturity.

## Fit with j-stack

| Concern | Existing j-stack mechanism | Jev contribution | Remaining gap |
| --- | --- | --- | --- |
| Large tool outputs | Headroom compression and Graphify | Removes stale tool pairs while retaining selected evidence verbatim | Jev needs a hosted API and host-specific compaction hook |
| Lossy generated summaries | Structured handoff blackboard | Avoids rewriting retained transcript content | Selection can still delete the wrong evidence |
| Cross-tool continuation | `.planning/` wiki and handoffs | None directly; Claude Code transcript replacement is host-specific | Codex, Cursor, and other runtimes still need filesystem state |
| Usage/rate-limit failure | Manual `handoff-snapshot` instruction | May reduce token use before failure | Cannot write a checkpoint after the model is already rate-limited |
| Hard crash/process kill | Git working tree and existing committed wiki | None | Session-end hooks are not guaranteed on abrupt termination |

Jev is therefore complementary to Headroom and Graphify, not a replacement for
the wiki. Headroom compresses individual large payloads; Graphify externalizes
code structure; Jev selects old transcript evidence; `.planning/` carries
durable project state and intent.

## Material risks and gaps

### 1. Current defaults appear unsafe

[Issue #56](https://github.com/tamaratran/fast-jev-compaction/issues/56)
reports that `keepCall` and `keepResult` are returned on different probability
scales while the code applies the same `0.5` threshold to both. In the author's
reproduction, important results never reached the keep threshold; on a
183-message real transcript, every non-pinned call was dropped at the default.

[Issue #52](https://github.com/tamaratran/fast-jev-compaction/issues/52)
independently reports that the default question wording suppresses the useful
signal and that late state-fitting stages can remove the very calls Jev is being
asked to judge. In a 1,084-message replay, all non-pinned calls were dropped by
the default configuration.

These reports are open and post-date the inspected main commit. The unit tests
use a fake Jev response and prove deterministic transformation behavior, not
real-model selection quality.

### 2. Operational hardening is incomplete

Open reports cover missing request deadlines/cancellation, unbounded concurrent
batches, auto-compaction locking, unresolved tool calls, ambiguous tool IDs,
and npm packaging. The plugin also depends on Claude Code's newer function-hook
surface and TypeSafe early access.

### 3. Privacy and vendor coupling

Every scoring batch resends a fitted representation of the conversation to the
TypeSafe endpoint. Tool results are replaced by size/status notes in that state,
but user and assistant text and tool inputs may still contain repository paths,
commands, requirements, or proprietary context. Enterprise j-stack use would
need an explicit data-handling review, secret scrubbing, endpoint controls, and
a documented fallback.

### 4. It targets context limits, not account usage limits

Compaction can reduce subsequent input tokens, but it cannot guarantee that an
agent receives another model turn. If a quota or rate-limit failure occurs, an
instruction such as "run handoff-snapshot when usage is low" may never execute.
Recovery must therefore have a non-model path.

## Recommended j-stack design

### Layer 1: curated durable wiki

Keep `.planning/` as the semantic source of truth. An agent should update the
canonical wiki at **meaningful state transitions**, not after every tool call:

- immediately after a user-approved scope or architecture decision;
- when phase, fidelity, blockers, ownership, or the ordered next action changes;
- after a coherent implementation slice is verified or committed;
- when research or review creates an artifact future work must trust;
- before a planned pause, tool switch, branch/worktree handoff, or risky change.

These are judgment-heavy updates and should remain agent-authored.

### Layer 2: mechanical WIP capsule

Add an atomically replaced, per-session capsule under a dedicated path such as
`.planning/checkpoints/<session-id>.json`. It is an autosave, not canonical
project truth. A hook or small local command can write it without an LLM.

Minimum fields:

- schema, timestamp, session/runtime ID, and checkpoint reason;
- repository root, branch, HEAD, dirty flag, changed files, and diffstat;
- current phase and current task when available from `.planning/index.md`;
- last user prompt and last completed assistant message from the transcript;
- active task/todo state when exposed by the runtime;
- commands/tests observed since the previous checkpoint, clearly marked as raw;
- transcript path and ordered recovery hints;
- `semantic_status: unverified` so a future agent does not mistake extraction
  for a reviewed decision.

Write or refresh the capsule on:

1. `Stop` after each completed agent turn, debounced and only when repository or
   task state changed;
2. `PreCompact`, before any transcript is rewritten;
3. `StopFailure`, especially `rate_limit`, `max_output_tokens`, `overloaded`, and
   server errors;
4. `SessionEnd` as a final best-effort flush.

Claude Code's documented hook payloads include `session_id`, `transcript_path`,
and `cwd` for these boundaries. `StopFailure` explicitly covers rate limits and
is intended for logging or recovery actions. A hard process kill can bypass the
last two events, which is why the completed-turn checkpoint is the primary
durability mechanism.

On `SessionStart` or resume, j-stack should detect newer unconsumed capsules,
compare them with git and the wiki, and have the agent reconcile them into a
normal handoff or log entry. The capsule should never directly edit
`index.md` or claim that tests passed; concurrent sessions and incomplete turns
make that unsafe.

### Layer 3: optional context compaction

Treat Jev as an opt-in experimental accelerator after upstream calibration and
packaging stabilize. If evaluated:

- pin an exact commit/version;
- default to fallback-on-any-error;
- reject degenerate decisions that drop every candidate;
- use separate or relative thresholds for calls and results;
- preserve errors, edits/writes, user constraints, and current-plan evidence;
- measure recovery correctness, not only character reduction;
- document external data flow and require an explicit API-key opt-in;
- keep the feature Claude-specific and do not make it part of j-stack's portable
  core.

## Alternatives considered

### ADOPT the plugin now

Fastest route to live compaction, but rejected as the recommendation because
the default-selection defects are material, npm installation is not currently
available, the API is early access, and recovery would remain unsolved.

### FORK the repository

Provides control over thresholds and safety rules, but creates maintenance work
against a very young Claude hook API and a vendor model whose calibration may
change. A fork is premature until a measured trial shows benefits beyond
Headroom and native compaction.

### BUILD a j-stack summarizer

Could be provider-neutral, but generated summaries recreate the lossy behavior
Jev is trying to avoid. Building a full compactor is unnecessary for the actual
pain point. A deterministic WIP capsule is smaller and more reliable.

### HYBRID (recommended)

Adopt the design insight—extractive selection for disposable transcript noise—
without coupling durable recovery to it. Build the WIP capsule and lifecycle
rules first; run Jev only as a pinned, optional experiment.

## Proposed success tests for a later spike

Use anonymized or synthetic transcripts and test these separately:

1. **Compaction fidelity:** after pruning, can a fresh agent state the goal,
   constraints, files being edited, last failing command, and exact next step?
2. **Rate-limit recovery:** inject `StopFailure(rate_limit)` mid-task and confirm
   a new session can resume from git + capsule without the original context.
3. **Hard-kill recovery:** terminate the agent between tool calls and bound the
   maximum lost work to one completed turn.
4. **Cross-runtime recovery:** resume the same capsule in Claude Code and Codex.
5. **Safety:** concurrent sessions never overwrite each other's capsules or
   mutate canonical wiki pages automatically.
6. **Economics:** measure total paid input tokens and wall time, including Jev's
   repeated state payloads and native prompt-cache rebuilds.

## Decision gate

Recommended decision: **HYBRID**.

User approval is still required before recording the decision in
`.planning/index.md`, writing an implementation plan, installing the plugin, or
building the WIP checkpoint mechanism.
