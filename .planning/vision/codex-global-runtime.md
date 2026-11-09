# Design: Codex-Native Global j-stack Runtime

Date: 2026-09-03
Status: approved for implementation planning

## Problem

The current Codex support configures a target repository's `AGENTS.md`, but it
does not install a global Codex policy, install Codex-native j-stack skills, or
provide a native independent-review loop. Existing custom skills are mostly
written for Claude Code and the `second-opinion` workflow depends on a
separate Codex CLI/API review that the user does not want to fund.

## Goals

- Give Codex a global, opt-in j-stack operating policy for coding, planning,
  design, and review sessions.
- Preserve all unrelated instructions in `~/.codex/AGENTS.md` and update the
  j-stack portion idempotently.
- Provide Codex-native custom skills under `~/.codex/skills` while retaining
  the existing Claude skill sources and installer behavior.
- Replace `second-opinion` in the Codex runtime with a fresh-context,
  high-effort Sol adversarial review that feeds findings immediately back to
  the active session.
- Prove installer behavior with temporary-`HOME` integration tests before any
  real Codex-home installation.

## Non-goals

- Do not change the existing default Claude runtime or delete its skills.
- Do not call paid external APIs or require an OpenAI API key.
- Do not automatically write an independent-review artifact; the primary
  session decides which findings to accept and writes only the resulting
  decisions or changes to `.planning/`.

## Global Policy

`templates/codex-global-policy.md` is the sole source for the global policy.
The installer exposes an explicit `--codex-global` flag; `--codex-only`
remains project-scoped and does not modify the user's global Codex home unless
combined with that flag.

The installed content is delimited by a single versioned marker pair:

```markdown
<!-- j-stack:codex-global-policy:start version=1 -->
...managed content...
<!-- j-stack:codex-global-policy:end -->
```

The policy activates j-stack only for coding, planning, design, or review
work. It explicitly excludes pure Q&A, lookups, and one-off non-coding work.
It directs applicable work to the repository's `AGENTS.md` and `.planning/`
blackboard; repository-local instructions remain more specific.

### Safe merge contract

1. With no markers, append one managed block without changing surrounding
   user content.
2. With exactly one valid pair, replace only the inclusive managed block.
3. With missing, mismatched, nested, or duplicate markers, fail without
   writing and explain the repair needed.
4. Write via a temporary file in the same directory and atomic replacement,
   preserving existing file permissions.
5. `--dry-run` prints the proposed unified diff and performs no writes.

No heading-based or fuzzy migration is attempted. Marker ownership is the only
safe update contract.

## Codex Skill Set

Create a separate Codex skill source directory, copied by an explicit
installer allowlist into `~/.codex/skills`. The Claude sources under `skills/`
remain unchanged. Codex skills retain the shared `.planning/` schema but use
Codex tools and terminology rather than Claude slash commands, Claude hooks,
or Claude agent definitions.

The Codex set contains:

- `build-mode`
- `poc-wiki-init`
- `handoff-snapshot`
- `prior-art-survey`
- `stakeholder-pack`
- `adversarial-review`

`adversarial-review` replaces `second-opinion` only in the Codex set. It
receives a named artifact or decision, launches an isolated high-effort Sol
reviewer with a fresh context and an explicit challenge rubric, and returns a
prioritized report to the primary session. The primary session evaluates and
incorporates accepted feedback immediately; it owns all persistent planning
writes and verification.

The Codex implementation should use the current session's native isolated
reviewer/task capability when available. If it is unavailable, it must report
that the requested fresh-context review cannot be performed rather than
silently reviewing from the current context or falling back to an API call.

## Installer and Tests

`install.sh` gains `--codex-global` and `--dry-run`, plus a Codex skill-install
phase. Test coverage is a behavioral temporary-`HOME` script, covering:

- append while preserving personal global instructions;
- exact replacement of an old managed block;
- byte-identical idempotent reruns;
- refusal and non-mutation for malformed markers;
- dry-run non-mutation and diff output;
- installation and update of the explicit Codex skill allowlist;
- absence of Claude CLI/API-key requirements in the Codex adversarial-review
  path.

The real `~/.codex` installation occurs only after these tests pass and its
dry-run diff is reviewed.

## Simplification Review (Ponytail Gate)

Defer a general runtime abstraction, configuration registry, automatic legacy
text migration, and persistent reviewer artifacts. The first implementation
needs one template, one strict merge helper, one explicit skill allowlist, and
one integration test harness. Separate Claude and Codex skill sources are
intentional: their execution tools differ enough that forced shared wording
would conceal incompatible instructions.
