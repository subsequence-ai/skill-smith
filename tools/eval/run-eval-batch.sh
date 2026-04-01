#!/bin/bash
# Run classification evals for a list of skills.
# Results go to <results-dir>/<skill>.json, logs to <results-dir>/<skill>.log.
#
# Usage:
#   bash run-eval-batch.sh                          # all skills in catalog
#   bash run-eval-batch.sh writing-plans replan      # specific skills
#
# Requires:
#   - skill-catalog.json (run build-skill-catalog.py first)
#   - eval set files at evals/trigger/<skill>.json

set -euo pipefail

# Ensure claude -p uses Pro/Max subscription, not API key billing
unset ANTHROPIC_API_KEY

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_DIR="${RESULTS_DIR:-evals/results/classify}"
EVAL_DIR="${EVAL_DIR:-evals/trigger}"
CATALOG="${CATALOG:-evals/skill-catalog.json}"

mkdir -p "$RESULTS_DIR"

# If skills passed as arguments, use those. Otherwise, pull all from catalog.
if [[ $# -gt 0 ]]; then
  SKILLS=("$@")
else
  if [[ ! -f "$CATALOG" ]]; then
    echo "Error: $CATALOG not found. Run build-skill-catalog.py first."
    exit 1
  fi
  mapfile -t SKILLS < <(python3 -c "import json; [print(s['name']) for s in json.load(open('$CATALOG'))]")
fi

echo "=== Classification Eval: ${#SKILLS[@]} skills ==="
echo "Started: $(date)"
echo ""

total_start=$SECONDS

for skill in "${SKILLS[@]}"; do
  eval_file="${EVAL_DIR}/${skill}.json"
  if [[ ! -f "$eval_file" ]]; then
    echo "SKIP: $skill — no eval set at $eval_file"
    continue
  fi

  echo -n "Running $skill... "
  start=$SECONDS

  python3 "$SCRIPT_DIR/classify-eval.py" \
    --skill "$skill" \
    --eval-set "$eval_file" \
    --catalog "$CATALOG" \
    --verbose \
    > "$RESULTS_DIR/${skill}.json" \
    2> "$RESULTS_DIR/${skill}.log"

  elapsed=$(( SECONDS - start ))
  pass_rate=$(python3 -c "import json; d=json.load(open('$RESULTS_DIR/${skill}.json')); print(f\"pass={d['pass_rate']:.0%} (ex-timeout={d['pass_rate_excluding_timeouts']:.0%}) timeouts={d['timed_out']}\")")
  echo "done (${elapsed}s) — $pass_rate"
done

total_elapsed=$(( SECONDS - total_start ))
echo ""
echo "=== Complete: ${total_elapsed}s total ==="
echo "Results in $RESULTS_DIR/"
