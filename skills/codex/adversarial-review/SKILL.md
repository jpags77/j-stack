---
name: adversarial-review
description: Runs a fresh-context, high-effort independent challenge of a named artifact or decision.
---

# adversarial-review

The primary session must name the artifact, decision, or diff under review.
When the current runtime supports it, create an isolated fresh-context Sol
reviewer at high effort. Give it an explicit challenge rubric covering
correctness, omissions, edge cases, security, operability, and alignment with
the stated requirements.

Return prioritized findings to the primary session, including evidence,
severity, and a recommended disposition. If fresh-context review is not
available, report that limitation rather than silently reviewing from the
current context. Do not create persistent independent-review artifacts
automatically; the primary session owns accepted decisions and writes them to
`.planning/`. Do not use credential-based external calls or paid API calls.
