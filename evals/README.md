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

The eight case descriptions in `cases.json` are evaluation prompts and
acceptance contracts, not claims that any live agent has already completed
them. Record runtime/version, model, effort, cache and usage provenance for
each run. Use one run per case for an initial pass; repeat variable cases at
least three times before reporting savings. Native token usage may be
unavailable: retain behavioral outcomes and state that token coverage is
incomplete.
