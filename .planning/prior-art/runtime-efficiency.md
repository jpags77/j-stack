# Runtime reliability and efficiency survey

Date: 2026-09-20. Scope: the six strategic improvements and decision optimization.
Decision: HYBRID, authorized by the user's instruction to proceed with the
proposed native-first implementation plan. This completes SURVEY for this
initiative; it does not claim a historical survey of every j-stack integration.

## Reuse before build

| Need | Reuse | Small addition | Reject/defer |
| --- | --- | --- | --- |
| Agent execution and model effort | Native Codex spawn parameters and runtime configuration | Task dispatch guidance and measured escalation | Custom router, scheduler, proxy, agent framework |
| Project memory | Existing markdown wiki, git, handoff schema | Compatible reader, versioned writer, read-only doctor | Database, vector memory, event-sourced workflow engine |
| Recovery | Working tree and host session persistence; supported Claude command hooks | Local WIP notes and small mechanical checkpoint command | Transcript rewriting, model calls after quota failure |
| Workflow selection | Explicit user requirements, existing lanes | Three documented profiles and evidence rules | Model deciding authoritative phase or waivers |
| Efficiency evaluation | Native usage reports when exposed, existing shell/Python toolchain | Fixture-based metrics import and comparison | Always-on telemetry collector or billing estimator |
| Ambiguous classification | Parent's existing reasoning, deterministic baseline | Optional Jev shadow evaluation | Jev required for routing, recovery, or phase transitions |

## Primary-source verification

- [OpenAI subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents):
  supports explicit model and effort selection, defaults, and custom agent
  configuration. Runtime tool availability is authoritative; names and settings
  must be checked at execution. Our current spawn tools support Luna directly.
- [Claude hooks](https://code.claude.com/docs/en/hooks): `PostToolBatch` runs after
  a resolved tool batch; `StopFailure` covers API errors including rate limits;
  `PreCompact` and `SessionEnd` cover other boundaries. Actual installed version
  must support the selected events. These docs establish no equivalent Codex hook.
- [Jev announcement](https://typesafe.ai/blog/introducing-system-one-models-and-jev):
  typed probabilistic outputs fit classification. Schema correctness is not
  decision correctness; published workflow speed/cost claims do not establish
  j-stack task savings or classification calibration.
- [Existing compactor survey](jev-context-compaction.md): MIT candidate inspected
  at e3f262a; selection and packaging concerns make direct adoption premature.

Existing native services remain subject to their host's terms; no external
library is incorporated by this design. Python standard library and git avoid a
new package dependency. Offline tests and explicit local exports do not require
credentials or transcript disclosure. No live Jev evaluation was performed.

## Decision boundaries

Authoritative phase = recorded task state plus evidence. Prior-art invalidation
begins with changed assumptions; semantic ambiguities go to the current agent.
Model selection uses native controls and explicit user choices. Jev can suggest a
profile or flag assumption changes in a synthetic, labeled shadow trial. A
classifier never weakens required evidence or overrides user intent.

## Evaluation gate

Baseline the existing workflow before changes using the same task fixtures,
runtime/model settings and acceptance rubric. Separate deterministic tests from
live agent trials. Compare parent plus children plus retries plus compaction,
including cached-input categories when available. Missing telemetry is unknown,
not zero. No claimed percentage savings without measured paired runs.
