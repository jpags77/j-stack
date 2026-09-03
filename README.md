# j-stack

A Claude Code skill stack with a separate Codex runtime for agentic product development — from problem definition through a demo-ready, defensible deliverable.

---

## What this is and where it came from

The goal was specific: **encode agentic coding best practices into the early phases of product development** — the discovery, scoping, prior art, and planning work that happens before a line of code runs. These phases are where AI agents cause the most damage when left undisciplined. They build the wrong thing confidently, reinvent existing solutions enthusiastically, and skip the "is this the right problem?" question entirely.

The approach was to not build this from scratch. Before writing anything, the right move was to research what already existed — and that research is exactly what the `prior-art-survey` skill in this stack does. Practicing what we preach.

That survey found two projects already doing the hard parts better than a greenfield build would:

- **[Superpowers](https://github.com/obra/superpowers)** by [@obra](https://github.com/obra) — agentic coding discipline encoded as Claude Code skills: structured brainstorming, spec-locked planning, TDD enforcement, parallel subagents in isolated worktrees, verification before completion. The answer to every known agentic anti-pattern.
- **[gstack](https://github.com/garrytan/gstack)** by [@garrytan](https://github.com/garrytan) — a 40+ skill community pack covering the gaps Superpowers doesn't: founder-lens scoping, UI design workflow, security review, and QA.
- **[Andrej Karpathy](https://karpathy.ai)**'s second brain concept — the idea of a persistent, structured markdown wiki that outlives any single session or tool. Every decision, artifact, and handoff is written to `.planning/`. When AI usage limits force a tool switch mid-engagement, the new tool reads the wiki and resumes without re-explanation. The wiki speaks every tool's native language (CLAUDE.md, AGENTS.md, .cursor/rules, chatgpt-brief.md). This is the memory layer that makes the whole stack resilient.

j-stack is an integration layer on top of these foundations. It doesn't replace them — it cherry-picks the right skills from each, adds its own custom skills that fill remaining gaps (session orientation, the wiki itself, cross-vendor review, stakeholder packaging, and a prior-art research agent), wires them into a coherent pipeline, and configures session behavior so the whole thing runs without manual orchestration.

The insight Superpowers and gstack share: **AI agents are powerful but undisciplined.** The value isn't the models — it's the process imposed on them. j-stack applies that principle earlier in the lifecycle than either project does alone, covering the full arc from "are we solving the right problem?" through a security-reviewed, cross-vendor-validated, stakeholder-ready deliverable.

**Credit where it's due:** the core coding discipline belongs to @obra and @garrytan. The wiki architecture belongs to Karpathy. j-stack is configuration, integration, and the early-phase additions on top of their work.

---

## What we've put together — and why

### Superpowers — agentic coding discipline as a default

If you know Claude Code, you know the failure modes: agents that drift off-spec as context fills, implementations that "look right" but weren't test-driven, parallel subagents that clobber each other's work, half-finished features marked done. Good engineers solve these with process discipline. **[Superpowers](https://github.com/obra/superpowers)** is that discipline, encoded as skills.

Each skill is the answer to a known agentic coding anti-pattern:

| Skill | Anti-pattern it solves |
|-------|------------------------|
| `brainstorming` | Building the wrong thing perfectly. Forces structured pressure-testing of the product idea — *is this actually the right problem?* — before any engineering begins. |
| `writing-plans` | Spec drift. Locks a full implementation plan, reviewed by Opus, before a single line of code runs. Subagents implement against the spec, not against context that's 80k tokens deep. |
| `test-driven-development` | Code that looks right but isn't. Enforces red-green-refactor: tests are written first against the spec, implementation follows only when the test fails for the right reason. |
| `subagent-driven-development` | Sequential bottlenecks. Parallelizes implementation across multiple Claude instances, each with a bounded task from the spec. |
| `using-git-worktrees` | Parallel agents clobbering each other. Each subagent gets its own git worktree — isolated branch, clean working tree, no collisions. |
| `systematic-debugging` | Thrashing. Replaces "try random things until it works" with a structured hypothesis → reproduce → isolate → fix protocol. |
| `verification-before-completion` | Premature done. Claude verifies the task actually meets its acceptance criteria before marking it complete — not just "the code runs." |

Together these aren't features — they're **a baseline of agentic coding discipline** that most teams wing on every project. Superpowers makes them the default.

---

### gstack — specialized skills for the gaps Superpowers doesn't cover

**[gstack](https://github.com/garrytan/gstack)** is a community skill pack with 40+ tools. j-stack doesn't install it wholesale — that would conflict with Superpowers' planning lane and add adoption tax. Instead, 11 skills are cherry-picked for specific gaps: frontend scoping, UI work, security, QA, docs, and safety guardrails.

**Expand phase — Opus (judgment)**

| Skill | What it does | Why this one |
|-------|-------------|--------------|
| `/office-hours` | YC-style office hours. Challenges your assumptions about what you're building — *is this the right problem?* — before any engineering begins. | Highest-judgment moment in the pipeline. Reframes "what to build" as "what problem to solve." Opus only. |
| `/plan-ceo-review` | CEO/founder-lens scope challenge. Asks: is this the right scope? What's the minimum viable version? What would a 10x founder cut? | Pairs with `/office-hours` to pressure-test both the problem and the proposed solution before REFINE begins. |

**Polish phase — Sonnet (execution)**

| Skill | What it does | Why this one |
|-------|-------------|--------------|
| `/qa` | Systematic audit against a rubric — runs known user flows, checks edge cases, produces a structured findings report. | Not a vibe check. An audit against the spec. Runs after BUILD, before DEFEND. |
| `/design-shotgun` | Generates multiple design directions rapidly to explore the space before committing. | Used at the start of UI work. Avoids converging on the first idea. Feeds `/design-html`. |
| `/design-html` | Takes a mockup or design direction and converts it to production-quality HTML/CSS. | The execution skill for UI work. Pairs with `/design-shotgun` — explore, then build. |
| `/design-review` | Audits the implemented UI against design principles: consistency, hierarchy, accessibility basics. | Closes the loop on UI work after `/design-html`. Catches regressions before the demo. |
| `/cso` | Chief Security Officer mode. OWASP Top 10 + STRIDE analysis with findings by severity. | Security exploit reasoning is high-judgment work — Opus. Runs before DEFEND so the stakeholder pack has a real security section. |
| `/codex` | (Claude runtime) Orchestrates a shell-out to OpenAI Codex CLI. | Used internally by the Claude-only `second-opinion` custom skill; not part of the native Codex global skill set. |
| `/document-release` | Reads the diff and updates docs to match. | No manual documentation sprint at the end. Docs are a diff operation, not a writing assignment. |

**Safety — Haiku (mechanical)**

| Skill | What it does | Why this one |
|-------|-------------|--------------|
| `/freeze` | Locks specific files from editing. | Use alone when you just need finalized artifacts (specs, stakeholder docs) protected from mid-session edits, without changing anything else about how Claude works. |
| `/guard` | `/freeze` plus careful mode. | Use when file-locking alone isn't enough — e.g. protecting a live production config, where you also want the extra caution careful mode adds. |

Not redundant: `/guard` is a strict superset, but its careful-mode overhead isn't warranted for the common case of "don't touch this file" — that's `/freeze` alone.

**What was skipped and why:** `/autoplan` and `/plan-eng-review` overlap Superpowers' planning lane — two planners create conflicts. `/ship`, `/canary`, `/investigate`, and `/land-and-deploy` are prod-shipping tools; PoC mission doesn't need them. `/retro`, `/pair-agent`, and `gbrain` solve problems outside the PoC scope entirely.

---

### prior-art-survey — a net new addition

Neither Superpowers nor gstack ships a prior-art research agent. This is an original addition, bundled in this repo (the survey skill under `skills/`, the three scouts as agent definitions under `agents/`), and it fills a real gap: **AI agents are enthusiastic reinventors of wheels.**

`prior-art-survey` dispatches three parallel scout agents — each pinned to `model: sonnet` via its agent definition, so research never silently burns Opus tokens — before any implementation begins:

| Scout | What it searches | Why it matters |
|-------|-----------------|----------------|
| OSS scout | GitHub, package registries, known open-source projects | Finds existing solutions you could adopt or adapt instead of building |
| Library scout | Language-specific ecosystems (npm, PyPI, etc.) | Finds packages that solve the problem — or 80% of it |
| Patterns scout | Established architectural and design patterns | Ensures the approach fits recognized patterns, not just intuition |

The output isn't just research — it becomes the "what else did you consider" section of the stakeholder pack, and it's the primary defense against the classic enterprise objection: *"did you look at X before building this?"*

---

### Five custom skills — what doesn't exist anywhere else

| Skill | What it does |
|-------|-------------|
| `build-mode` | Session orientation ritual. Run at the start of every session — reads wiki state, confirms fidelity target, surfaces scope changes, handles iteration bumps, and declares the session goal before any work begins. Prevents silent drift between sessions. |
| `poc-wiki-init` | Bootstraps the `.planning/` wiki at project start. Asks the fidelity target question upfront, generates schema files for Claude Code, Codex, Cursor, and ChatGPT. Idempotent — safe to run again. |
| `handoff-snapshot` | Writes a timestamped blackboard snapshot to `.planning/handoffs/` with typed state, claims, provenance, conflicts, decisions, next steps, touched artifacts, and a paste-ready continuation prompt for the next tool. |
| `second-opinion` | (Claude runtime) Dispatches an artifact to Codex CLI for independent review, then synthesizes a convergence/divergence matrix. |
| `stakeholder-pack` | Aggregates vision, prior-art, security, and cross-model review outputs into a single executive-ready document. Pre-answers the five standard enterprise PoC questions. |

---

### Token optimization and the second brain

Anthropic is tightening usage limits, and burning Opus credits on mechanical work is a real cost. j-stack addresses this at three levels.

**Model routing by cognitive demand** is the first defense. The 11 cherry-picked gstack skills get an explicit model directive injected at install time; custom and bundled skills ship with their own `model:` frontmatter already set (prior-art-survey routes per-scout instead, via pinned-model Agent dispatch — see [Model routing](#model-routing) below):

- **Opus** — judgment calls: scoping, security reasoning, cross-model synthesis, stakeholder framing
- **Sonnet** — execution: implementation, audits, UI conversion, code review
- **Haiku** — mechanical operations: templating, summarizing, file locking

A full pipeline run spends Opus tokens where they move the needle and Haiku tokens on everything else.

**The `.planning/` wiki is the second defense** — and the emergency bailout. This is the same concept Andrej Karpathy describes with his Obsidian second brain: a persistent, structured external memory that outlives any single session or tool. Every decision, artifact, and handoff is written to markdown files in `.planning/`. The wiki speaks every tool's native language:

| File | Read by |
|------|---------|
| `.planning/CLAUDE.md` | Claude Code |
| `.planning/AGENTS.md` | Codex CLI |
| `.planning/.cursor/rules` | Cursor |
| `.planning/chatgpt-brief.md` | ChatGPT (paste-in) |

When Anthropic limits hit mid-engagement — and they will — `handoff-snapshot` writes a structured blackboard to `.planning/handoffs/`. It keeps the human continuation prompt, but also records machine-readable state: current phase, repo status, claims with provenance, confidence, open questions, conflicts between sources, and ordered next actions. Paste the continuation prompt into Codex, Cursor, or ChatGPT and the session resumes from the blackboard instead of reconstructing context from chat memory.

After significant code interactions, j-stack also treats commit + wiki update + handoff as the durable checkpoint. Local commits are appropriate once the diff is coherent; GitHub pushes are intentionally explicit and should happen only when the user asks or when a publish workflow is active.

**Headroom** is the third defense — context compression at named pipeline checkpoints. Large tool outputs (wiki reads at build-mode, prior-art scout returns, BUILD subagent transcripts, large file reads) are compressed before reasoning over them. The compressed form stays in context; the original is retrievable by hash if a specific detail is needed. Zero change to the workflow, measurable reduction in tokens-per-session.

---

## How it works

### The pipeline

```
EXPAND → REFINE → SURVEY → PLAN → BUILD → POLISH → DEFEND → HANDOFF
```

| Phase | Skills | What happens |
|-------|--------|-------------|
| **Expand** | `/office-hours`, `/plan-ceo-review` | Founder-lens reframe. Are we solving the right problem? What would a 10x founder cut? |
| **Refine** | `brainstorm` (SP) | Structured pressure-testing of the approach. Locked before prior-art begins. |
| **Survey** | `prior-art-survey` | Three parallel scouts: OSS, libraries, patterns. Answers "did you try X" before it's asked. |
| **Plan** | `writing-plans` (SP), `ponytail-review spec` | Full implementation spec, Opus-reviewed. Ponytail reviews the spec for YAGNI before BUILD starts — catch bloat before tokens are spent generating it. |
| **Build** | `subagent-driven-dev` (SP), `/design-shotgun`, `/design-html` | TDD execution. Parallel subagents in isolated worktrees, implementing against the spec. |
| **Polish** | `/qa`, `/design-review`, `/cso` | Audit against spec, design review, OWASP/STRIDE security analysis. |
| **Defend (Claude runtime)** | `second-opinion`, `stakeholder-pack` | An independent Codex CLI review is synthesized with the primary review. |
| **Handoff** | `/document-release`, `handoff-snapshot` | Docs generated from diff. Wiki snapshot written for cross-tool resumption. |

### Complete skill flow

Every session enters through `build-mode`, which reads wiki state and dispatches to the correct phase automatically.

```
build-mode  [custom · sonnet]  ← fires automatically when .planning/ exists (hook)
│
├── if no .planning/ wiki → poc-wiki-init  [custom · haiku]
│     ├── asks fidelity target (working PoC / polished demo / MVP)
│     └── if existing repo: asks goal, constraints, definition of done
│
├── orients: iteration / phase / fidelity / engagement goal
│
└── dispatches to current phase ↓

EXPAND
  /office-hours       [gstack · opus]   ← YC-style problem reframe
  /plan-ceo-review    [gstack · opus]   ← CEO/founder scope challenge

REFINE
  superpowers:brainstorming  [superpowers · opus]

SURVEY
  prior-art-survey    [custom · opus]
  ├── prior-art-oss-scout      [custom agent · sonnet]  ← parallel
  ├── prior-art-library-scout  [custom agent · sonnet]  ← parallel
  └── prior-art-patterns-scout [custom agent · sonnet]  ← parallel

PLAN
  superpowers:writing-plans  [superpowers · opus]
  ponytail-review spec       [ponytail · full]   ← spec gate: trim YAGNI before BUILD

BUILD
  superpowers:subagent-driven-development  [superpowers · sonnet]
  ├── superpowers:using-git-worktrees          ← isolated branch per subagent
  ├── superpowers:test-driven-development      ← red-green-refactor enforced
  ├── superpowers:verification-before-completion ← gates done claims
  └── superpowers:systematic-debugging         ← invoked when stuck
  /design-shotgun  [gstack · sonnet]  ← UI: explore directions
  /design-html     [gstack · sonnet]  ← UI: execute direction

POLISH  (build-mode checks log.md and dispatches to first pending)
  /qa             [gstack · sonnet]
  /design-review  [gstack · sonnet]
  /cso            [gstack · opus]

DEFEND
  second-opinion   [Claude-only custom · opus]
  └── /codex  [Claude runtime gstack · sonnet]  ← shells out to OpenAI Codex CLI
  stakeholder-pack [custom · opus]

HANDOFF
  /document-release  [gstack · sonnet]
  handoff-snapshot   [custom · haiku]  ← structured blackboard for tool switches and checkpoints

SAFETY / ON-DEMAND
  /freeze  [gstack · haiku]
  /guard   [gstack · haiku]
```

### SDLC coverage — the discovery-to-demo arc

j-stack covers the **discovery → demo arc** of the SDLC. What's deliberately out of scope is the production-ops side — deployment, monitoring, incident response — because PoC mission ≠ production mission.

| SDLC Phase | j-stack Stage | Engineering PM Principle |
|---|---|---|
| Product Discovery | EXPAND | *Are we solving the right problem?* Reframe before engineering begins. |
| Requirements & Ideation | REFINE | Structured pressure-testing before committing to an approach. |
| Feasibility / Build-vs-Buy | SURVEY | Named, reasoned alternatives. Every "did you try X" answered before the meeting. |
| Technical Design | PLAN | Spec locked before implementation. Explicit gate — nothing builds until this is done. |
| Development | BUILD | TDD enforced, parallel subagents, spec-bound execution. |
| QA & Security | POLISH | Definition of done against spec. Risk management as a deliverable. |
| Stakeholder Review | DEFEND | Pre-answered objections, cross-vendor validation. |
| Documentation & Handoff | HANDOFF | Docs from diff. Knowledge transfer built in, not bolted on. |

**Out of scope by design:** Deployment / Release ops · Monitoring / Observability · Incident response / Maintenance *(PoC mission ≠ production)*

### The five questions enterprise stakeholders always ask

j-stack produces artifacts that answer these before the meeting:

| Question | Artifact |
|----------|----------|
| Why did you build it this way? | Vision doc from `/office-hours` + `brainstorm` |
| What else did you consider? | `prior-art-survey` output (OSS, libraries, patterns) |
| Is it secure? | `/cso` OWASP/STRIDE security review |
| Does it actually work? | `/qa` audit against spec + TDD test suite |
| Why should I trust one AI vendor? | `second-opinion` cross-vendor convergence matrix (Claude runtime) |

All five are assembled by `stakeholder-pack` into a single document before the demo. The meeting shifts from "defend the work" to "discuss what's next."

---

## How to use it

### Prerequisites

**Claude runtime:**

- [Claude Code](https://claude.ai/code) installed (`which claude`)
- [Superpowers plugin](https://github.com/obra/superpowers) installed in Claude Code
- [Ponytail plugin](https://github.com/DietrichGebert/ponytail) installed in Claude Code (`/plugin marketplace add DietrichGebert/ponytail`)
- [Graphify](https://github.com/safishamsi/graphify) *(optional — run once after first BUILD sprint, refresh at major phase transitions)* `uv tool install graphifyy && graphify install`
- `prior-art-survey` + three scout agents (bundled in this repo — installed automatically by `install.sh`)

**Codex runtime:**

- [OpenAI Codex](https://github.com/openai/codex) available for the active session
- `AGENTS.md` in the target repo with the j-stack Codex runtime mapping (installed by `bash install.sh --codex-only`, or by the default installer)
- Optional global Codex policy and native skills: `bash install.sh --codex-only --codex-global`
- GitHub access for the repo: a configured `origin` remote, authenticated `git` push rights, and optionally the GitHub CLI or Codex GitHub connector for PR/issue context
- git, bash, python3, standard Unix tools

### Installation

```bash
git clone https://github.com/jpags77/J-Stack.git
cd J-Stack
bash install.sh
```

```bash
bash install.sh --codex-only    # only configure the Codex runtime (AGENTS.md + Codex check)
bash install.sh --skip-codex    # skip the Codex CLI check for Claude-only installs
bash install.sh --skip-verify   # skip post-install verification
```

The default script clones gstack, copies 11 cherry-picked skills into `~/.claude/skills/` with model directives injected, installs the 5 custom skills plus the bundled `prior-art-survey` (all from `skills/` files in this repo), installs the three scout agents into `~/.claude/agents/` (pinned to `model: sonnet`, honored by the Agent tool at dispatch), writes the project `CLAUDE.md` and `AGENTS.md` lane configuration, and merges a `SessionStart` hook into `~/.claude/settings.json` so `build-mode` fires automatically (see [Manual hook setup](#manual-hook-setup) if you don't have `python3`).

`--codex-only` skips the other runtime's CLI/plugin/skill/agent/hook installation. It checks for the Codex CLI, writes the project `AGENTS.md` runtime mapping, and verifies the Codex surface. Add `--codex-global` to install the opt-in global policy and the six native skills (`build-mode`, `poc-wiki-init`, `handoff-snapshot`, `prior-art-survey`, `stakeholder-pack`, and `adversarial-review`) under `~/.codex/`.

For a safe global-policy preview, run `bash install.sh --codex-only --codex-global --dry-run`. The dry run prints the proposed diff and writes nothing. Before any real `~/.codex` install, run the temporary-HOME tests (`bash tests/codex-global-config.sh` and `bash tests/codex-config.sh`), review the dry-run output, and then explicitly authorize the real command. The managed marker block is the only content j-stack owns: an existing valid block is replaced in place while unrelated instructions and file permissions are preserved; malformed or duplicate markers fail without mutation.

### Manual hook setup

`install.sh` uses `python3` to merge the `SessionStart` hook into `~/.claude/settings.json` without disturbing your existing settings. If `python3` isn't available, the installer skips this step and warns you — add the hook by hand. Merge this into the `hooks` object of `~/.claude/settings.json` (create the file with `{ }` if it doesn't exist):

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/build-mode-gate.sh",
            "statusMessage": "Loading j-stack session context..."
          }
        ]
      }
    ]
  }
}
```

Without the hook, j-stack still works — run `/build-mode` yourself — but the hook makes it deterministic rather than relying on the model honoring an instruction. The script stays silent unless the project has a `.planning/` wiki, so non-engagement sessions pay no context cost.

### GitHub integration

j-stack treats GitHub as the durable collaboration surface, not the memory layer. The memory layer is still `.planning/`; GitHub holds the reviewed commits, branches, pull requests, issues, and CI signal around that work.

Use this default flow:

```bash
git remote -v              # confirm origin points at the intended repo
git status --short         # inspect local/untracked work before edits
git checkout -b codex/...  # create a focused branch for non-trivial changes
```

After meaningful code or documentation work, checkpoint locally first:

1. Commit the coherent diff.
2. Update the relevant `.planning/` artifact and append `.planning/log.md`.
3. Run `handoff-snapshot` if switching tools, pausing, or handing work to another runtime.
4. Push only when the user asks or an explicit publish workflow is active.

Codex should prefer the GitHub connector for repository, issue, and pull request context, and local `git`/`gh` for branch state, commits, pushes, CI logs, and current-branch PR discovery. This keeps GitHub state, local checkout state, and the `.planning/` blackboard aligned.

### Codex runtime

j-stack treats Codex as a separate runtime through `AGENTS.md` and the `.planning/` wiki. Codex runs the same process directly from repo instructions and durable planning state, with its native skills installed only when explicitly requested.

- **Direct runtime mode:** open the repo in Codex intentionally. Codex reads `AGENTS.md`, `.planning/index.md`, `.planning/log.md`, and the latest `.planning/handoffs/` snapshot, then continues the current phase.
- **Fallback mode:** when Claude usage limits hit, open the repo in Codex and resume from the same `.planning/` state.
- **Review mode:** `adversarial-review` uses an isolated fresh-context reviewer when available for a spec, diff, or architecture decision. It returns prioritized findings to the primary session, which decides what belongs in `.planning/`.
- `adversarial-review` uses the native isolated review capability when available and requires no API key or paid API; if that capability is unavailable, it reports the limitation rather than falling back to an external API.

Codex does not need to run Claude slash commands directly. `AGENTS.md` maps those commands to equivalent Codex behavior while preserving the same phase order and wiki write-back rules.

To configure only this runtime in a repo:

```bash
bash install.sh --codex-only
# Optional global policy + Codex-native skills:
bash install.sh --codex-only --codex-global
```

Then start Codex in the repo. There is no Claude-style `SessionStart` hook for Codex in this stack today; the bootstrap contract is explicit: read `AGENTS.md`, then `.planning/index.md`, `.planning/log.md`, and the latest `.planning/handoffs/` snapshot before non-trivial work.

### Starting a new PoC or improving an existing repo

`build-mode` fires automatically at session start (via the `SessionStart` hook `install.sh` merges into `~/.claude/settings.json` — see [Manual hook setup](#manual-hook-setup) for the no-`python3` fallback). You don't run it manually.

**First session on a new project:**
```
1. Open Claude Code in your project directory
2. build-mode fires automatically
   ├── bootstraps .planning/ wiki (asks fidelity target)
   └── dispatches to /office-hours to begin EXPAND
3. Pipeline runs phase by phase from there
```

**First session on an existing repo:**
```
1. Open Claude Code in the repo
2. build-mode fires automatically
   ├── bootstraps .planning/ wiki
   ├── asks: goal, constraints, definition of done, prior docs
   └── dispatches to the right phase based on your answers
      (new feature → EXPAND, known spec → PLAN, bug fixes → BUILD, etc.)
```

**Every subsequent session:**
```
1. build-mode fires automatically
   ├── reads wiki: iteration / phase / fidelity / open items
   ├── confirms scope: "anything changed since last session?"
   ├── confirms fidelity target
   ├── asks session goal
   └── dispatches to current phase
```

**Iterative development:** Scope changes mid-engagement bump the iteration, identify which phase to re-enter, and archive the prior plan. You don't restart the pipeline; you re-enter at the right phase with the new input.

### What's NOT installed — and why

These were considered and explicitly rejected:

| Skipped | Reason |
|---------|--------|
| Graphify always-on | Build cost is zero but graph goes stale — run once after scaffolding exists, refresh at phase transitions, not every session |
| Full gstack install | Conflicts with Superpowers, adoption tax |
| gstack `/autoplan`, `/plan-eng-review` | Overlap Superpowers' planning lane |
| gstack `/investigate`, `/ship`, `/canary` | Prod-shipping discipline; out of PoC scope |
| LiteLLM gateway | Proxy complexity not worth it for one OpenAI shell-out |
| MCP-based memory | ~6K token tax per session; markdown wiki achieves the same goal |
| Headroom auto-compression | Compressing every tool call adds latency with no benefit on small outputs — checkpoint discipline at named pipeline moments is sufficient |
