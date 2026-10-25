# Prior-art survey: project-reflection

Date: 2026-10-25. Spec: task brief "Build a project reflection skill into j-stack". Scouts were not dispatched; one bounded inline pass (web search + two page fetches). The brief delegated the build/adopt decision ("record the reuse decision").

## What exists

| Option | Type | Covers | Doesn't cover | Maintenance / license |
|---|---|---|---|---|
| BayramAnnakov/claude-reflect | Claude Code plugin | Detects corrections via hooks, queues them, `/reflect` shows each for Apply/Edit/Skip, writes to CLAUDE.md files | No-approval operation; separate reflections file; evidence/uncertainty fields; Codex | MIT, ~1.9k stars, 97 commits (last-commit date not confirmed) |
| claude-code-continuous-learning-skill, retrospective / ia-reflect / lessons-learned skills (several) | Skills | Session review; friction/wins categories; some cite exchanges | Mostly user-confirmed, or write to CLAUDE.md / new skills; not checked individually for license or upkeep | Not verified |
| Codex built-in Memories | Native Codex feature | Background session summaries in `~/.codex/memories/` | Off by default, region-limited, machine-local, not project-scoped by default, Codex only; OpenAI says keep required guidance in AGENTS.md | Vendor feature; official page could not be fetched here, details from search snippets |
| Claude Code auto-memory | Native | Per-project notes | Not an evidence/uncertainty record; not shared with Codex | Vendor feature; not re-checked |
| Research (arXiv 2602.11988v3, 2604.14004, 2510.04618v3) | Context only | Mandatory repo context can raise cost without raising success; abstract insights transfer better than traces; curated evolving playbooks helped on benchmarks | Does not show savings for this workflow or future models | Not re-read in full |

## Decision: BUILD (thin)

Adopted ideas, not code: capture at checkpoints, separate evidence from interpretation, dedupe, dated revisions. The existing tools route learnings through an approval step or into CLAUDE.md-style instructions, which the brief rules out, and none targets a `.planning/` wiki shared by Claude Code and Codex. One ~80-line skill plus a 3-line checkpoint section reuses j-stack's existing plumbing (handoff-snapshot, templates, installer). No new service, hook, database, or agent.
