#!/usr/bin/env python3
"""Classification-based trigger eval for Claude Code skills.

Tests skill routing quality by asking Claude to classify queries against
a skill catalog. Does NOT rely on Skill tool invocation (proven non-functional
with claude -p).

Usage:
    # Single skill eval
    python3 evals/classify-eval.py --skill writing-plans \
        --eval-set evals/trigger/writing-plans.json --runs-per-query 3 --verbose

    # Disambiguation eval (uses expected_skill from each entry)
    python3 evals/classify-eval.py --skill MULTI \
        --eval-set evals/disambiguation.json --runs-per-query 3 --verbose
"""

import argparse
import json
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from pathlib import Path


@dataclass
class EvalResult:
    query: str
    should_trigger: bool
    expected_skill: str
    actual_skill: str
    raw_response: str
    passed: bool
    parse_failure: bool
    timed_out: bool


@dataclass
class EvalSummary:
    skill: str
    total_queries: int
    total_runs: int
    passed: int
    failed: int
    parse_failures: int
    timed_out: int
    pass_rate: float
    pass_rate_excluding_timeouts: float
    results: list[dict] = field(default_factory=list)


def load_catalog(catalog_path: Path) -> list[dict[str, str]]:
    return json.loads(catalog_path.read_text())


def build_routing_prompt(catalog: list[dict[str, str]], query: str) -> str:
    skill_list = "\n".join(
        f"{i+1}. {s['name']}: {s['description']}"
        for i, s in enumerate(catalog)
    )
    return f"""You are a skill router. Given this list of available skills and a user query, respond with ONLY the skill name that best matches, or "none" if no skill fits. Do not explain your reasoning.

Skills:
{skill_list}

Query: "{query}"

Answer:"""


def build_catalog_with_override(
    catalog: list[dict[str, str]], skill_name: str, new_description: str
) -> list[dict[str, str]]:
    """Return a copy of the catalog with one skill's description replaced."""
    result = []
    for entry in catalog:
        if entry["name"] == skill_name:
            result.append({"name": skill_name, "description": new_description})
        else:
            result.append(entry)
    return result


def run_claude(prompt: str, verbose: bool = False) -> tuple[str, bool]:
    """Run claude -p and return (response_text, timed_out)."""
    try:
        result = subprocess.run(
            ["claude", "-p", "--output-format", "text"],
            input=prompt,
            capture_output=True,
            text=True,
            timeout=120,
        )
        if result.returncode != 0:
            if verbose:
                print(f"  claude -p error: {result.stderr.strip()}", file=sys.stderr)
            return "", False
        return result.stdout.strip(), False
    except subprocess.TimeoutExpired:
        if verbose:
            print("  claude -p timed out", file=sys.stderr)
        return "", True


def parse_skill_name(response: str, catalog_names: set[str]) -> tuple[str, bool]:
    """Parse the skill name from Claude's response.

    Returns (skill_name, is_parse_failure).
    """
    cleaned = response.strip().lower().strip('"\'`').strip()

    # Direct match
    if cleaned in catalog_names:
        return cleaned, False

    if cleaned == "none":
        return "none", False

    # Try to find a catalog name within the response
    for name in catalog_names:
        if name in cleaned:
            return name, False

    # Parse failure — couldn't extract a valid skill name
    return cleaned, True


def evaluate_single(
    query: str,
    should_trigger: bool,
    expected_skill: str,
    catalog: list[dict[str, str]],
    catalog_names: set[str],
    verbose: bool = False,
) -> EvalResult:
    """Run one query through the classifier and evaluate."""
    prompt = build_routing_prompt(catalog, query)
    raw, timed_out = run_claude(prompt, verbose=verbose)
    actual, parse_failure = parse_skill_name(raw, catalog_names)

    if timed_out:
        passed = False  # don't count timeouts as pass or real fail
    elif should_trigger:
        passed = actual == expected_skill
    else:
        passed = actual != expected_skill

    if verbose:
        if timed_out:
            status = "TIMEOUT"
        else:
            status = "PASS" if passed else "FAIL"
        pf = " [PARSE_FAILURE]" if parse_failure and not timed_out else ""
        print(
            f"  {status}{pf}: expected={expected_skill}, "
            f"actual={actual}, trigger={should_trigger}, "
            f"query={query[:60]}...",
            file=sys.stderr,
        )

    return EvalResult(
        query=query,
        should_trigger=should_trigger,
        expected_skill=expected_skill,
        actual_skill=actual,
        raw_response=raw,
        passed=passed,
        parse_failure=parse_failure,
        timed_out=timed_out,
    )


def run_eval(
    skill: str,
    eval_set: list[dict],
    catalog: list[dict[str, str]],
    runs_per_query: int = 1,
    num_workers: int = 5,
    verbose: bool = False,
    description_override: str | None = None,
) -> EvalSummary:
    """Run the full eval for a skill (or MULTI mode)."""
    catalog_names = {s["name"] for s in catalog}
    is_multi = skill == "MULTI"

    if description_override and not is_multi:
        catalog = build_catalog_with_override(catalog, skill, description_override)

    # Build work items
    work: list[tuple[str, bool, str]] = []
    for entry in eval_set:
        query = entry["query"]
        should_trigger = entry.get("should_trigger", True)
        expected = entry.get("expected_skill", skill) if is_multi else skill
        for _ in range(runs_per_query):
            work.append((query, should_trigger, expected))

    if verbose:
        print(
            f"Running {len(work)} evals ({len(eval_set)} queries × {runs_per_query} runs) "
            f"with {num_workers} workers",
            file=sys.stderr,
        )

    results: list[EvalResult] = []

    with ThreadPoolExecutor(max_workers=num_workers) as executor:
        futures = {
            executor.submit(
                evaluate_single,
                query, should_trigger, expected,
                catalog, catalog_names, verbose,
            ): (query, should_trigger, expected)
            for query, should_trigger, expected in work
        }
        for future in as_completed(futures):
            results.append(future.result())

    passed = sum(1 for r in results if r.passed)
    parse_failures = sum(1 for r in results if r.parse_failure)
    timeouts = sum(1 for r in results if r.timed_out)
    total = len(results)
    non_timeout = total - timeouts

    summary = EvalSummary(
        skill=skill,
        total_queries=len(eval_set),
        total_runs=total,
        passed=passed,
        failed=total - passed,
        parse_failures=parse_failures,
        timed_out=timeouts,
        pass_rate=round(passed / total, 4) if total > 0 else 0.0,
        pass_rate_excluding_timeouts=round(passed / non_timeout, 4) if non_timeout > 0 else 0.0,
        results=[
            {
                "query": r.query,
                "should_trigger": r.should_trigger,
                "expected_skill": r.expected_skill,
                "actual_skill": r.actual_skill,
                "raw_response": r.raw_response,
                "passed": r.passed,
                "parse_failure": r.parse_failure,
                "timed_out": r.timed_out,
            }
            for r in results
        ],
    )

    return summary


def main() -> None:
    parser = argparse.ArgumentParser(description="Classification-based skill trigger eval")
    parser.add_argument("--skill", required=True, help="Skill name or MULTI for disambiguation")
    parser.add_argument("--eval-set", required=True, help="Path to eval set JSON")
    parser.add_argument("--catalog", default="evals/skill-catalog.json", help="Path to skill catalog")
    parser.add_argument("--runs-per-query", type=int, default=1, help="Runs per query (default: 1)")
    parser.add_argument("--num-workers", type=int, default=5, help="Parallel workers (default: 5)")
    parser.add_argument("--verbose", action="store_true", help="Print per-query results to stderr")
    parser.add_argument(
        "--description-override",
        help="Override the target skill's description (for optimization testing)",
    )
    args = parser.parse_args()

    catalog = load_catalog(Path(args.catalog))
    eval_set = json.loads(Path(args.eval_set).read_text())

    summary = run_eval(
        skill=args.skill,
        eval_set=eval_set,
        catalog=catalog,
        runs_per_query=args.runs_per_query,
        num_workers=args.num_workers,
        verbose=args.verbose,
        description_override=args.description_override,
    )

    output = {
        "skill": summary.skill,
        "total_queries": summary.total_queries,
        "total_runs": summary.total_runs,
        "passed": summary.passed,
        "failed": summary.failed,
        "parse_failures": summary.parse_failures,
        "timed_out": summary.timed_out,
        "pass_rate": summary.pass_rate,
        "pass_rate_excluding_timeouts": summary.pass_rate_excluding_timeouts,
        "results": summary.results,
    }
    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
