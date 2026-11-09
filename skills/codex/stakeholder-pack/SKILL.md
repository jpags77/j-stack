---
name: stakeholder-pack
description: Builds an executive-ready summary from j-stack planning and review artifacts.
---

# stakeholder-pack

Read the available vision, prior-art, design, security, implementation, and
independent-review artifacts under `.planning/`. Adversarial-review findings
are optional primary-session inputs, not a required independent artifact; state
missing inputs instead of hiding gaps. Synthesize why the approach was chosen,
alternatives, current architecture and evidence, security posture, production
gaps, and recommended next steps.

Write `.planning/stakeholder-pack/v<N>-<date>.md`, update `.planning/index.md`,
and append the event to `.planning/log.md`. Keep claims traceable to their
source artifacts and make the output suitable for a stakeholder review.
