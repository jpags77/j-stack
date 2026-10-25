---
name: project-reflection
description: Quiet, no-approval reflection on completed project work. Run at existing checkpoints (a substantial review finished, a hard failure resolved, a handoff) to record what the work taught as revisable observations in .planning/reflections.md. Writes nothing when nothing material was learned. Also supports a bounded, explicitly requested backfill over named existing records. Never edits CLAUDE.md, AGENTS.md, skills, or policy.
model: sonnet
---

# project-reflection

Keeps interpretation ("what did this teach us, and how sure are we") in `.planning/reflections.md`, apart from the chronology in `log.md`, plans, reviews, and handoffs. Those records stay as they are.

## When to run

Only at a checkpoint, and only if the work since the last checkpoint contained something worth learning:

- a substantial review (`/qa`, `/cso`, `/design-review`, `second-opinion`) just finished
- a difficult failure was resolved (more than one wrong turn, or a surprising cause)
- a handoff is being written (`handoff-snapshot` runs this first)
- the user asks, or asks for a **backfill** of named records (see below)

Do not run per turn, per commit, or on routine work. Do not spawn another agent for it; do it inline from what the session already knows.

**No recursion.** Edits to `reflections.md`, and the log line about them, are never evidence and never a trigger. This skill does not call `handoff-snapshot`.

**No approvals.** Write directly. The file is advisory, so a wrong entry is cheap to revise and a review queue is not.

## Process

1. **Read `.planning/reflections.md` first** (create it from the format below only if you are about to write an entry). If missing or empty and nothing is worth recording, stop.
2. **Gather evidence, narrowly.** Use the session's own context. Read only what a candidate needs: the changed planning record, one commit (`git show --stat <sha>`), one test result. Do not reread full histories, whole logs, or the source tree.
3. **Find candidates.** Worth recording: a failed assumption, an investigation approach that saved time, rework that was avoided or happened, a reusable snippet or tool that worked. Skip anything routine, incidental, or already recorded.
4. **Separate what happened from why.** `Observed` holds facts you can point at (a failing test, a commit, a measured result). `Explanation` holds the cause you think applies, labelled `unverified` unless a test, reproduction, or direct inspection confirmed it. A plausible story, a passing command that didn't exercise the claim, or an agent saying "fixed" is not verification. If you only have the story, say so.
5. **Reconcile with existing entries** (match by `Scope` and evidence, not wording):
   - already cited evidence, same conclusion → do nothing
   - a second, independent incident → add the evidence, may move `tentative` → `supported`
   - only a copy of an already-cited incident (handoff, log, review) → do nothing
   - narrower or different conditions → `narrowed`, state the new scope
   - contradicting evidence → `retracted` (or `superseded` by a new entry), keep the old text and say what changed
   - otherwise → new entry, `tentative`
6. **Write only if something changed.** Then add one `index.md` line for `reflections.md` if absent, and append `## [<timestamp>] reflection | <ids added/revised>` to `log.md`. If nothing changed, write nothing, including no log line.

## Rules for entries

- **One occurrence is tentative**, even if its cause was verified (record that in `Explanation`). Copies of the same incident in a log, a handoff, and a review are one occurrence. `supported` needs two independent incidents.
- **Generalize, keep the conditions.** Strip incidental names and paths; keep when it applies ("repos whose test fixtures share a global DB"). It's fine for a lesson to be local to one project.
- **Cite, don't invent.** Link records or commits. Include dates, and tool/model versions only when known. No made-up token counts, savings, or recurrence counts.
- **Snippets live where they are maintained.** Reference path, compatibility, and how it was verified. Do not paste code here.
- **Unfinished work is not a reflection.** Leave tasks in their existing tracker.
- **Advisory only.** Never promote an entry into CLAUDE.md, AGENTS.md, a skill, or a rule. A future reader should weigh an entry against current evidence and a stronger model's judgment.
- **Human text is read-only.** Anything in the file not written in the entry format below (free-form notes, someone else's entries) stays byte-for-byte. To disagree with it, add your own entry with `Relates: <heading>`.
- **Revise, don't rewrite.** Edit only your own entries; keep dated lines in `History`.

## Format

Free-form text is allowed anywhere. Entries this skill writes look like this, so the file stays readable by people and by a later cross-project reader:

```markdown
## R-short-slug: One-line claim
- Status: tentative | supported | narrowed | retracted | superseded
- Scope: when this applies (and what it was not tested against)
- Observed: what happened, as facts
- Explanation: why it probably happened. (unverified | verified: how)
- Evidence: `path#section` / `commit sha` / test name, with dates. Tools/models if known.
- Reuse: (optional) path to maintained snippet; compatibility; how verified
- Relates: (optional) other entry or heading
- History:
  - 2026-10-25 tentative: first seen
  - 2026-11-02 retracted: <counterevidence>, see <ref>
```

`R-` ids are stable; never renumber or reuse one.

## Backfill

Only when the user names the records (a file, a commit range, "the last N log entries" with N given). Process just those, in one run, then stop and report what was added. Never scan other repos or the whole history. Treat a record and its copies as one occurrence.
