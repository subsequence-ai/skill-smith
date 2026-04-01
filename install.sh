#!/bin/bash
set -e

REPO="subsequence-ai/skill-smith"
BRANCH="main"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

SKILL_DIR="$HOME/.claude/skills/skill-smith"
TOOL_DIR="$HOME/.claude/tools"
EVAL_DIR="$HOME/.claude/tools/eval"

echo "Installing Skill Smith..."

# Check for ~/.claude directory
if [ ! -d "$HOME/.claude" ]; then
  echo "Error: ~/.claude directory not found. Is Claude Code installed?"
  exit 1
fi

# Check for python3 (optional — only needed for eval scripts)
if ! command -v python3 >/dev/null 2>&1; then
  echo "Warning: python3 not found. Eval scripts won't work without it."
  echo "The skill and validator will still install fine."
  echo ""
fi

# --- Install skill-smith skill ---
mkdir -p "$SKILL_DIR/references"

echo "Downloading skill-smith skill..."
curl -fsSL "${RAW}/skills/skill-smith/SKILL.md" -o "$SKILL_DIR/SKILL.md"

# Download reference files
for ref in archetypes.md best-practices-summary.md quality-checklist.md; do
  curl -fsSL "${RAW}/skills/skill-smith/references/${ref}" -o "$SKILL_DIR/references/${ref}"
done

echo "  Installed skill to $SKILL_DIR"

# --- Install validator ---
mkdir -p "$TOOL_DIR"

curl -fsSL "${RAW}/tools/validate-skill.sh" -o "$TOOL_DIR/validate-skill.sh"
chmod +x "$TOOL_DIR/validate-skill.sh"
echo "  Installed validator to $TOOL_DIR/validate-skill.sh"

# --- Install eval scripts ---
mkdir -p "$EVAL_DIR"

curl -fsSL "${RAW}/tools/eval/classify-eval.py" -o "$EVAL_DIR/classify-eval.py"
curl -fsSL "${RAW}/tools/eval/build-skill-catalog.py" -o "$EVAL_DIR/build-skill-catalog.py"
curl -fsSL "${RAW}/tools/eval/run-eval-batch.sh" -o "$EVAL_DIR/run-eval-batch.sh"
chmod +x "$EVAL_DIR/run-eval-batch.sh"
echo "  Installed eval scripts to $EVAL_DIR/"

echo ""
echo "Skill Smith installed."
echo ""
echo "  Build a skill:     Ask Claude Code to \"create a skill\" or \"build a SKILL.md\""
echo "  Validate a skill:  bash ~/.claude/tools/validate-skill.sh ~/.claude/skills/my-skill"
echo "  Build eval catalog: python3 ~/.claude/tools/eval/build-skill-catalog.py"
echo "  Run trigger eval:  python3 ~/.claude/tools/eval/classify-eval.py --skill my-skill --eval-set evals.json"
echo "  Run batch eval:   bash ~/.claude/tools/eval/run-eval-batch.sh"
