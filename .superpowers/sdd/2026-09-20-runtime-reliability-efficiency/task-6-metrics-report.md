# Task 6 evaluator metrics report

## Scope

Extended the offline evaluator only. It still reads explicit JSONL and case
catalog files; it does not launch agent trials, inspect runtime logs, infer
missing telemetry, or calculate billed costs. Parent owns the live paired
trials and workflow changes.

## Comparability and quality rules

- A comparison is coverage-comparable only when both variants have records for
  every case in the supplied catalog, every case has at least one root run, and
  both variants have the same number of root runs for each case. Root runtime,
  runtime version, model, and effort must be known and identical within and
  across variants for each case.
- Root runs are records with no parent. Each root plus its descendants is one
  repeat, preserving aggregate-usage de-duplication and descendant quality
  outcomes.
- Repeat statistics report median and min/max range for token categories,
  total tokens, wall time, and quality counts. A metric remains null if any
  repeat lacks that measurement.
- Savings eligibility requires comparable coverage, complete usage, known
  passing acceptance on both variants, and zero known unsupported completion
  claims on both variants. It also requires at least three root-run repeats per
  case. Failed or unknown quality/telemetry leaves numeric deltas descriptive
  only and never marks savings eligible; one- and two-run results are
  preliminary.

## Verification

Added regressions for asymmetric case coverage, unequal root-run counts,
repeat median/range, unknown repeat usage, unknown acceptance, unsupported
completion claims, and a successful paired comparison. Initial run failed on
the absent report contract. Parent review added regression coverage for
execution-setting mismatches and unknown settings, plus the three-repeat
eligibility threshold. The updated focused evaluator suite passed (28 tests)
and `git diff --check` passed.

No live trials were run in this scoped worker. Native token telemetry remains
unknown until the parent records trial data.
