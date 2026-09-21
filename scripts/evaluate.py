#!/usr/bin/env python3
"""Summarize explicit, sanitized evaluation records; never discovers runs."""

import argparse
import json
import math
import statistics
import sys
from collections import defaultdict
from pathlib import Path


class EvaluationError(ValueError):
    """Raised when an input record is ambiguous or internally inconsistent."""


FIELDS = {
    "run_id", "case_id", "variant", "runtime", "runtime_version", "model",
    "effort", "parent_run_id", "usage_scope", "input_tokens",
    "cached_input_tokens", "output_tokens", "reasoning_tokens",
    "reasoning_included_in_output", "wall_seconds", "retries",
    "unnecessary_questions", "acceptance_passed", "unsupported_done_claims",
    "recovery_steps", "source", "completeness",
}
COUNTS = ("input_tokens", "cached_input_tokens", "output_tokens", "reasoning_tokens",
          "retries", "unnecessary_questions", "unsupported_done_claims", "recovery_steps")
QUALITY_COUNTS = ("retries", "unnecessary_questions", "unsupported_done_claims", "recovery_steps")


def _validate_record(record, index):
    if not isinstance(record, dict):
        raise EvaluationError(f"run {index}: expected an object")
    missing = sorted(FIELDS - record.keys())
    if missing:
        raise EvaluationError(f"run {index}: missing fields: {', '.join(missing)}")
    extra = sorted(record.keys() - FIELDS)
    if extra:
        raise EvaluationError(f"run {index}: unknown fields: {', '.join(extra)}")
    for name in ("run_id", "case_id", "variant", "runtime", "runtime_version", "model", "effort", "source"):
        if not isinstance(record[name], str) or not record[name]:
            raise EvaluationError(f"run {index}: {name} must be a non-empty string")
    if record["parent_run_id"] is not None and not isinstance(record["parent_run_id"], str):
        raise EvaluationError(f"run {index}: parent_run_id must be a string or null")
    if record["usage_scope"] not in ("own", "aggregate"):
        raise EvaluationError(f"run {index}: usage_scope must be 'own' or 'aggregate'")
    if record["completeness"] not in ("complete", "partial", "unknown"):
        raise EvaluationError(f"run {index}: completeness must be complete, partial, or unknown")
    included = record["reasoning_included_in_output"]
    if included is not True and included is not False and included is not None:
        raise EvaluationError(f"run {index}: reasoning_included_in_output must be boolean or null")
    accepted = record["acceptance_passed"]
    if accepted is not True and accepted is not False and accepted is not None:
        raise EvaluationError(f"run {index}: acceptance_passed must be boolean or null")
    for name in COUNTS:
        value = record[name]
        if value is not None and (type(value) is not int or value < 0):
            raise EvaluationError(f"run {index}: {name} must be a non-negative integer or null")
    wall = record["wall_seconds"]
    if wall is not None and (type(wall) not in (int, float) or not math.isfinite(wall) or wall < 0):
        raise EvaluationError(f"run {index}: wall_seconds must be a finite non-negative number or null")
    if (record["input_tokens"] is not None and record["cached_input_tokens"] is not None
            and record["cached_input_tokens"] > record["input_tokens"]):
        raise EvaluationError(f"run {index}: cached_input_tokens exceeds input_tokens")


def _validated(records):
    by_id = {}
    for index, record in enumerate(records, 1):
        _validate_record(record, index)
        if record["run_id"] in by_id:
            raise EvaluationError(f"duplicate run_id: {record['run_id']}")
        by_id[record["run_id"]] = record
    for record in records:
        parent = record["parent_run_id"]
        if parent is not None and parent not in by_id:
            raise EvaluationError(f"run {record['run_id']}: unknown parent_run_id {parent}")
        if parent is not None:
            parent_record = by_id[parent]
            if (record["case_id"], record["variant"]) != (parent_record["case_id"], parent_record["variant"]):
                raise EvaluationError(
                    f"run {record['run_id']}: parent and child must share case_id and variant"
                )
    state = {}

    def visit(run_id):
        if state.get(run_id) == 1:
            raise EvaluationError(f"parent_run_id cycle includes {run_id}")
        if state.get(run_id) == 2:
            return
        state[run_id] = 1
        parent = by_id[run_id]["parent_run_id"]
        if parent is not None:
            visit(parent)
        state[run_id] = 2

    for run_id in by_id:
        visit(run_id)
    for record in records:
        if record["usage_scope"] == "aggregate":
            parent = record["parent_run_id"]
            while parent is not None:
                if by_id[parent]["usage_scope"] == "aggregate":
                    raise EvaluationError(
                        f"conflicting overlapping aggregates: {parent} and {record['run_id']}"
                    )
                parent = by_id[parent]["parent_run_id"]
    return by_id


def _included(records, by_id):
    """Keep own records; an aggregate record covers its entire descendant tree."""
    excluded = set()
    children = defaultdict(list)
    for record in records:
        if record["parent_run_id"] is not None:
            children[record["parent_run_id"]].append(record["run_id"])
    for record in records:
        if record["usage_scope"] != "aggregate":
            continue
        stack = list(children[record["run_id"]])
        while stack:
            child = stack.pop()
            excluded.add(child)
            stack.extend(children[child])
    return [record for record in records if record["run_id"] not in excluded]


def _sum(records, field):
    if not records:
        return None
    values = [record[field] for record in records]
    return sum(values) if all(value is not None for value in values) else None


def summarize(records):
    """Summarize selected records using null for any incomplete aggregate."""
    records = list(records)
    by_id = _validated(records)
    selected = _included(records, by_id)
    input_tokens = _sum(selected, "input_tokens")
    cached_tokens = _sum(selected, "cached_input_tokens")
    output_tokens = _sum(selected, "output_tokens")
    reasoning_tokens = _sum(selected, "reasoning_tokens")
    uncached_tokens = (input_tokens - cached_tokens
                       if input_tokens is not None and cached_tokens is not None else None)
    canonical_parts = []
    usage_complete = bool(selected) and all(record["completeness"] == "complete" for record in selected)
    for record in selected:
        parts = [record["input_tokens"], record["output_tokens"]]
        if record["reasoning_included_in_output"] is False:
            parts.append(record["reasoning_tokens"])
        elif record["reasoning_included_in_output"] is None:
            parts.append(None)
        if any(part is None for part in parts):
            usage_complete = False
        else:
            canonical_parts.append(sum(parts))
    token_total = sum(canonical_parts) if usage_complete else None
    quality = {field: _sum(records, field) for field in QUALITY_COUNTS}
    acceptance_values = [record["acceptance_passed"] for record in records]
    if any(value is False for value in acceptance_values):
        acceptance = False
    elif acceptance_values and all(value is True for value in acceptance_values):
        acceptance = True
    else:
        acceptance = None
    wall = [record["wall_seconds"] for record in records]
    return {
        "run_count": len(records),
        "usage_record_count": len(selected),
        "input_tokens": input_tokens,
        "cached_input_tokens": cached_tokens,
        "uncached_input_tokens": uncached_tokens,
        "output_tokens": output_tokens,
        "reasoning_tokens": reasoning_tokens,
        "token_total": token_total,
        "usage_complete": usage_complete,
        "wall_seconds": sum(wall) if all(value is not None for value in wall) else None,
        **quality,
        "acceptance_passed": acceptance,
    }


def compare(before, after):
    """Compare two summaries; token categories remain distinct from money."""
    fields = ("input_tokens", "cached_input_tokens", "uncached_input_tokens",
              "output_tokens", "reasoning_tokens", "token_total", "wall_seconds",
              *QUALITY_COUNTS)
    result = {}
    for field in fields:
        left, right = before[field], after[field]
        result[f"{field}_delta"] = right - left if left is not None and right is not None else None
    result["acceptance_passed"] = after["acceptance_passed"]
    result["acceptance_regressed"] = before["acceptance_passed"] is True and after["acceptance_passed"] is False
    result["usage_complete"] = before["usage_complete"] and after["usage_complete"]
    return result


REPEAT_METRICS = (
    "input_tokens", "cached_input_tokens", "uncached_input_tokens",
    "output_tokens", "reasoning_tokens", "token_total", "wall_seconds",
    *QUALITY_COUNTS,
)


def _repeat_groups(records):
    """Return one record subtree per root run, retaining aggregate semantics."""
    children = defaultdict(list)
    by_id = {record["run_id"]: record for record in records}
    for record in records:
        if record["parent_run_id"] is not None:
            children[record["parent_run_id"]].append(record["run_id"])
    roots = [record for record in records if record["parent_run_id"] is None]
    groups = []
    for root in roots:
        run_ids, stack = [], [root["run_id"]]
        while stack:
            run_id = stack.pop()
            run_ids.append(run_id)
            stack.extend(children[run_id])
        groups.append([by_id[run_id] for run_id in run_ids])
    return groups


def _repeat_statistics(records):
    groups = _repeat_groups(records)
    summaries = [summarize(group) for group in groups]
    metrics = {}
    for field in REPEAT_METRICS:
        values = [summary[field] for summary in summaries]
        metrics[field] = (
            {"median": statistics.median(values), "range": [min(values), max(values)]}
            if values and all(value is not None for value in values) else None
        )
    return {"root_run_count": len(groups), **metrics}


def _comparability(case_groups, before_variant, after_variant, catalog_case_ids=None):
    before_cases = {case_id for case_id, variants in case_groups.items() if before_variant in variants}
    after_cases = {case_id for case_id, variants in case_groups.items() if after_variant in variants}
    paired = sorted(before_cases & after_cases)
    catalog = set(catalog_case_ids if catalog_case_ids is not None else case_groups)
    before_missing = sorted(catalog - before_cases)
    after_missing = sorted(catalog - after_cases)
    before_only, after_only = sorted(before_cases - after_cases), sorted(after_cases - before_cases)
    root_counts = {
        before_variant: {case_id: len(_repeat_groups(case_groups.get(case_id, {}).get(before_variant, []))) for case_id in catalog},
        after_variant: {case_id: len(_repeat_groups(case_groups.get(case_id, {}).get(after_variant, []))) for case_id in catalog},
    }
    root_runs_match = bool(paired) and all(
        root_counts[before_variant][case_id] == root_counts[after_variant][case_id]
        and root_counts[before_variant][case_id] > 0
        for case_id in paired
    )
    return {
        "comparable": not before_missing and not after_missing and root_runs_match,
        "paired_case_count": len(paired),
        "paired_cases": paired,
        "missing_cases": {before_variant: before_missing, after_variant: after_missing},
        "unpaired_cases": {before_variant: before_only, after_variant: after_only},
        "root_run_counts": root_counts,
        "root_runs_match": root_runs_match,
    }


def _quality_gate(before, after, is_comparable):
    reasons = []
    if not is_comparable:
        reasons.append("coverage_not_comparable")
    if not before["usage_complete"] or not after["usage_complete"]:
        reasons.append("usage_incomplete")
    acceptance = (before["acceptance_passed"], after["acceptance_passed"])
    if False in acceptance:
        reasons.append("acceptance_failed")
    elif None in acceptance:
        reasons.append("acceptance_unknown")
    claims = (before["unsupported_done_claims"], after["unsupported_done_claims"])
    if any(value is not None and value > 0 for value in claims):
        reasons.append("unsupported_done_claims")
    elif any(value is None for value in claims):
        reasons.append("unsupported_done_claims_unknown")
    return {"passed": not reasons, "reasons": reasons}


def _gated_comparison(before, after, comparability):
    gate = _quality_gate(before, after, comparability["comparable"])
    return {
        **compare(before, after),
        "comparability": comparability,
        "quality_gate": gate,
        "savings_eligible": gate["passed"],
    }


def _read_jsonl(path):
    records = []
    with open(path, encoding="utf-8") as stream:
        for line_number, line in enumerate(stream, 1):
            if not line.strip():
                continue
            try:
                records.append(json.loads(line))
            except json.JSONDecodeError as exc:
                raise EvaluationError(f"{path}:{line_number}: invalid JSON: {exc.msg}") from exc
    return records


def evaluate_files(runs_path, cases_path):
    records = _read_jsonl(runs_path)
    try:
        cases = json.loads(Path(cases_path).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise EvaluationError(f"cannot read cases JSON: {exc}") from exc
    if not isinstance(cases, list) or any(not isinstance(case, dict) or not isinstance(case.get("case_id"), str) for case in cases):
        raise EvaluationError("cases must be a JSON array of objects with case_id strings")
    case_ids = [case["case_id"] for case in cases]
    if len(case_ids) != len(set(case_ids)):
        raise EvaluationError("case catalog contains duplicate case_id values")
    _validated(records)
    unknown = sorted({record["case_id"] for record in records} - set(case_ids))
    if unknown:
        raise EvaluationError("runs refer to unknown cases: " + ", ".join(unknown))
    groups = defaultdict(lambda: defaultdict(list))
    for record in records:
        groups[record["case_id"]][record["variant"]].append(record)
    results = []
    for case in cases:
        variants = {variant: summarize(group) for variant, group in sorted(groups[case["case_id"]].items())}
        comparisons = {}
        case_groups = {case["case_id"]: groups[case["case_id"]]}
        if "baseline" in variants:
            for variant, summary in variants.items():
                if variant != "baseline":
                    comparisons[variant] = _gated_comparison(
                        variants["baseline"], summary,
                        _comparability(case_groups, "baseline", variant, [case["case_id"]]),
                    )
        repeat_statistics = {
            variant: _repeat_statistics(records)
            for variant, records in sorted(groups[case["case_id"]].items())
        }
        results.append({"case_id": case["case_id"], "variants": variants,
                        "repeat_statistics": repeat_statistics, "comparisons": comparisons})
    by_variant = defaultdict(list)
    for record in records:
        by_variant[record["variant"]].append(record)
    summaries = {variant: summarize(group) for variant, group in sorted(by_variant.items())}
    comparisons = {}
    if "baseline" in summaries:
        for variant, summary in summaries.items():
            if variant != "baseline":
                comparisons[variant] = _gated_comparison(
                    summaries["baseline"], summary,
                    _comparability(groups, "baseline", variant, case_ids),
                )
    return {
        "run_count": len(records), "case_count": len(cases),
        "variants": summaries, "comparisons": comparisons, "cases": results,
    }


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--runs", required=True, help="explicit JSONL run records")
    parser.add_argument("--cases", required=True, help="case catalog JSON")
    parser.add_argument("--json", action="store_true", help="emit machine-readable JSON")
    args = parser.parse_args(argv)
    if not args.json:
        parser.error("--json is required")
    try:
        report = evaluate_files(args.runs, args.cases)
    except (EvaluationError, OSError) as exc:
        print(f"evaluate.py: {exc}", file=sys.stderr)
        return 2
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
