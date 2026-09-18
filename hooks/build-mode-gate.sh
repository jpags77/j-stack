#!/bin/bash
# SessionStart: nudge into j-stack build mode only for projects that have a .planning/ wiki.
# Silent everywhere else, so Q&A and one-off sessions pay no context tax.
input=$(cat)
dir=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)
dir=${dir:-${CLAUDE_PROJECT_DIR:-$PWD}}

[ -d "$dir/.planning" ] || exit 0

jq -nc --arg c "This project has a .planning/ wiki: it is a j-stack engagement. Invoke the build-mode skill before any coding, planning, design, or review work. Skip only for pure Q&A that produces no artifacts." \
  '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$c}}'
