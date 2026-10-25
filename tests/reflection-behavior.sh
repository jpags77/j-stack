#!/usr/bin/env bash
# Behavioral check for skills/project-reflection. Opt-in: needs the `claude`
# CLI and spends model calls (about 7 short headless runs), and model output
# is not deterministic, so a failure means "inspect", not necessarily "broken".
# Triggering is covered separately by reflection-hook-e2e.sh.
# Each scenario builds a tiny throwaway repo, hands a fresh agent the skill
# plus a stand-in session summary, then asserts on the files it left behind.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="${ROOT}/skills/project-reflection/SKILL.md"
WORK="$(mktemp -d)"
FAILS=0
command -v claude >/dev/null || { echo "claude CLI not found" >&2; exit 2; }

pass() { echo "  ✓ $*"; }
fail() { echo "  ✗ $*" >&2; FAILS=$((FAILS+1)); }
count() { grep -c "$1" "$2" 2>/dev/null || true; }

mkrepo() { # $1 = name
  local d="${WORK}/$1"; mkdir -p "$d/.planning/reviews" "$d/.planning/handoffs"
  ( cd "$d" && git init -q && git config user.email t@t && git config user.name t
    printf '# Wiki Index\n\n## Current State\n**Phase:** BUILD\n' > .planning/index.md
    printf '# Activity Log\n\n## [2026-10-19 09:00] init | wiki bootstrapped\n' > .planning/log.md
    cat > .planning/reviews/qa-2026-10-20.md <<'EOF'
# QA 2026-10-20
test_export failed 3/3 when run right after test_import. Reproduced by running the
pair alone. Both write tmp/fixture.db. Fix (commit FIXSHA) gives each test its own
temp dir; the pair then passed 10/10 consecutive runs. Python 3.12, pytest 8.3.
EOF
    git add -A && git commit -qm "qa: export/import fixture collision; per-test temp dirs" )
  echo "$d"
}

run() { # $1=dir  $2=prompt ; transcript -> $1/.transcript.jsonl
  ( cd "$1" && timeout 300 claude -p "$2" --permission-mode acceptEdits \
      --allowedTools "Read Edit Write Bash(git:*) Bash(date:*) Skill" \
      --output-format stream-json --verbose < /dev/null > .transcript.jsonl 2>/dev/null )
}
PRE="Follow ${SKILL} (read it first) as a checkpoint reflection in this repo. Do not ask me anything; there is no one to approve. Session summary: "
INCIDENT="a substantial /qa review just finished. The test_export/test_import failure in .planning/reviews/qa-2026-10-20.md was reproduced and fixed, verified with 10 passing runs."
h() { sha256sum "$1" 2>/dev/null | cut -d' ' -f1; }

echo "1. supported lesson captured with scope + evidence"
D1="$(mkrepo s1)"; run "$D1" "${PRE}${INCIDENT}"
R="$D1/.planning/reflections.md"
if [ -f "$R" ]; then
  for k in "Status: tentative" "Scope:" "Observed:" "Explanation:" "Evidence:"; do
    grep -q "$k" "$R" && pass "has $k" || fail "missing $k"
  done
  grep -q "qa-2026-10-20" "$R" && pass "links the review" || fail "evidence does not link the review"
  [ "$(count '^## R-' "$R")" = 1 ] && pass "exactly one entry" || fail "entry count != 1"
  [ "$(count 'reflection |' "$D1/.planning/log.md")" = 1 ] && pass "one log line" || fail "log lines != 1"
else fail "no reflections.md written"; fi

echo "4. rerun on unchanged evidence + duplicated handoff copy add nothing"
BEFORE="$(h "$R")"; run "$D1" "${PRE}${INCIDENT}"
[ "$(h "$R")" = "$BEFORE" ] && pass "identical file after rerun" || fail "file changed on rerun"
cat > "$D1/.planning/handoffs/2026-10-21T1000-snapshot.md" <<'EOF'
# Handoff
Claim C1: test_export/test_import collided on tmp/fixture.db; fixed with per-test temp dirs (see qa-2026-10-20).
EOF
run "$D1" "${PRE}a handoff was just written; it restates the earlier export/import incident."
[ "$(count '^## R-' "$R")" = 1 ] && pass "still one entry" || fail "entry count changed"
grep -q "Status: tentative" "$R" && pass "still tentative (copy is not corroboration)" || fail "status moved"
[ "$(count 'reflection |' "$D1/.planning/log.md")" -le 2 ] && pass "no log spam" || fail "log spam"

echo "2. plausible unverified cause stays uncertain"
D2="$(mkrepo s2)"; run "$D2" "${PRE}a hard failure was just resolved. A migration test failed for about 40 minutes of guessing; then I bisected the last 12 commits and found the breaking commit in 5 minutes (commit 3fa91c2 renamed a column). I think my earlier guesses failed because the ORM caches the schema, but I never tested that."
R2="$D2/.planning/reflections.md"
if [ -f "$R2" ]; then
  pass "entry written for the successful strategy"
  grep -i "^- Explanation:.*cach" "$R2" | grep -viqE "unverified|not verified|untested|not tested|not confirmed|never tested" && fail "an Explanation states the cache theory without marking it unverified" || pass "cache theory not asserted as fact"
  grep -iq "^- Explanation:.*cach" "$R2" && pass "cache theory recorded as an Explanation" || echo "  (note: no Explanation mentions the cache theory)"
  grep -q "Status: tentative" "$R2" && pass "tentative" || fail "not tentative"
  grep -q "3fa91c2" "$R2" && pass "cites the commit" || fail "commit not cited"
else fail "no entry written for a clear successful strategy"; fi

echo "3. routine work produces no change"
D3="$(mkrepo s3)"; L="$(h "$D3/.planning/log.md")"; run "$D3" "${PRE}a checkpoint after renaming one variable and fixing a README typo. Tests passed. Nothing surprising happened."
[ ! -f "$D3/.planning/reflections.md" ] && pass "no reflections.md created" || fail "created reflections.md for routine work"
[ "$(h "$D3/.planning/log.md")" = "$L" ] && pass "log unchanged" || fail "log changed"

echo "5. counterevidence revises, keeping provenance"
D5="$(mkrepo s5)"
cat > "$D5/.planning/reflections.md" <<'EOF'
# Reflections

## R-shared-fixture-db: Parallel-looking test failures come from a shared fixture DB
- Status: tentative
- Scope: pytest suites whose fixtures write to one shared path
- Observed: test_export failed 3/3 right after test_import; passed 10/10 after per-test temp dirs
- Explanation: both tests write tmp/fixture.db (verified: failure reproduced in isolation)
- Evidence: `.planning/reviews/qa-2026-10-20.md`, 2026-10-20
- History:
  - 2026-10-20 tentative: first seen
EOF
git -C "$D5" add -A && git -C "$D5" commit -qm seed
run "$D5" "${PRE}new evidence on 2026-10-24: the same export/import failure came back with per-test temp dirs already in place. A trace showed test_import monkeypatches a module-level clock that leaks into test_export; the temp-dir change only coincidentally helped. Verified by a reproducing test and a fix; 20 passing runs."
R5="$D5/.planning/reflections.md"
grep -Eq "Status: (retracted|narrowed|superseded)" "$R5" && pass "status revised" || fail "status not revised"
grep -q "tmp/fixture.db" "$R5" && pass "original claim retained" || fail "original text lost"
grep -q "2026-10-24" "$R5" && pass "dated revision recorded" || fail "no dated revision"

echo "6. free-form and human-authored content survives"
D6="$(mkrepo s6)"
cat > "$D6/.planning/reflections.md" <<'EOF'
# Reflections

Jeff's rule of thumb: mocks hide integration bugs, so be suspicious of green unit tests.

## Why I distrust snapshot tests
They get regenerated without being read. Seen on three projects.
EOF
HUMAN_BEFORE="$(cat "$D6/.planning/reflections.md")"
run "$D6" "${PRE}${INCIDENT}"
R6="$D6/.planning/reflections.md"
python3 - "$R6" <<'PY' && pass "human text preserved verbatim" || fail "human text altered"
import sys
s=open(sys.argv[1]).read()
for frag in ["Jeff's rule of thumb: mocks hide integration bugs, so be suspicious of green unit tests.","## Why I distrust snapshot tests\nThey get regenerated without being read. Seen on three projects."]:
    assert frag in s, frag
PY
grep -q '^## R-' "$R6" && pass "new entry added alongside" || fail "no new entry"

echo
if [ "$FAILS" = 0 ]; then echo "All behavioral checks passed. Work dir: $WORK"; else echo "$FAILS check(s) failed. Inspect: $WORK"; exit 1; fi
