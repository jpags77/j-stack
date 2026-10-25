---
name: poc-wiki-init
description: Bootstraps a markdown-wiki memory layer for a new PoC engagement. Creates the directory structure under .planning/, generates per-tool schema files (CLAUDE.md, AGENTS.md, .cursor/rules), initializes index.md and log.md with proper conventions, and optionally configures a private git remote for cross-machine portability. Activates whenever a new PoC engagement begins or when an existing project lacks .planning/ infrastructure. Used to enable cross-tool handoff when Anthropic usage limits force a switch to Codex / Cursor / ChatGPT / Gemini mid-engagement.
model: haiku
---

# poc-wiki-init

## When to activate

Run when starting a new PoC engagement, or when joining an existing project that lacks `.planning/` infrastructure. Idempotent — running on a project that already has `.planning/` reports current state and exits without overwriting.

## Why this exists

The same wiki must be readable by Claude Code, Codex CLI, Cursor, ChatGPT, and Gemini. Each tool reads its own schema file (CLAUDE.md, AGENTS.md, etc.), but the wiki content is one source of truth. When Claude usage limits force a tool switch mid-PoC, the new tool reads the wiki and resumes — no re-explanation needed.

## Process

### 1. Detect existing state

Check whether `.planning/` exists in the project root:
- If it does not: proceed to step 2.
- If it does: read `index.md`, summarize current state to the user, and exit. Do not modify.

### 2. Capture fidelity target

Before creating any files, ask:

"What level of functionality are we targeting for this engagement?
  A) Working PoC — functional core logic, real integrations, key edge cases handled, something that can be built upon
  B) Polished demo — looks great and works on the happy path, mocked data acceptable
  C) MVP — production-ready enough to put in front of real users"

Record the answer. It will be written into `index.md` in step 4. This answer governs how every phase is executed — it is not cosmetic.

### 3. Create directory structure

```
.planning/
├── index.md
├── log.md
├── CLAUDE.md
├── AGENTS.md
├── .cursor/
│   └── rules
├── chatgpt-brief.md
├── vision/
├── prior-art/
├── plans/
├── reviews/
├── stakeholder-pack/
├── handoffs/
└── raw/
```

### 4. Generate stub files

**index.md** — content-oriented catalog. Initial content:

```markdown
# Wiki Index

One-line summary of every page in this wiki. Update on every page creation.

## Current State

**Iteration:** 1
**Phase:** Not started — run session-start at the beginning of each session
**Fidelity target:** [answer from fidelity question above — A/B/C and description]
**Last updated:** [current ISO timestamp]

## vision/
(empty — populate after /office-hours)

## prior-art/
(empty — populate after prior-art-survey)

## plans/
(empty — populate after writing-plans)

## reviews/
(empty — populate after /design-review, /cso, second-opinion)

## stakeholder-pack/
(empty — populate after stakeholder-pack)

## handoffs/
(empty — populate when switching tools)
```

**log.md** — append-only chronological record. Initial content:

```markdown
# Activity Log

Append-only. Format: ## [YYYY-MM-DD HH:MM] <operation> | <subject>

## [<current ISO timestamp>] init | wiki bootstrapped
```

**CLAUDE.md** — schema for Claude Code. Read `templates/lane-doctrine.md` (co-located next to this SKILL.md — the same file install.sh injects into a project's root CLAUDE.md/AGENTS.md) and use its content verbatim as the `## Stack ownership` / `## Wiki` / `## Cross-tool` / `## Work checkpoints` sections, followed by `templates/reflection-checkpoint.md` verbatim, rather than retyping them. Do not paraphrase or shorten it — a second copy is exactly the drift this convention exists to avoid. Full file:

```markdown
# Project Context for Claude Code

This project uses a markdown wiki at .planning/ as its single source of truth.

## Before any non-trivial work

1. Read .planning/index.md to understand existing state.
2. Read .planning/log.md to see recent activity.
3. Check .planning/handoffs/ for the most recent snapshot if one exists — another tool may have left state for you.

[insert templates/lane-doctrine.md verbatim here]

[insert templates/reflection-checkpoint.md verbatim here]
```

**AGENTS.md** — schema for Codex CLI. Read `templates/lane-doctrine.md`, `templates/reflection-checkpoint.md`, and `templates/codex-role.md` (co-located next to this SKILL.md) and insert them verbatim in that order. Full file:

```markdown
# Project Context for Codex CLI

This project uses a markdown wiki at .planning/ as its single source of truth.

## Before any work

1. Read .planning/index.md.
2. Read .planning/log.md for recent activity.
3. Read .planning/handoffs/ for the most recent snapshot - Claude Code or another tool may have left state for you to resume from.

## Phase pipeline

EXPAND -> REFINE -> SURVEY -> PLAN -> BUILD -> POLISH -> DEFEND -> HANDOFF

Respect the lane ownership from the root AGENTS.md/CLAUDE.md files. Do not skip ahead to implementation when the wiki says the project is still in an earlier phase.

[insert templates/lane-doctrine.md verbatim here]

[insert templates/reflection-checkpoint.md verbatim here]

[insert templates/codex-role.md verbatim here]
```

**.cursor/rules** — schema for Cursor:

```markdown
# Cursor Rules for this PoC

Wiki at .planning/ is single source of truth. Read .planning/index.md before any non-trivial work. Check .planning/handoffs/ for the most recent snapshot from another tool.

When producing notable output, file it back into .planning/ as a new page and update index.md.
```

**chatgpt-brief.md** — paste-into-ChatGPT primer:

```markdown
# ChatGPT Context Primer for this PoC

Paste this into ChatGPT before asking questions about the project.

---

This project lives in a markdown wiki under .planning/. The relevant pages are:

[List the current contents of .planning/index.md here. The poc-wiki-init skill should populate this dynamically when first run; subsequent updates happen via handoff-snapshot.]

When I ask you about this project, I will paste relevant pages from .planning/ into the conversation. Your job is to reason about them and produce output I can file back into the wiki.
```

### 5. Initialize git

If the project is not already a git repo, run `git init` and add `.planning/` to be tracked. If it is, just `git add .planning/` and commit with message `wiki: bootstrap .planning/ structure`.

### 6. Optional remote

Ask the user whether they want to push the wiki to a private remote for cross-machine portability. If yes, prompt for the remote URL, configure it, and push. If no, skip — they can add it later.

### 7. Update log.md

Append: `## [<timestamp>] init | wiki bootstrapped`

## Output

Confirm to the user: "Wiki bootstrapped at .planning/. Schema files in place for Claude Code, Codex, Cursor, and ChatGPT. Run session-start at the beginning of each session, then /office-hours to start the founder-lens reframe."