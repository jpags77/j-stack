---
name: adversarial-review
description: Runs a fresh-context, high-effort independent challenge of a named artifact or decision.
---

# adversarial-review

The primary session must name the artifact, decision, or diff under review.
When the current runtime supports it, issue exactly this native request: create
an isolated zero-history reviewer with `fork_turns: "none"`, using model
`gpt-5.6-sol` at `high` effort. Supply only the named artifact and this
challenge rubric: correctness, omissions, edge cases, security, operability,
and alignment with the stated requirements.

Return prioritized findings to the primary session, including evidence,
severity, and a recommended disposition. If fresh-context review is not
available, report that limitation rather than silently reviewing from the
current context. Do not create persistent independent-review artifacts
automatically; the primary session owns accepted decisions and writes them to
`.planning/`. Do not make API calls of any kind (all API calls are prohibited),
use the Claude CLI, use credential-based external calls, or use paid API calls.
If the native capability is unavailable,
report that limitation rather than substituting any of those paths.
