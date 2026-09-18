# Codex-Native Runtime Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add opt-in managed global Codex policy installation, Codex-native j-stack skill installation, and a fresh-context adversarial-review skill without altering the Claude runtime.

**Architecture:** `templates/codex-global-policy.md` supplies a single managed global block. `install.sh` gains narrowly scoped Codex flags, a Python-based strict marker merger, and a Codex skill allowlist. A separate `skills/codex/` tree keeps Codex instructions independent from Claude-oriented sources while retaining `.planning/` as shared state.

**Tech Stack:** Bash installer, embedded Python 3 for atomic text merge and unified diffs, Markdown skills, Bash integration tests.

**Spec:** `.planning/vision/codex-global-runtime.md`

## Global Constraints

- `--codex-global` is explicit; `--codex-only` alone remains project-scoped.
- `--dry-run` is accepted only with `--codex-only --codex-global`; it never
  mutates a project, Codex home, Claude home, or external state.
- Never overwrite non-managed content in `~/.codex/AGENTS.md`.
- Malformed, mismatched, nested, or duplicate policy markers must leave the target untouched and fail nonzero.
- `--dry-run` must not mutate files and must print a unified diff for global-policy changes.
- Codex skill installation uses an explicit allowlist and never invokes Claude, a paid API, or `second-opinion`.
- Tests run with a temporary `HOME`; real `~/.codex` installation is outside this plan.

---

### Task 1: Managed global Codex policy and installer flags

**Files:**
- Create: `templates/codex-global-policy.md`
- Modify: `install.sh`
- Create: `tests/codex-global-config.sh`

**Interfaces:**
- Consumes: `templates/codex-global-policy.md`
- Produces: `merge_codex_global_policy` installer behavior invoked by `--codex-global`, and the flags `--codex-global` and `--dry-run`.

- [ ] **Step 1: Write the failing integration tests**

Create `tests/codex-global-config.sh` with helpers that create a `mktemp -d`
workspace and call the installer from a temporary target directory with:

```bash
fail() { echo "$*" >&2; exit 1; }
assert_contains() { grep -Fq -- "$2" "$1" || fail "missing $2"; }
assert_not_contains() { ! grep -Fq -- "$2" "$1" || fail "unexpected $2"; }
assert_count() {
  [ "$(grep -Fc -- "$2" "$1")" -eq "$3" ] || fail "wrong count for $2"
}
assert_fails() { "$@" && fail "expected command to fail: $*"; }
run_install() {
  (cd "$tmp_target" && HOME="$tmp_home" bash "$ROOT/install.sh" \
    --codex-only --codex-global --skip-codex --skip-verify)
}
run_dry_install() {
  (cd "$tmp_target" && HOME="$tmp_home" bash "$ROOT/install.sh" \
    --codex-only --codex-global --dry-run --skip-codex --skip-verify)
}
```

Test these observable contracts before changing `install.sh`:

```bash
# Existing personal text stays byte-for-byte around one installed block.
assert_contains "$global_agents" "# Personal rules"
assert_contains "$global_agents" "Always use my preferred formatter."
assert_count "$global_agents" "j-stack:codex-global-policy:start" 1

# An old valid managed block is fully replaced with the current template.
assert_not_contains "$global_agents" "old managed content"
assert_contains "$global_agents" "j-stack:codex-global-policy:start version=1"

# A second install is byte-identical.
first="$(cksum "$global_agents")"
run_install
[ "$first" = "$(cksum "$global_agents")" ]

# A malformed marker leaves content unchanged and reports failure.
before="$(cksum "$global_agents")"
assert_fails run_install
[ "$before" = "$(cksum "$global_agents")" ]

# --dry-run writes no file and emits unified-diff headers.
printf '%s\n' '# Personal rules' \
  '<!-- j-stack:codex-global-policy:start version=0 -->' \
  'old managed content' \
  '<!-- j-stack:codex-global-policy:end -->' > "$global_agents"
before="$(cksum "$global_agents")"
dry_output="$(run_dry_install)"
[ "$before" = "$(cksum "$global_agents")" ] || fail "dry run changed AGENTS.md"
assert_contains "$dry_output" "---"
assert_contains "$dry_output" "+++"

# A dry run without the two Codex-only flags fails before any mutation.
assert_fails "$ROOT/install.sh" --dry-run
```

- [ ] **Step 2: Run the new test and verify it fails for the missing feature**

Run: `bash tests/codex-global-config.sh`

Expected: failure because `--codex-global`, `--dry-run`, the template, and
managed-marker installation do not yet exist.

- [ ] **Step 3: Add the global-policy template and minimal installer behavior**

Create `templates/codex-global-policy.md` containing only the Codex runtime
activation rule: use j-stack for coding, planning, design, and review work;
exclude pure Q&A, lookups, and one-off non-coding work; defer to repository
`AGENTS.md` and `.planning/` when present.

In `install.sh`:

1. Parse booleans for `--codex-global` and `--dry-run`, document them in the
   usage comment, and reject `--dry-run` unless both `--codex-only` and
   `--codex-global` were supplied.
2. Add a Codex global phase that runs only when `--codex-global` is set.
3. Pass the target path, template path, and dry-run boolean to a small inline
   Python program. It must count and validate marker pairs, append when there
   are none, replace one valid inclusive block, and reject all malformed
   layouts before opening a write path.
4. In dry-run mode, emit `difflib.unified_diff` and skip the atomic write.
5. In write mode, preserve existing mode bits, create a same-directory
   temporary file, replace atomically with `os.replace`, and print a concise
   status line.

The block written by the helper must wrap the template exactly:

```markdown
<!-- j-stack:codex-global-policy:start version=1 -->
<template content>
<!-- j-stack:codex-global-policy:end -->
```

- [ ] **Step 4: Run the focused integration test and verify it passes**

Run: `bash tests/codex-global-config.sh`

Expected: all preservation, replacement, idempotency, malformed-marker, and
dry-run cases pass.

- [ ] **Step 5: Commit the task**

```bash
git add install.sh templates/codex-global-policy.md tests/codex-global-config.sh
git commit -m "feat: install managed Codex global policy"
```

### Task 2: Codex-native skill source set and installer allowlist

**Files:**
- Create: `skills/codex/build-mode/SKILL.md`
- Create: `skills/codex/poc-wiki-init/SKILL.md`
- Create: `skills/codex/handoff-snapshot/SKILL.md`
- Create: `skills/codex/prior-art-survey/SKILL.md`
- Create: `skills/codex/stakeholder-pack/SKILL.md`
- Create: `skills/codex/adversarial-review/SKILL.md`
- Modify: `install.sh`
- Modify: `tests/codex-global-config.sh`
- Modify: `tests/codex-config.sh`
- Modify: `README.md`

**Interfaces:**
- Consumes: the global policy and existing `.planning/` schema.
- Produces: six installed directories under `~/.codex/skills/` and Codex-only
  user documentation.

- [ ] **Step 1: Extend the failing integration test for skill installation**

Add a test to `tests/codex-global-config.sh` that runs
`--codex-only --codex-global` under a temporary `HOME`, then asserts each
allowlisted directory contains a `SKILL.md`:

```bash
for skill in build-mode poc-wiki-init handoff-snapshot prior-art-survey stakeholder-pack adversarial-review; do
  [ -f "$tmp_home/.codex/skills/$skill/SKILL.md" ] || fail "missing $skill"
done
[ ! -e "$tmp_home/.codex/skills/second-opinion" ] || fail "Claude-only second-opinion copied"
assert_not_contains "$tmp_home/.codex/skills/adversarial-review/SKILL.md" "API key"
assert_not_contains "$tmp_home/.codex/skills/adversarial-review/SKILL.md" "claude"
```

- [ ] **Step 2: Run the focused integration test and verify it fails**

Run: `bash tests/codex-global-config.sh`

Expected: failure because no Codex skill source set or installer phase exists.

- [ ] **Step 3: Add Codex-native skills and the explicit installer allowlist**

Create each `skills/codex/<skill>/SKILL.md` with Codex-native instructions:

- `build-mode`: classifies whether work is j-stack-governed, reads the wiki,
  follows the phase pipeline, and excludes pure Q&A/non-coding work.
- `poc-wiki-init`, `handoff-snapshot`, and `stakeholder-pack`: retain their
  planning-file contracts but remove Claude-specific terminology.
- `prior-art-survey`: uses Codex-native research and isolated reviewers when
  available; it reports a clear capability limitation rather than mentioning
  Claude agent definitions.
- `adversarial-review`: names the artifact, creates an isolated fresh-context
  Sol reviewer at high effort when the current runtime supports it, requires a
  challenge rubric, returns prioritized findings to the primary session, and
  forbids automatic persistent review artifacts, API keys, and paid API calls.

In `install.sh`, define this exact allowlist and copy its directories into
`${HOME}/.codex/skills` only when `--codex-global` is selected:

```bash
CODEX_SKILLS=(build-mode poc-wiki-init handoff-snapshot prior-art-survey stakeholder-pack adversarial-review)
```

Validate every source directory before copying. Never reference or copy
`second-opinion` in this phase. Extend `tests/codex-config.sh` with static
assertions for the two flags, template, allowlist, and adversarial review.

- [ ] **Step 4: Run focused and existing checks**

Run:

```bash
bash tests/codex-global-config.sh
bash tests/codex-config.sh
bash tests/structure.sh
bash -n install.sh
git diff --check
```

Expected: every command exits zero.

- [ ] **Step 5: Commit the task**

```bash
git add install.sh skills/codex templates/codex-global-policy.md tests README.md
git commit -m "feat: add Codex-native j-stack skills"
```

### Task 3: Documentation and real-home safety boundary

**Files:**
- Modify: `README.md`
- Modify: `.planning/index.md`
- Modify: `.planning/log.md`
- Create: `.planning/handoffs/<timestamp>-snapshot.md`

**Interfaces:**
- Consumes: the passing temporary-`HOME` test suite and installer behavior.
- Produces: accurate user documentation and a durable blackboard checkpoint;
  it does not run the real-home installer.

- [ ] **Step 1: Write the failing documentation assertions**

Add static checks to `tests/codex-config.sh` for the documented command and
safety sequence:

```bash
assert_contains "$ROOT/README.md" "--codex-global"
assert_contains "$ROOT/README.md" "--dry-run"
assert_contains "$ROOT/README.md" "temporary-HOME"
assert_contains "$ROOT/README.md" "adversarial-review"
```

- [ ] **Step 2: Run the static test and verify it fails**

Run: `bash tests/codex-config.sh`

Expected: failure because the new command and review loop are undocumented.

- [ ] **Step 3: Document the Codex setup and checkpoint state**

Update the README to distinguish project-local `--codex-only` from opt-in
global `--codex-global`, show a dry-run command, explain managed-marker
preservation, list Codex-native skills, and explain the no-API-key
adversarial-review flow. State that the real `~/.codex` invocation follows
tests plus dry-run review and requires the user's explicit next command.

Update the planning index/log with implementation results. Generate a handoff
snapshot that records commits, verification commands, the user-controlled
real-home installation as the next action, and any unavailable native isolated
review capability.

- [ ] **Step 4: Run the complete verification suite**

Run:

```bash
bash tests/codex-global-config.sh
bash tests/codex-config.sh
bash tests/structure.sh
bash -n install.sh
git diff --check
git status --short
```

Expected: test and syntax commands exit zero; status contains only intended
documentation/checkpoint changes before the commit.

- [ ] **Step 5: Commit the task**

```bash
git add README.md .planning/index.md .planning/log.md .planning/handoffs
git commit -m "docs: document Codex global runtime"
```

## Ponytail Simplification Review

- **Delete:** a broad runtime abstraction or configuration registry. The
  installer needs one policy template, one strict merge helper, and one
  allowlist.
- **Delete:** fuzzy migration of existing global instructions. Managed markers
  are the only safe ownership signal.
- **Delete:** a persistent standalone adversarial-review artifact. Findings
  flow directly to the active session; that session records decisions when
  warranted.
- **Simplify:** make `--dry-run` a narrowly safe Codex-only command instead
  of a partial simulation of the default installer.
- **Keep separate:** the documentation/checkpoint task. It is independently
  reviewable because it prevents unsafe real-home installation and records
  the required handoff boundary.
