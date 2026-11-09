# j-stack strategic review

Date: 2026-09-20
Status: recommendations for discussion; no implementation or adoption authorized
Scope: repository workflow, skills, wiki and prior audit; not an external tooling survey

## Assessment

j-stack's strongest assets are problem framing, explicit alternatives, independent
review, and portable evidence in `.planning/`. Its main weakness is reliance on
agents to reconcile overlapping procedural instructions and manually synchronize
state. Improve the reliability of those contracts before adding more tools.

## Evidence from current files

- `skills/build-mode/SKILL.md` asks three startup questions on every session even
  when recorded context and the current request supply the answers.
- Its progress reconciliation treats artifact presence as completion. A vision
  document does not establish that a scope review occurred; source commits do
  not establish that acceptance criteria passed.
- It preserves prior-art completion across all iterations. Changed architecture
  or constraints can invalidate earlier research.
- `skills/poc-wiki-init/SKILL.md` combines functional PoC, polished demo, and MVP
  into one fidelity choice. Visual fidelity and operational readiness are
  independent dimensions.
- The index still describes the Codex global install as pending in one entry,
  while the September 18 handoff records completion. Historical snapshots are
  valid history, but current-state summaries need explicit supersession.
- The September 18 handoff and the current Codex blackboard template use different
  top-level shapes while both name `j-stack.handoff.blackboard.v1`.
- The README excludes production operations while describing an MVP target as
  production-ready; the delivery boundary needs an explicit readiness definition.
- The repository has shell tests but no `.github/workflows/` directory in this
  checkout. Installation checks alone do not establish workflow behavior.

## Priorities

1. **Durable recovery inside a turn.** Save task intent before substantial work;
   refresh a small semantic WIP note after meaningful discoveries, edits, tests,
   or decisions. Use supported runtime events to capture mechanical state after
   tool batches or mutations, with a time/tool-count bound. Completed-turn,
   failure, compaction, and session-end events supplement this. A single turn can
   contain substantial work, so the preceding Jev survey's completed-turn policy
   alone is insufficient. No hook can recover intent never externalized. Record
   pending versus completed actions and verify effects before retrying them.
   Keep raw transcripts local and separate from automatically committed wiki
   content. Store references to preserved work, not merely a diffstat.
2. **Small shared state contract.** Standardize and version the existing handoff
   schema; associate gates with task/iteration, acceptance criteria, evidence,
   reviewed revision, and status. Use pending/passed/failed/waived/stale rather
   than inferring success from a filename. Introduce a read-only doctor for
   schema and reference consistency. Avoid a new workflow engine or database.
3. **Proportional process.** Retain the phase model but define explicit reduced
   paths for maintenance, bounded changes, and new engagements. Reuse valid
   decisions; ask only about missing or conflicting information. Reopen research
   when its assumptions change, not on every edit or never again.
4. **Outcome-based quality.** Define the stakeholder decision the PoC must enable,
   the critical workflow, measurable success criteria, and permitted mocks before
   implementation. Record acceptance evidence against the implementation tested.
   Distinguish presentation fidelity, integration realism, and operational risk.
   Maintain baseline secret/data/access safeguards across all profiles.
5. **Focused review and learning.** Give independent reviewers a specific failure
   question plus requirements and evidence. Reconcile findings and their
   disposition, rather than treating reviewer agreement as truth. Record only
   reusable, supported lessons with applicability and limitations.
6. **Behavioral regression tests and efficiency measurement.** Add fixtures for
   interrupted recovery, stale plans, changed scope, absent capabilities, and
   cross-runtime handoff. Deterministic checks belong in CI; small agent trials
   measure behavior separately. Track recovery effort, rework, unsupported done
   claims, user interruptions, and total task cost. Establish a baseline before
   choosing model routing, compression, or delegation optimizations.

## Suggested sequence

First make recovery dependable and current state unambiguous. Then add a doctor
and small behavior suite. Next tune workflow profiles and acceptance gates using
those tests. Finally evaluate optional accelerators such as Jev against measured
task outcomes. Existing audit items N7, N9, and N13 align with this direction.

## Scope boundary

This review records recommendations only. Keep the existing phase policy until
a concrete revision is agreed. No skills, runtime hooks, installation settings,
or external services were changed by this review.
