---
name: build-mode
description: Enters j-stack build mode for product, PoC, or feature development. Reads (or bootstraps) the .planning/ wiki, orients on iteration and phase, confirms the fidelity target, surfaces scope changes, and dispatches the next pending phase step. Establishes j-stack as the governing pipeline for the session, with Superpowers skills as subcomponents. Use at the start of any session that will produce code, plans, designs, or reviews — and whenever a project has a .planning/ wiki. Not for pure Q&A, lookups, or one-off edits.
model: sonnet
---

# build-mode

Entering build mode means this session is governed by the j-stack pipeline. Announce
that you are entering it, then run the process below.

## Authority

j-stack governs the session. Superpowers skills are subcomponents, invoked at the phases
named below — do not let `superpowers:using-superpowers` drive session ordering. Its own
instruction-priority rules defer to user configuration, and this skill is that
configuration.

**Do not use:** `/autoplan`, `/plan-eng-review`. Both conflict with
`superpowers:writing-plans`.

## The pipeline

```
EXPAND → REFINE → SURVEY → PLAN → BUILD → POLISH → DEFEND → HANDOFF
```

| Phase | Skills | What happens |
|-------|--------|-------------|
| **Expand** | `/office-hours`, `/plan-ceo-review` | Founder-lens reframe. Are we solving the right problem? |
| **Refine** | `superpowers:brainstorming` | Structured pressure-test. Lock the approach before prior-art. |
| **Survey** | `prior-art-survey`, `/recall-learnings` | Three parallel scouts: OSS, libraries, patterns. Recall cross-project learnings for the stack. |
| **Plan** | `superpowers:writing-plans` | Full implementation spec, reviewed before any code runs. |
| **Build** | `superpowers:subagent-driven-development`, `/design-shotgun`, `/design-html`, `/recall-learnings` | TDD execution in isolated worktrees against the spec. |
| **Polish** | `/qa`, `/design-review`, `/cso` | Audit against spec, design review, OWASP/STRIDE security. |
| **Defend** | `second-opinion`, `stakeholder-pack` | Cross-vendor review, stakeholder pack assembled. |
| **Handoff** | `/document-release`, `handoff-snapshot`, `/graduate-learnings` | Docs from diff, wiki snapshot, learnings graduated to the vault. |

Name the phase you are in at the start of non-trivial work. Never skip a phase silently.

## Process

### 1. Check wiki exists

Look for `.planning/` in the project root.

- If absent: invoke `poc-wiki-init` now — do not stop, do not ask the user to run it
  separately. It is idempotent, asks the fidelity question, and creates the structure.
  Then continue with step 2.
- If present: proceed.

### 2. Read current state

Read these in order:

1. `.planning/index.md` — full file. Extract: current iteration, current phase, fidelity
   level, what's completed, and the `Prior-art:` flag from `## Current State`
   (`✅ complete` or `⬜ pending`).
2. `.planning/log.md` — last 15 entries. Extract: what happened last session, open
   decisions or blockers, which phase-step skills have run since the last iteration bump.
3. `.planning/handoffs/` — most recent file if any. Extract: next steps, continuation prompt.
4. Artifact scan — list `.planning/prior-art/`, `.planning/plans/`, `.planning/reviews/`,
   `.planning/stakeholder-pack/`. Presence or absence tells you which phase steps have
   run. This becomes the checklist in step 8.
5. Graphify check — look for `graphify-out/GRAPH_REPORT.md` in the project root. If
   present, the project has a knowledge graph; note it in the brief. Not required.

### 3. Detect engagement type

- **Greenfield:** no source files beyond scaffolding, or `index.md` says "new project"
- **Existing repo:** source files present, git history exists, or `index.md` describes
  ongoing work

If this is the **first session on an existing repo** (wiki just created, or
`## Current State` shows iteration 1 / phase "Not started"), ask before orienting:

1. "What's the goal for this engagement? (add a feature, fix bugs, refactor, security
   hardening, migrate, improve performance, other)"
2. "Are there constraints I should know about? (must not break X, specific stack,
   deadline, can't change the API)"
3. "What does 'done' look like — how will you know this engagement was successful?"
4. "Is there existing documentation, a spec, or prior decisions I should read first?"

If the codebase is large or unfamiliar, suggest `/graphify .` before SURVEY or PLAN — it
builds a structural knowledge graph subagents can query instead of reading files
individually. File the resulting `graphify-out/GRAPH_REPORT.md` into `.planning/vision/`.

Record answers in `index.md` under `## Engagement Context`. These shape how every phase
runs — they are not optional. Skip the questions if that section already has answers.

### 4. Build orientation summary

- **Iteration:** N (or "1 / first session")
- **Engagement type:** greenfield or existing repo
- **Goal:** from engagement context, or "not set"
- **Last phase completed / currently in phase**
- **Fidelity target:** working PoC / polished demo / MVP / not set
- **Last session summary:** 1–2 sentences from log.md
- **Open items:** unresolved decisions or blockers

### 5. Ask three questions

**Q1 — Scope or direction change?**
"Is there new feedback, stakeholder input, or scope change since last session?"

If yes, identify which phase the change requires re-entering:
- Core problem changed → EXPAND
- Approach or spec changed → PLAN
- Feature scope changed mid-build → BUILD
- UI direction changed → POLISH

**Q2 — Fidelity confirmation**

If recorded: "We're targeting [level]. Still correct?"

If not recorded: "What level of functionality are we targeting?
  A) Working PoC — functional core logic, real integrations, key edge cases handled
  B) Polished demo — looks great, works on the happy path, mocked data acceptable
  C) MVP — production-ready enough for real users"

Record or confirm in `index.md` under `## Current State`.

**Q3 — Session goal**
"What do we want to accomplish this session?" Record it in log.md.

### 6. Handle scope changes

If Q1 revealed one:

1. Append to `log.md`:
   `## [timestamp] change | iteration N→N+1 | [one-line reason]`
2. Update `## Current State` in `index.md`: bump the iteration, set the phase to the
   re-entry point from Q1, reset every `## Iteration Progress` line to ⬜ — **except**
   the SURVEY / prior-art line. Prior-art runs once per project lifecycle; the
   `Prior-art:` flag and its checklist line stay ✅ once set.
3. If the spec or plan is affected: archive the existing plan by leaving it in place
   (e.g. `plans/v1-spec.md` stays — never delete). Note that `plans/vN+1-spec.md` gets
   written when PLAN re-runs. Do not create it now — that belongs to
   `superpowers:writing-plans`.
4. Tell the user: "Iteration bumped to N+1. Re-entering [phase]. Existing plan archived
   as v[N]."

### 7. Record session start

Append to `log.md`:
`## [timestamp] build-mode | iteration [N] | phase: [current phase] | goal: [session goal]`

### 8. Compute progress, output brief, dispatch

**8a. Reconcile the `## Iteration Progress` checklist in `index.md`.**

`[auto]` steps — confirm from the wiki artifact. These signals are reliable because the
skill files a distinguishable artifact:

| Step | Artifact |
|------|----------|
| `office-hours` | `vision/` has a design doc |
| `prior-art-survey` | the `Prior-art:` flag in Current State (**authoritative**) |
| `writing-plans` | `plans/` has a plan for this iteration |
| `subagent-driven-development` | source commits since the plan |
| `second-opinion` | `reviews/second-opinion-*` |
| `qa` | `reviews/qa-*` |
| `design-review` | `reviews/design-*` |
| `cso` | `reviews/security-*` |
| `stakeholder-pack` | `stakeholder-pack/` non-empty |
| `handoff-snapshot` | `handoffs/` has a recent snapshot |

Artifact exists → ✅. Otherwise ⬜.

`[confirm]` steps (`plan-ceo-review`, `brainstorming`, `document-release`) leave no
reliable wiki trace. If one is still ⬜ and the current phase implies it should have run,
**ask**: "Has `/plan-ceo-review` run this iteration? I can't confirm it from the wiki."
Tick the line with their answer so you don't ask again.

Scope to the **current iteration** — an artifact or tick from a prior iteration does not
satisfy a step now. When evidence is ambiguous, treat the step as ⬜ and surface it. A
silently skipped step is the exact failure this catches.

Write the reconciled checklist back to `index.md`.

**8b. Output the orientation brief:**

```
SESSION ORIENTATION
───────────────────────────────────────────
Iteration : [N]
Phase     : [current phase]
Fidelity  : [level]
Prior-art : [✅ complete / ⬜ pending]
Graph     : ✅ graphify-out/ present — query with /graphify
            ← omit this line entirely when graphify-out/ is absent
Last session: [1-sentence summary or "first session"]
This session: [session goal]
[If scope changed]: Scope change recorded — re-entering [phase], prior plan archived as v[N].

[Current phase] progress (iteration [N]):
  ✅ [step that has run]
  ⬜ [step pending]   ← next
[If an earlier step in this phase was skipped]: ⚠ [step] never ran this iteration — recommend running it.
───────────────────────────────────────────
```

**8c. Dispatch the first pending (⬜) step** — do not wait for further instruction:

| Current phase | Dispatch to |
|---------------|------------|
| Not started / EXPAND | `/office-hours` |
| EXPAND (office-hours done, ceo-review pending) | `/plan-ceo-review` |
| REFINE | `superpowers:brainstorming` |
| SURVEY | `prior-art-survey`, then `/recall-learnings` |
| PLAN | `superpowers:writing-plans` |
| BUILD | `superpowers:subagent-driven-development` |
| BUILD — UI work in progress | `/design-shotgun` or `/design-html`, depending on whether directions are locked |
| POLISH — code review pending | `/qa` |
| POLISH — security pending | `/cso` |
| POLISH — design review pending | `/design-review` |
| DEFEND — cross-vendor review pending | `second-opinion` |
| DEFEND — stakeholder pack pending | `stakeholder-pack` |
| HANDOFF — docs pending | `/document-release` |
| HANDOFF — switching tools | `handoff-snapshot` |

**Prior-art gate (SURVEY before PLAN).** If the phase is PLAN, or you are about to
dispatch `superpowers:writing-plans`, and `Prior-art:` is `⬜ pending`, do NOT dispatch
writing-plans. Dispatch `prior-art-survey` first: "Prior-art hasn't run on this project —
running SURVEY before PLAN." This holds even when `superpowers:brainstorming` hands off
directly to planning in a single session. Prior-art runs at least once per project before
any implementation.

**Multi-step phases (POLISH, DEFEND, HANDOFF).** Dispatch the first ⬜ step. Always
surface skipped steps even if the recorded phase has moved on — "Heads up: we're in
POLISH but `/cso` has never run this iteration. Run it before DEFEND?" A later phase being
recorded does not mean every step of the current one completed.

If the session goal names a specific step ("run the security review"), honor that over the
default dispatch. If the phase is ambiguous, or the goal implies re-entering a different
phase than recorded, confirm before dispatching.

## Filing POLISH reports

`/qa`, `/cso`, and `/design-review` are general-purpose skills that do not write to the
wiki on their own. After each one completes in a project with `.planning/`:

- Save the report to `.planning/reviews/` — `/qa` → `qa-<date>.md`, `/cso` →
  `security-<date>.md`, `/design-review` → `design-<date>.md`
- Append a one-line entry to `.planning/log.md`
- Tick that step's line in `## Iteration Progress` in `index.md`

This is what makes the `[auto]` detection in 8a work, and it feeds `stakeholder-pack`,
which expects `security-*` and `design-*`.

## Wiki discipline

When a phase produces notable output — decisions, analyses, reviews — file it into
`.planning/` and update `index.md`. The wiki compounds; it is not just a log.

## Cross-project brain

`.planning/` is **intra-project** memory. The Obsidian vault at
`~/Documents/Obsidian/J-Vault` is **inter-project** memory: learnings that compound across
engagements.

- **Recall** at SURVEY and BUILD: `/recall-learnings`, scoped to the project's stack.
- **Graduate** at HANDOFF: `/graduate-learnings` writes durable learnings from
  `.planning/` into the vault's `Learnings/` folder. No approval gate.

## Cross-tool handoff

Approaching context limits or switching tools → run `handoff-snapshot`. It writes a
continuation prompt to `.planning/handoffs/` that Codex, Cursor, ChatGPT, or Gemini can
resume from. Per-tool schema files live in `.planning/`: `CLAUDE.md`, `AGENTS.md`,
`.cursor/rules`, `chatgpt-brief.md`.
