import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from evaluate import EvaluationError, compare, evaluate_files, summarize


def run(**changes):
    record = {
        "run_id": "r1",
        "case_id": "bounded-correction",
        "variant": "baseline",
        "runtime": "codex",
        "runtime_version": "test-runtime",
        "model": "test-model",
        "effort": "medium",
        "parent_run_id": None,
        "usage_scope": "own",
        "input_tokens": 100,
        "cached_input_tokens": 20,
        "output_tokens": 30,
        "reasoning_tokens": 10,
        "reasoning_included_in_output": True,
        "wall_seconds": 4.0,
        "retries": 0,
        "unnecessary_questions": 0,
        "acceptance_passed": True,
        "unsupported_done_claims": 0,
        "recovery_steps": 0,
        "source": "native-export",
        "completeness": "complete",
    }
    record.update(changes)
    return record


class SummarizeTests(unittest.TestCase):
    def test_missing_usage_is_unknown(self):
        report = summarize([run(input_tokens=None)])
        self.assertIsNone(report["input_tokens"])
        self.assertEqual(report["usage_complete"], False)
        self.assertIsNone(report["token_total"])

    def test_no_runs_does_not_claim_zero_usage(self):
        report = summarize([])
        self.assertIsNone(report["input_tokens"])
        self.assertIsNone(report["token_total"])
        self.assertFalse(report["usage_complete"])
        self.assertIsNone(report["acceptance_passed"])

    def test_aggregate_parent_not_double_counted(self):
        records = [
            run(run_id="p", usage_scope="aggregate", input_tokens=100),
            run(run_id="c", parent_run_id="p", input_tokens=40),
        ]
        self.assertEqual(summarize(records)["input_tokens"], 100)

    def test_excluded_reasoning_is_added_once(self):
        report = summarize([run(reasoning_included_in_output=False)])
        self.assertEqual(report["token_total"], 140)

    def test_included_reasoning_is_not_added_twice(self):
        report = summarize([run()])
        self.assertEqual(report["token_total"], 130)

    def test_unknown_reasoning_semantics_makes_total_unknown(self):
        report = summarize([run(reasoning_included_in_output=None)])
        self.assertIsNone(report["token_total"])
        self.assertFalse(report["usage_complete"])

    def test_partial_source_cannot_be_reported_as_complete_usage(self):
        report = summarize([run(completeness="partial")])
        self.assertIsNone(report["token_total"])
        self.assertFalse(report["usage_complete"])

    def test_own_parent_and_child_runs_are_both_counted(self):
        records = [
            run(run_id="p", usage_scope="own"),
            run(run_id="c", parent_run_id="p", usage_scope="own", input_tokens=40),
        ]
        self.assertEqual(summarize(records)["input_tokens"], 140)

    def test_cached_input_must_not_exceed_total_input(self):
        with self.assertRaises(EvaluationError):
            summarize([run(input_tokens=10, cached_input_tokens=11)])

    def test_ambiguous_scope_is_rejected(self):
        with self.assertRaises(EvaluationError):
            summarize([run(usage_scope="unspecified")])

    def test_numeric_acceptance_flag_is_rejected_as_not_a_boolean(self):
        with self.assertRaises(EvaluationError):
            summarize([run(acceptance_passed=1)])

    def test_unrecognized_run_fields_are_rejected(self):
        with self.assertRaises(EvaluationError):
            summarize([run(untracked_metric=5)])

    def test_aggregate_usage_does_not_hide_child_quality_failure(self):
        records = [
            run(run_id="p", usage_scope="aggregate", acceptance_passed=True),
            run(run_id="c", parent_run_id="p", acceptance_passed=False,
                unsupported_done_claims=1),
        ]
        report = summarize(records)
        self.assertFalse(report["acceptance_passed"])
        self.assertEqual(report["unsupported_done_claims"], 1)

    def test_known_acceptance_failure_survives_an_unknown_sibling(self):
        records = [
            run(run_id="a", acceptance_passed=False),
            run(run_id="b", acceptance_passed=None),
        ]
        self.assertIs(summarize(records)["acceptance_passed"], False)

    def test_duplicate_ids_and_cycles_are_rejected(self):
        with self.assertRaises(EvaluationError):
            summarize([run(), run(run_id="r1", case_id="other")])
        with self.assertRaises(EvaluationError):
            summarize([
                run(run_id="a", parent_run_id="b"),
                run(run_id="b", parent_run_id="a"),
            ])

    def test_overlapping_aggregate_roots_are_rejected(self):
        with self.assertRaises(EvaluationError):
            summarize([
                run(run_id="p", usage_scope="aggregate"),
                run(run_id="c", parent_run_id="p", usage_scope="aggregate"),
            ])


class ComparisonTests(unittest.TestCase):
    def test_comparison_reports_categories_and_quality_without_costs(self):
        before = summarize([run()])
        after = summarize([run(run_id="r2", variant="candidate", input_tokens=80)])
        result = compare(before, after)
        self.assertEqual(result["input_tokens_delta"], -20)
        self.assertEqual(result["cached_input_tokens_delta"], 0)
        self.assertEqual(result["uncached_input_tokens_delta"], -20)
        self.assertTrue(result["acceptance_passed"])
        self.assertNotIn("dollars", result)


class CaseAndCliTests(unittest.TestCase):
    def test_case_catalog_has_eight_complete_descriptions(self):
        path = Path(__file__).resolve().parents[1] / "evals" / "cases.json"
        cases = json.loads(path.read_text())
        self.assertEqual(len(cases), 8)
        for case in cases:
            self.assertTrue(case["allowed_workflow"])
            self.assertTrue(case["expected_artifacts"])
            self.assertTrue(case["acceptance_assertions"])

    def test_sanitized_baseline_decisions_use_catalog_case_ids(self):
        root = Path(__file__).resolve().parents[1] / "evals"
        catalog = {case["case_id"] for case in json.loads((root / "cases.json").read_text())}
        baseline = json.loads((root / "baseline-decisions.json").read_text())
        self.assertEqual({case["case_id"] for case in baseline["cases"]}, catalog)
        self.assertIsNone(baseline["metadata"]["usage"])

    def test_cli_reads_explicit_jsonl_and_emits_json_report(self):
        root = Path(__file__).resolve().parents[1]
        with tempfile.TemporaryDirectory() as temp:
            temp = Path(temp)
            runs = temp / "runs.jsonl"
            cases = temp / "cases.json"
            runs.write_text(json.dumps(run()) + "\n")
            cases.write_text(json.dumps([{"case_id": "bounded-correction", "name": "bounded correction"}]))
            result = subprocess.run(
                [sys.executable, str(root / "scripts" / "evaluate.py"), "--runs", str(runs), "--cases", str(cases), "--json"],
                check=False, capture_output=True, text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            report = json.loads(result.stdout)
            self.assertEqual(report["run_count"], 1)
            self.assertEqual(report["cases"][0]["case_id"], "bounded-correction")
            self.assertEqual(report["variants"]["baseline"]["input_tokens"], 100)


if __name__ == "__main__":
    unittest.main()
