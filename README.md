<p align="center">
  <img src="logo.png" alt="Skill Smith" width="200">
</p>

# Skill Smith

A skill-building toolkit for [Claude Code](https://claude.ai/code) built for **Substrate** — a Claude Code operating environment by [Subsequence.ai](https://subsequence.ai). Substrate is currently in beta, and Skill Smith is its second public component after [Subtext](https://github.com/subsequence-ai/subtext).

Skills are evolving from conversational prompts into agent-executable components — tools that orchestrators discover, invoke, and chain in autonomous pipelines. Most skills aren't built for this.

Skill Smith fixes this with three tools: a **skill builder** that encodes research-backed methodology, a **structural validator** that catches defects automatically, and a **trigger evaluator** that tests whether your skill actually fires when it should.

> **What is Substrate?** A curated layer of configs, hooks, skills, and workflows that sits on top of Claude Code — turning it from a general-purpose coding assistant into a structured development environment. Skill Smith works standalone with any Claude Code setup, but it was designed as part of that system.

## What's in the box

| Tool | What it does |
|------|-------------|
| `skill-smith` | Builds other skills via a 7-phase workflow: qualification, archetype selection, methodology extraction, construction, validation, agent-readiness audit, done gate. |
| `validate-skill.sh` | 35 automated structural checks — frontmatter, naming, description quality, required sections, content depth, methodology quality, file organization. |
| `classify-eval.py` | Tests whether Claude routes queries to the correct skill. Finds descriptions that are too vague, too narrow, or that collide with other skills. |
| `run-eval-batch.sh` | Batch runner for classification evals — runs all skills (or a specified list) sequentially with per-skill results and logs. |

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/subsequence-ai/skill-smith/main/install.sh | bash
```

Installs the skill to `~/.claude/skills/skill-smith/`, the validator to `~/.claude/tools/validate-skill.sh`, and the eval scripts to `~/.claude/tools/eval/`. No dependencies beyond `bash` and `python3`.

### Manual install

1. Copy `skills/skill-smith/` to `~/.claude/skills/skill-smith/`
2. Copy `tools/validate-skill.sh` to wherever you want it
3. Copy `tools/eval/` alongside it

## Usage

### Building a skill

Just ask Claude Code to build a skill — "create a skill that does X", "encode my deployment process as a skill", etc. Skill Smith triggers automatically and runs 7 phases:

1. **Qualification** — Is this actually a skill, or a one-off prompt?
2. **Archetype** — Workflow, analysis, review/guardrail, orchestrator, or formatting?
3. **Extraction** — Analyzes examples of your best work. Falls back to intent-based with a confidence warning.
4. **Construction** — Builds the SKILL.md with routing-optimized description and all 6 required sections.
5. **Validation** — Runs the structural harness. Fixes all failures before proceeding.
6. **Agent-readiness** — Can an orchestrator find it? Can a downstream agent parse the output?
7. **Done gate** — Validation passes, agent-readiness reviewed, user confirms.

### Validating a skill

```bash
bash validate-skill.sh ~/.claude/skills/my-skill
```

```
=== Skill Validation: my-skill ===

── Structural Validation ──
  PASS YAML frontmatter is present and parses correctly
  PASS name field exists and is kebab-case: 'my-skill'
  PASS description is 187 chars (max 1,024)
  ...
── Required Sections ──
  PASS Section found: Purpose
  FAIL Section missing: Edge Cases
── Summary ──
  Passed: 32  Failed: 1  Warnings: 2
  RESULT: FAIL (1 issue(s) found)
```

### Testing trigger quality

```bash
# Build catalog of installed skills
python3 build-skill-catalog.py

# Test a single skill
python3 classify-eval.py --skill my-skill --eval-set evals.json --verbose

# Multiple runs for statistical confidence
python3 classify-eval.py --skill my-skill --eval-set evals.json --runs-per-query 3

# Run all skills in batch
bash run-eval-batch.sh

# Run specific skills in batch
bash run-eval-batch.sh writing-plans replan handoff
```

Eval sets are JSON arrays:

```json
[
  {"query": "Create a skill for my review process", "should_trigger": true},
  {"query": "Review this pull request", "should_trigger": false}
]
```

The evaluator sends each query to Claude with your full skill catalog and checks which skill it picks. Reports pass rates, misroutes, and timeouts separately. Use `--skill MULTI` mode with `expected_skill` per query for cross-skill disambiguation testing.

The batch runner produces per-skill JSON results and log files, with a summary line per skill showing pass rate, timeout-excluded pass rate, and timeout count.

## How it works

**Skill Smith** encodes methodology from a research synthesis of Anthropic's official documentation, the wise words of [Nate Jones](https://natejones.substack.com/), and community publications — validated against 27 production skills. Key insights: descriptions truncate at ~250 chars (front-load routing info), skills under-trigger by default (be slightly pushy), and the 6 required sections each prevent a specific class of failure.

**validate-skill.sh** is pure bash, no dependencies. Parses frontmatter, checks naming, validates description heuristics, confirms sections exist with content, flags placeholder text and vague guidance.

**classify-eval.py** uses `claude -p` (headless mode) to simulate routing decisions. No API key needed — runs on your Pro/Max subscription. Supports parallel workers, multiple runs per query, and description overrides for A/B testing.

## Requirements

- Claude Code (Pro or Max subscription)
- Bash
- Python 3.10+ (for eval scripts only)
- macOS or Linux

## License

MIT
