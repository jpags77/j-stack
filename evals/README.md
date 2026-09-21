# Workflow and efficiency evaluations

This directory defines deterministic task cases and the explicit run-record
contract. `scripts/evaluate.py` only reads the files named on its command line;
it does not launch agents, inspect logs, or discover local run data.

## Recording runs

Write one JSON object per line, following [run.schema.json](run.schema.json).
Keep raw native run records local when they may contain private data. Commit
only sanitized summaries that contain no prompts, transcripts, secrets, or
user-specific paths. Use `null` for unknown measurements; do not estimate or
fill gaps from partial records.

`usage_scope` must be `own` when a record covers that run alone or `aggregate`
when it covers the run and its descendant work. Aggregate records replace the
whole descendant subtree in totals. Duplicate IDs, broken parent references,
cycles, nested overlapping aggregates, and ambiguous scope are rejected.

`reasoning_included_in_output` records native source semantics. When `true`,
reported output already includes reasoning and reasoning is not added again.
When `false`, separate reasoning tokens are added to the canonical total. A
missing flag or a missing category needed for the total makes the total `null`.
Reported input includes cached input where the source defines cached input as a
subset; cached and uncached input are reported separately. Token totals are
usage counts, not billed-dollar estimates.

## Report

Run:

```sh
python3 scripts/evaluate.py --runs path/to/runs.jsonl --cases evals/cases.json --json
```

The JSON report gives each case's summaries by variant and compares each
non-`baseline` variant to `baseline`. It includes input, cached input, uncached
input, output, reasoning, canonical token totals, wall time, retries,
unnecessary questions, unsupported completion claims, recovery steps, and
acceptance outcome. A missing value propagates as `null`; no cost field is
calculated. Aggregate usage scope affects token usage fields only. Per-run
quality outcomes include descendants so an aggregate parent's success cannot
hide a child's failed acceptance or unsupported completion claim. `wall_seconds`
is the sum of reported per-run durations; parent and child intervals can
overlap, so it is not necessarily elapsed task time. `usage_record_count`
distinguishes runs contributing token usage from total `run_count`.

Comparisons include `comparability`, `quality_gate`, and `savings_eligible`.
Global comparisons are eligible only when both variants cover every case in
the supplied catalog and have the same nonzero number of root runs per case.
Missing cases and root-run counts are listed by variant; `unpaired_cases`
identifies cases present on only one side. A root run (a record with no parent)
and all of its descendants form one repeat, so aggregate parents and their
children are not mistaken for separate repetitions. Per-case
`repeat_statistics` reports each metric's median and `[minimum, maximum]`
range; if any repeat's value is unknown, that metric's statistics are `null`.

`savings_eligible` is false unless coverage is comparable, token usage is
complete on both sides, both variants have known passing acceptance, and both
report zero unsupported completion claims. Numeric deltas remain descriptive
when this gate fails; they must not be presented as savings. This gate does not
replace the case acceptance assertions or human review.

The eight case descriptions in `cases.json` are evaluation prompts and
acceptance contracts, not claims that any live agent has already completed
them. Record runtime/version, model, effort, cache and usage provenance for
each run. Use one run per case for an initial pass; repeat variable cases at
least three times before reporting savings. Native token usage may be
unavailable: retain behavioral outcomes and state that token coverage is
incomplete.
