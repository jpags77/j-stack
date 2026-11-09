# Runtime Reliability and Efficiency Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development to implement
> this plan task-by-task. User-selected method: Luna sub-agents with parent-led
> integration. Checkboxes track implementation, not completion of this plan.

**Goal:** Implement the six strategic improvements with measurable efficiency,
recoverable WIP, consistent evidence, and proportional process.

**Architecture:** Reuse markdown, git, native agent execution, and existing
installation paths. Add small standard-library utilities for state/checkpoint
validation and evaluation; keep runtime adapters thin. No model router or daemon.

**Tech Stack:** Existing bash, Python 3 standard library, git, native Claude/Codex
capabilities, unittest, existing shell tests, GitHub Actions for offline checks.

**Spec:** `.planning/vision/runtime-reliability-efficiency.md`
**Prior art:** `.planning/prior-art/runtime-efficiency.md`
**Status:** User approved; BUILD in progress in branch `codex/runtime-reliability`.
Task 0 baseline committed. Consult the plan-specific SDD ledger for implementation
progress; unchecked items below remain requirements, not completion claims.

## Global constraints

- No new package dependencies, database, daemon, proxy, or routing service.
- Native model controls own execution; explicit user model choices persist.
- No automatic push or real-home installation during implementation.
- Existing user edits and personal settings must survive.
- Keep raw transcripts out of tracked wiki content by default.
- Never claim automatic recovery on a host lacking hooks.
- Use existing bash/Python/git dependencies; single-command installation remains.
- Run Graphify before substantive BUILD per repository policy; absent Graphify
  is surfaced before broad code exploration, as required by the current policy.
- Preserve existing dirty `.planning/` work from this conversation. Stage only
  enumerated task files. No recursive cleanup outside validated test directories.

## Review focus

1. An interrupted long turn must leave a usable WIP record (Tasks 2 and 3).
2. Concurrent sessions or reordered callbacks must not overwrite newer evidence
   or another agent's capsule (Task 2).
3. Legacy v1 handoffs and dirty/untracked changes must remain readable and
   untouched; metadata is not a backup (Tasks 1, 2 and 4).
4. Missing native events/telemetry must produce explicit degraded capability,
   not invented automation or zero cost (Tasks 0, 3 and 6).
5. A reduced workflow must preserve acceptance and material risk checks, while
   irrelevant changes must not trigger every gate again (Tasks 4 and 5).

## Delivery and ownership

| Task | Deliverable | Depends on | Luna effort |
| --- | --- | --- | --- |
| 0 | Baseline fixtures and measurement contract | none | medium |
| 1 | Versioned state and compatibility | 0 baseline | high |
| 2 | Local WIP checkpoint utility | 1 | high |
| 3 | Installation and runtime recovery | 2 | high |
| 4 | Doctor and evidence freshness | 1 | high |
| 5 | Proportional workflow and outcome quality | 1, 4 | medium |
| 6 | Efficiency improvements and paired evaluation | 0, 3, 5 | medium |
| 7 | CI, migration documentation, final review | all core tasks | medium |
| E | Optional Jev shadow experiment | 0, 5, 6 | medium |

Task 0 finishes baseline capture before Task 1 changes instructions. Tasks 2 and 4 share a utility file and
must run serially; do not parallelize their edits. Task 5 owns skills/templates;
Task 3 owns installer/hooks, but changes to build-mode must be integrated by the
parent after their respective branches finish. Task 6 follows a captured baseline.

Each dispatch includes only this spec, the task section, relevant file paths,
upstream interfaces, and acceptance criteria. Use `fork_turns: none`, model
`gpt-5.6-luna`, and explicit effort. Maximum two implementation agents at once;
a third slot is available for bounded read-only review. Do not fork the entire
conversation. Do not create persistent app threads or external API workers.

Parent checks each task's diff/tests and integrates it. Use a fresh Luna reviewer
at recovery, workflow, and final milestones with a concrete failure question.
Escalate unresolved ambiguity to the parent after two failed attempts with the
same cause. Report evidence and next step in at most roughly 500 words; link logs.
No automatic escalation to a different model without preserving user direction.

## Task 0: Baseline and evaluation contract

**Files:** create `evals/README.md`, `evals/cases.json`,
`evals/run.schema.json`, `scripts/evaluate.py`, `tests/test_evaluate.py`.
**Interface:** `python3 scripts/evaluate.py --runs FILE --cases FILE --json`
reads explicit JSONL records and emits a report. No agent launcher or log crawler.

Run record fields: run_id, case_id, variant, runtime/version, model, effort,
parent_run_id, usage_scope (own/aggregate), input_tokens, cached_input_tokens,
output_tokens, reasoning_tokens, wall_seconds, retries, unnecessary_questions,
acceptance_passed, unsupported_done_claims, recovery_steps, source, completeness.
Unknown numeric values are null. Identify whether reasoning tokens are included
in output; never add them twice. Aggregate parents exclude separately counted
children. Reject ambiguous usage scope. Cached input is a subset when the source
defines it so; preserve native meanings and reject cached > total input.

Canonical token total = reported input (including cached subset) + reported output
(including reasoning where the native source defines it as included). Separate
reasoning is added only when the source explicitly excludes it from output.
Missing semantics or any missing contributing category makes total null; never
sum partial coverage and call it a complete task total. A complete aggregate
ancestor replaces its whole descendant subtree, recursively; if incomplete,
descendant records cannot fill its unknown own usage without an explicit own
record. Reject cycles, duplicate run IDs and conflicting overlapping aggregates.
Compare cached/uncached categories separately; token total is not billed dollars.

- [ ] Add eight deterministic case descriptions: bounded correction, new feature,
  unknown integration, changed architecture, irrelevant copy edit, interrupted
  mutation, cross-runtime handoff, absent optional capability. Each has explicit
  allowed workflow, expected artifacts, and acceptance assertions.
- [ ] Write and run failing metric tests, including:

```python
def test_missing_usage_is_unknown(self):
    report = summarize([run(input_tokens=None)])
    self.assertIsNone(report['input_tokens'])
    self.assertEqual(report['usage_complete'], False)

def test_aggregate_parent_not_double_counted(self):
    records = [run(run_id='p', usage_scope='aggregate', input_tokens=100),
               run(run_id='c', parent_run_id='p', input_tokens=40)]
    self.assertEqual(summarize(records)['input_tokens'], 100)
```

`run(**changes)` is a test helper supplying all required fields; `summarize(records:
list[dict]) -> dict` is the exported evaluator function.
- [ ] Implement schema checks, aggregation and comparisons. Emit raw totals,
  per-case results, completeness and quality outcomes; no fabricated dollar costs.
- [ ] Run `python3 -m unittest discover -s tests -p 'test_evaluate.py' -v`.
- [ ] Capture pre-change baseline on synthetic fixtures using the current native
  harness; keep raw run records local and commit only sanitized report summaries.
  First pass: one run/case. Repeat variable cases three times before claiming
  savings. Record model/runtime/cache conditions. If usage is unavailable, retain
  behavioral results and state that token baseline is incomplete.
- [ ] Parent checks report and commits task files with `test: establish workflow
  and efficiency baseline` before instruction changes begin.

## Task 1: Canonical state and compatible handoffs

**Files:** create `scripts/jstack_state.py`, `templates/blackboard-v2.json`,
`templates/task.md`, `tests/test_state.py`, `tests/fixtures/state/*.json`;
modify both `skills/handoff-snapshot/SKILL.md` and
`skills/codex/handoff-snapshot/SKILL.md`, its `templates/blackboard.json`, and
`install.sh` template-copy logic.
**Interfaces:** `normalize_handoff(data: dict) -> dict`,
`validate_task(data: dict) -> list[dict]`. Diagnostics contain code, severity,
path, message. `python3 scripts/jstack_state.py normalize FILE` prints normalized
JSON and never writes the input. Errors return exit 2.

- [ ] Fixtures cover Claude v1, Codex v1, canonical v2, malformed JSON, unknown
  version and missing evidence. Record source_schema on normalized data; missing
  legacy fields are null/empty and marked unverified, never invented.
- [ ] Pin compatibility with a failing test:

```python
def test_legacy_file_is_not_rewritten(self):
    original = self.legacy_path.read_bytes()
    result = normalize_handoff(json.loads(original))
    self.assertEqual(result['schema'], 'j-stack.handoff.blackboard.v2')
    self.assertEqual(self.legacy_path.read_bytes(), original)
    self.assertEqual(result['source_schema'], 'j-stack.handoff.blackboard.v1')
```

- [ ] Implement mappings: repo→repository_state; state.iteration/phase/current_task
  → explicit fields; artifacts→touched_artifacts; provenance/source preserved.
  Version 2 adds timestamp, runtime/session/task IDs, WIP reference and evidence.
  Use timestamp-session-task-nonce filenames with exclusive-create and retry.
  The parent alone updates its task record
  and shared index; children return evidence for parent integration. Test that
  same-second handoffs for the same session/task do not collide and differing
  session task IDs remain distinct. Inject a repeated nonce to test collision retry.
  Never silently accept a third unknown v1 shape.
- [ ] Define task JSON block schema `j-stack.task.v1` in `templates/task.md`:
  task_id, iteration, phase, profile, intent, success_criteria, fidelity,
  assumptions, gates, next_action. Gate fields: id, status, criterion,
  evidence_paths, revision, relevant_paths with hashes, assumption_ids, waiver.
- [ ] Copy canonical templates into installed skill bundles so installation is
  self-contained. Add byte-equality test for bundled source copies rather than
  independently maintaining competing shapes.
- [ ] Run state tests and existing installation tests under temporary homes.
  Commit: `feat: standardize task evidence and versioned handoffs`.

## Task 2: WIP and mechanical checkpointing

**Files:** extend `scripts/jstack_state.py`; create `templates/wip.md`,
`tests/test_checkpoint.py`; update `.gitignore` for `.planning/runtime/`.
**Interfaces:** `checkpoint(root: Path, event: dict) -> dict` returns status,
path, warnings. CLI `checkpoint --root ROOT --event-stdin` consumes one JSON
object. Required event fields: runtime, session_id, event_id, event_name;
optional: agent_id, sequence, timestamp, tool_ids, completion, transcript_ref.
`inspect --root ROOT` lists local session capsules without executing stored text.

- [ ] Write failing tests for rate-limit payload, two sessions, traversal-shaped
  IDs, duplicate event, reversed sequence, malformed event, unavailable git,
  read-only destination, deleted transcript, killed writer, dirty/untracked files.

```python
def test_stale_event_preserves_newer_checkpoint(self):
    checkpoint(self.root, event(sequence=7))
    checkpoint(self.root, event(sequence=6))
    self.assertEqual(self.read_capsule()['sequence'], 7)

def test_checkpoint_does_not_stage_or_change_user_files(self):
    before = self.capture_user_files_and_index()
    checkpoint(self.root, event(event_name='StopFailure'))
    self.assertEqual(self.capture_user_files_and_index(), before)
```

- [ ] Implement hashed session+agent paths, same-directory temporary writes,
  `os.replace`, owner-only permissions and an OS-released lock. Observe git after
  acquiring the lock. Supplied monotonic sequences reject stale callbacks; without
  sequence, serialize observations and label ordering unknown. Preserve the last
  good file on errors. Do not follow symlinks into unrelated destinations.
- [ ] Inventory staged, unstaged and untracked paths using git's NUL-separated
  output. Exclude runtime artifacts. Store WIP hash/reference, working-tree path,
  repository identity, HEAD, event IDs and completion state. No raw transcript
  content, credential-bearing command strings, automatic git add, or replay.
  Keep WIP freshness separate from mechanical checkpoint freshness. Test that
  StopFailure preserves old semantic timestamps and flags potentially stale WIP.
- [ ] Implement debounce: immediate mutation/failure/compaction checkpoints;
  read-only activity due at 10 tool calls or 60 elapsed seconds on next event.
  Session end is best effort. Use a monotonic local clock for debounce.
- [ ] WIP template: task/intent, constraints, discoveries, files, last verification,
  pending external effects, exact next action. Keep it under about 500 words;
  link detailed evidence. Explicitly state capsule metadata cannot restore deleted
  uncommitted files or recreate reasoning never written.
  Each session/agent key owns one WIP writer; hooks read it only. Use atomic
  replacement for WIP as for capsules. Parent merges child reports into its own
  WIP, never writes child WIP. Test simultaneous child and parent updates preserve
  each file, and a checkpoint sees an old or new complete WIP document.
- [ ] Run checkpoint tests, including subprocess concurrency and forced termination
  in a temporary repository. Fresh reader sees either old or new valid JSON.
  Test a second worktree: ignored capsules are absent and continuation falls back
  to committed handoff plus explicit missing-local-state warning, not false recovery.
  Commit: `feat: checkpoint unfinished work without model calls`.

## Task 3: Runtime adapters and installation

**Files:** create `hooks/checkpoint.py`, `tests/checkpoint-config.sh`,
`tests/fixtures/hooks/*.json`; modify `install.sh`, `hooks/build-mode-gate.sh`,
`templates/codex-role.md`, `README.md`; queue build-mode changes for Task 5.
**Interface:** hook reads native JSON stdin, translates to Task 2 event, invokes
installed utility relative to its own location. Normal success produces no
context output. Errors write a short diagnostic; checkpoint failure does not
block the original task.

- [ ] Write fixtures for PostToolBatch, PostToolUse, StopFailure, PreCompact,
  Stop and SessionEnd. Verify installed host event support before enabling names.
  Prefer batch events; fallback per-tool events are serialized/debounced. Do not
  configure both paths to duplicate each tool batch.
- [ ] Installer adds utility/templates to a runtime-local managed directory and
  merges only its exact owned hook entries. Repeated installation is idempotent;
  unrelated settings/hooks are byte/semantically preserved as appropriate.
- [ ] Provide opt-in recovery flag `--recovery` with dry-run support. Codex-only
  installs supply the explicit command and instructions, with automatic support
  labeled unavailable unless a supported native event is actually verified.
- [ ] Add a SessionStart hint only when newer unconsumed WIP exists: path and
  freshness warning, not full transcript. Non-j-stack sessions remain silent.
- [ ] Test fresh/repeated/dry-run/malformed config installs under temporary HOME;
  test paths with spaces and missing optional tools. Confirm no hook output loop
  and no writes to canonical index/log during mechanical capture.
- [ ] Test interruption after a mutation within one unfinished turn and then
  resume using capsule + WIP + working tree. Verify pending operations are checked
  before retry. Commit: `feat: integrate capability-aware recovery adapters`.

## Task 4: Read-only doctor and evidence freshness

**Files:** extend `scripts/jstack_state.py`; create `tests/test_doctor.py` and
`tests/fixtures/doctor/`; update `templates/task.md` documentation.
**Interface:** `doctor --root ROOT --json` yields diagnostics and counts;
exit 0 clean, 1 actionable warnings, 2 malformed input/error. No auto-repair.
`evidence_status(gate: dict, root: Path, assumptions: dict) -> str` returns the
effective status without mutating the recorded status.

- [ ] Test missing reference, unknown schema, changed relevant file, unchanged
  file at a different HEAD, untracked relevant edit, and changed assumption.

```python
def test_unrelated_change_preserves_evidence(self):
    gate = self.passed_gate(paths=['src/main.py'])
    self.write('notes.md', 'unrelated')
    self.assertEqual(evidence_status(gate, self.root, {}), 'passed')
```

- [ ] Validate task/handoff schemas, references, required passed-gate evidence,
  waiver rationale/authority and active-task pointer. Artifact presence alone
  cannot pass gates. Hash mismatch or assumption mismatch returns stale.
- [ ] Report conflicting explicit state and supersession; do not pretend to infer
  arbitrary prose contradictions. Historical snapshots are not errors solely
  because they describe an older state.
- [ ] Test no file changes before/after doctor and stable diagnostic codes.
  Commit: `feat: diagnose stale and inconsistent project evidence`.

## Task 5: Proportional process and acceptance quality

**Files:** modify `templates/lane-doctrine.md`, `templates/codex-role.md`,
`skills/build-mode/SKILL.md`, `skills/codex/build-mode/SKILL.md`, both
`poc-wiki-init`, both `prior-art-survey`, both `stakeholder-pack`,
`skills/second-opinion/SKILL.md`, `skills/codex/adversarial-review/SKILL.md`,
co-located templates, root/wiki AGENTS.md and CLAUDE.md, and `README.md`;
create `templates/workflow-profiles.md`, `templates/review.md`,
`tests/test_workflow_contract.py`.
**Interface:** all runtime instructions read the same task/evidence contract;
no additional workflow engine. Existing phase names remain.

- [ ] Record three profiles with explicit rules: maintenance reuses valid scope
  and plan; feature adds requirements/design where behavior changes; engagement
  runs full uncertainty reduction. Material risk escalates applicable checks.
  Every omitted gate has a scoped not-applicable/waiver rationale in the task.
- [ ] Startup reads active task, current index and newest relevant WIP/handoff;
  log/history expands only for unresolved context. Remove ritual re-asking when
  the current request supplies answers. User authority remains controlling.
- [ ] Replace permanent prior-art flag semantics with scoped evidence and
  assumption invalidation. Keep project summary flags as derived orientation;
  new architecture/constraints reopen relevant research, copy edits do not.
- [ ] Replace A/B/C-only behavior with presentation/integration/operations fields;
  preserve legacy labels as historical metadata with an explicit provisional
  mapping. Unknown dimensions remain unknown until they materially matter.
- [ ] Require success criteria and labeled mocks. Stakeholder pack reports
  demonstrated outcomes and production gaps, with evidence references.
- [ ] Review template carries failure question, findings, severity, disposition,
  owner and verification. Preserve user-selected model; native capability controls
  dispatch. Remove hardcoded personal vault dependence; keep useful lessons in
  `.planning/` and make external graduation opt-in.
- [ ] Run fixture assertions against task contract and use live agent trials for
  behavior; do not claim string-matching skill text proves agent compliance.
  Trial: no repeat question for supplied goal; scope change stales relevant gate;
  high-risk one-line edit receives appropriate review; mock demo is labeled.
- [ ] Parent reconciles copies and index state without rewriting history. Commit:
  `feat: scale workflow to uncertainty and acceptance evidence`.

## Task 6: Token efficiency and native model use

**Files:** extend `scripts/evaluate.py`, `evals/README.md`,
`tests/test_evaluate.py`; modify startup/dispatch guidance and `README.md`;
create `.planning/reviews/runtime-efficiency-results.md` during execution.

- [ ] Inventory instruction bytes and duplicated sections in the governed
  startup path. Report bytes as bytes; use native reported tokens for usage.
  Leave detailed phase material on demand and current task summaries small.
- [ ] Use direct native spawn parameters for Luna model/effort. No global config
  rewrite is needed. Use medium normally, high for Task 1/2/4 edge cases, low for
  mechanical synchronization; record actual values in measurements.
- [ ] Remove redundant orientation reads, broad tool dumps and unconditional
  three-scout fan-out when a bounded survey can answer the question. Keep scoped
  research and independent review for uncertainty that warrants them.
- [ ] Re-run baseline cases with identical rubric and comparable runtime/model
  settings. Record parent/children, retries, input/cached/output categories,
  compaction cost when exposed, wall time, recovery steps and failed acceptance.
- [ ] Compare native-only vs streamlined native workflow. Hold models fixed for
  the process comparison; model-effort experiments are a separate variable.
  Report median/range for repeated cases, failures and incomplete telemetry.
- [ ] Require all critical acceptance checks and zero unsupported done claims;
  no weaker outcome is counted as an efficiency gain. Treat 20% median total
  token reduction as an aspirational target, not an assertion or release blocker.
  Keep a useful reliability fix even if its token overhead is small and positive;
  disclose the tradeoff. Commit: `perf: reduce measured workflow overhead`.

## Task 7: CI, rollout and final verification

**Files:** create `.github/workflows/tests.yml`, `tests/run.sh`;
modify existing tests for portable stat behavior where necessary and README.

- [ ] `tests/run.sh` runs shell syntax, existing three shell suites, new temporary
  install test and `python3 -m unittest discover -s tests -p 'test_*.py'`.
  Tests use temporary repositories/homes; network-dependent installs are fixture
  stubbed. No model calls or credentials in CI.
- [ ] CI runs the offline suite on supported macOS and Linux images; differences
  such as BSD/GNU stat are handled in test helpers. Preserve existing safety tests.
- [ ] Fresh Luna reviewer checks recovery loss boundaries, legacy compatibility,
  permission/path handling, reduced-process risk and telemetry accounting.
  Parent resolves findings and reruns affected checks.
- [ ] Document local same-worktree recovery vs committed cross-machine handoff,
  opt-in hook install, native capabilities, uninstall/disable behavior and
  rollback by reverting coherent commits. Dry-run real-home changes only.
- [ ] Update wiki index, append log and create handoff snapshot with verification
  evidence. Local commits only; no push. Core work is complete when six strategic
  recommendations are covered and recovery/quality fixtures pass, even if the
  optional Jev experiment is deferred.

## Experiment E: Jev decision suggestions, only after baseline

**Files:** create `evals/jev-shadow.md`, `evals/jev-cases.json`, optionally
`scripts/jev_shadow.py` and `tests/test_jev_shadow.py` only if a live trial is
explicitly selected and API access is available.

- [ ] Define 24 synthetic labeled cases, split 12 calibration/12 holdout, balanced
  across process profile, assumption change, stage inconsistency and model/effort
  suggestion. Labels allow multiple acceptable answers where ambiguity is real.
- [ ] Compare simple rules and the current parent agent with Jev suggestions.
  Never let Jev advance a stage, waive a gate or change the selected runtime model.
- [ ] Live trial uses only synthetic feature JSON with typed outputs, timeout,
  bounded request count and explicit usage recording. Missing key skips cleanly.
  No repo/private transcript transmission and no compactor installation.
- [ ] Score missed required checks more heavily than unnecessary extra process.
  Reject adoption if any high-risk holdout case weakens required checks or if
  total task savings disappear after classification overhead/rework. Small sample
  success is preliminary and requires a longer opt-in trial before default use.
- [ ] File ADOPT/DEFER result with measurements. Default outcome without evidence:
  DEFER. This experiment is not a dependency of core delivery.

## Ponytail simplification gate

Applied before BUILD. Delete/defer list incorporated into this plan:

- No orchestration service, dynamic model router, database, daemon or dashboard.
- No transcript parser for every host; use explicit native inputs and refs.
- No giant shared machine state file; task records and per-session capsules have
  clear separate ownership. No automatic wiki rewrites from hooks.
- No timer process: debounce at existing events, with the limitation documented.
- No full-file backup system or automated replay of interrupted operations.
- No new cross-project vault integration; portable in-project lessons first.
- No multiple reviewer agents per tiny step; review meaningful milestones.
- No mandatory Jev, auto-compaction replacement or paid telemetry pipeline.
- No claim of savings from source length alone or a single successful model run.

## Plan self-review and execution boundary

All six strategic recommendations map to Tasks 1–6; regression protection and
rollout map to Task 7. Each runtime claim has a degraded mode. Recovery does not
claim to preserve unwritten reasoning or deleted working trees. Baseline precedes
instruction changes; optional classification follows measured improvements.

User selected Luna sub-agent execution. This artifact is the concrete plan for
review before implementation. Next step after review is Task 0, then Task 1 under
the normal BUILD prerequisites, not another choice of execution method.
