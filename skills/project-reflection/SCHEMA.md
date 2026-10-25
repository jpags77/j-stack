# Reflections schema

Two files, two jobs:

| File | Written by | Holds |
|---|---|---|
| `.planning/reflections.md` | the model (via `project-reflection`) | interpretation: what the work taught, how sure we are, what it applies to |
| `.planning/metrics.jsonl` | the `reflection-gate` hook (a script) | measurement: tokens, subagents, models, time. The model never writes it |

Both are advisory. Neither is loaded into context automatically, and nothing in them is promoted into CLAUDE.md, AGENTS.md, skills, or policy. A reader should weigh an entry against current evidence and its own judgment.

Free-form text is allowed anywhere in `reflections.md`. Only blocks that follow the entry format below are machine-readable; everything else is human content and is never edited by the skill.

---

## 1. `reflections.md` entry

One entry is a level-2 heading plus a bullet list. Order is fixed; lines marked *(optional)* may be omitted.

```markdown
## R-<slug>: <one-line claim>
- Status: tentative | supported | narrowed | retracted | superseded
- Scope: <when this applies, and what it was not tested against>
- Observed: <what happened, as checkable facts>
- Explanation: <why it probably happened> (unverified | verified: <how>)
- Evidence: <links to records, commits, tests; dates; tool/model versions if known>
- Cost: <metrics ids and the measured figures that matter>            (optional)
- Reuse: <path to maintained snippet; compatibility; how verified>    (optional)
- Relates: <other entry id or heading>                                (optional)
- History:
  - <YYYY-MM-DD> <status>: <what happened to this entry and why>
```

### Fields

| Field | Rule |
|---|---|
| `R-<slug>` | Stable id. Lowercase words joined by hyphens. Never renumbered, never reused, even after retraction. |
| claim (heading text) | One sentence, generalized. No incidental paths or names unless they are the scope. |
| `Status` | See lifecycle below. |
| `Scope` | Applicability conditions. State what was *not* tested. A lesson may be local to one project. |
| `Observed` | Facts someone can point at: a failing test, a commit, a measured figure. No causes here. |
| `Explanation` | The proposed cause. Must end with `(unverified)` or `(verified: <how>)`. A plausible story, a command that did not exercise the claim, or an agent saying "fixed" is `unverified`. |
| `Evidence` | Repo-relative paths (`path#section`), commit shas, test names, dates. Add tool/model versions only when known. Copies of one incident (log, handoff, review) are one occurrence; cite the primary record. |
| `Cost` | Metrics ids (`M-…`) with the figures copied from `metrics.jsonl`. Never estimated. Omit when the cost is unremarkable. |
| `Reuse` | A pointer to a snippet in its maintained location, with compatibility and verification notes. Do not paste code. |
| `Relates` | Another entry's id when one refines, contradicts, or supersedes it. |
| `History` | Append-only, dated, one line per change. Oldest first. The first line is always `<date> tentative: first seen`. |

Do not invent missing metadata, token counts, savings, or recurrence counts. If a value is unknown, leave it out or say it was not measured.

### Status lifecycle

```
tentative ──(second independent incident)──▶ supported
tentative / supported ──(conditions differ)──▶ narrowed   (Scope rewritten, old Scope kept in History)
any ──(counterevidence)──▶ retracted                       (text kept, History says what changed)
any ──(replaced by a better entry)──▶ superseded           (Relates points to the replacement)
```

- A single occurrence is always `tentative`, even if its cause was verified.
- `supported` needs two **independent** incidents. Duplicate handoffs or log lines for the same incident do not count.
- `retracted` and `superseded` entries stay in the file with their original text, so the provenance of a wrong belief is visible.

### Idempotency

An entry is identified by its `Scope` and `Evidence`, not its wording. If the evidence it would cite is already cited and the conclusion is unchanged, nothing is written, and no log line is added. Rerunning over unchanged evidence produces no diff.

### Human-authored content

Anything that is not an `R-` entry is read-only to the skill. To disagree with a human note, add a new entry with `Relates: <that heading>`.

### Example (illustrative; the figures are made up)

```markdown
## R-shared-fixture-path: Order-dependent test failures may be tests sharing one fixture file
- Status: narrowed
- Scope: pytest suites where several tests write the same fixed path; not tested against in-memory fixtures
- Observed: test_export failed 3/3 when run after test_import; passed 10/10 once each test had its own temp dir (2026-10-20).
- Explanation: the second test saw state left by the first through the shared file. (verified: failure reproduced with the pair alone)
- Evidence: `.planning/reviews/qa-2026-10-20.md`; commit 3fa91c2; Python 3.12, pytest 8.3
- Cost: M-7275b278-2 (1 subagent, 48k tokens, 6m active); investigation by bisect rather than guessing
- Relates: R-leaked-module-clock
- History:
  - 2026-10-20 tentative: first seen
  - 2026-10-24 narrowed: a recurrence with per-test temp dirs traced to a leaked monkeypatched clock; the shared path is one cause, not the only one. See R-leaked-module-clock
```

---

## 2. `metrics.jsonl` record

One JSON object per line, appended at each checkpoint and at session end. All values are measured from Claude Code's session transcripts (and subagent transcripts). Usage is counted once per API call, not once per logged content block.

```json
{
  "id": "M-<session8>-<n>",
  "session": "<full session id>",
  "items": ["<evidence path or reason>", "..."],
  "window_start": "<ISO timestamp of first record in this window>",
  "window_end": "<ISO timestamp of last record in this window>",
  "elapsed_s": 0,
  "active_s": 0,
  "main_tokens": { "<model>": { "in": 0, "out": 0, "cache_read": 0, "cache_write": 0, "calls": 0 } },
  "subagent_tokens": { "<model>": { "in": 0, "out": 0, "cache_read": 0, "cache_write": 0, "calls": 0 } },
  "subagents": [
    { "type": "<agent type>", "model": "<model>", "description": "<first 60 chars>", "api_calls": 0, "tokens": 0, "seconds": 0 }
  ],
  "tool_calls": 0,
  "tool_errors": 0,
  "claude_code_version": "<x.y.z>"
}
```

| Field | Meaning |
|---|---|
| `id` | `M-` + first 8 chars of the session id + a per-session counter. Cited from `Cost:` lines. |
| `items` | What triggered the record: review/handoff paths, a struggle note, or `["session end"]`. |
| `window_*` | The slice of the session this record covers. Windows never overlap; each starts after the previous `window_end`. |
| `elapsed_s` | Wall-clock span of the window. |
| `active_s` | Sum of gaps between consecutive records that are 300 s or less. A stated heuristic, not attention time. |
| `main_tokens` / `subagent_tokens` | Per model. `in` = uncached input, `out` = output, `cache_read` and `cache_write` = prompt-cache tokens. Keep them separate; they are priced differently. |
| `subagents[].tokens` | `in + out + cache_read + cache_write` for that subagent in the window. |
| `tool_calls` / `tool_errors` | Distinct tool calls (main plus subagents) and failed tool results. |

Known limits: the transcript can lag the current turn, so the last turn may fall into the next window. Past sessions are not reconstructed. Only foreground subagents were verified.

---

## 3. For a later cross-project reader

- Entries are plain Markdown; split on `^## R-` and read the bullet keys above. Ignore any other block.
- Treat `Status`, `Scope`, and `(unverified)` as part of the claim. A `retracted` entry is evidence about what *not* to believe.
- Join `Cost: M-…` ids to `metrics.jsonl` by `id`. Compare like with like (same model, similar work); one window is an observation, not a baseline.
- Do not write back into a project's `reflections.md`. Put consolidated observations elsewhere and link the source entry ids.
