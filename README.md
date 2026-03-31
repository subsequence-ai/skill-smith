<p align="center">
  <img src="logo.png" alt="Skill Smith" width="200">
</p>

# Skill Smith

A skill-building toolkit for [Claude Code](https://claude.ai/code) built for **Substrate** — a Claude Code operating environment by [Subsequence.ai](https://subsequence.ai). Substrate is currently in beta, and Skill Smith is its second public component after [Subtext](https://github.com/subsequence-ai/subtext).

Most Claude Code skills don't work reliably. Descriptions are too vague to trigger correctly. Required sections are missing. Output formats are hand-wavy. They work in the session where they were written, then break everywhere else.

Skill Smith fixes this with three tools: a **skill builder** that encodes research-backed methodology, a **structural validator** that catches defects automatically, and a **trigger evaluator** that tests whether your skill actually fires when it should.

> **What is Substrate?** A curated layer of configs, hooks, skills, and workflows that sits on top of Claude Code — turning it from a general-purpose coding assistant into a structured development environment. Skill Smith works standalone with any Claude Code setup, but it was designed as part of that system.

## What's in the box

| Tool | What it does |
|------|-------------|
| `skill-smith` | A Claude Code skill that builds other skills. 7-phase workflow: qualification, archetype selection, methodology extraction, construction, structural validation, agent-readiness audit, done gate. Produces complete skill directories that pass validation out of the box. |
| `validate-skill.sh` | Structural validation harness. 35 automated checks covering frontmatter, naming, description quality, required sections, content depth, output format, methodology quality, and file organization. Pass/fail with exact failure reasons. |
| `classify-eval.py` | Trigger quality evaluator. Tests whether Claude routes queries to the correct skill by running classification evals against your full skill catalog. Finds descriptions that are too vague, too narrow, or that collide with other skills. |

## The problem

Claude Code skills are just Markdown files with a description and a body. There's no schema enforcement, no testing infrastructure, and no feedback loop. The result:

- **Bad descriptions** — Claude sees ~250 characters before truncation. If your routing info isn't front-loaded, your skill never triggers.
- **Missing structure** — No edge cases section means Claude improvises when inputs are weird. No output format means every run produces different shapes.
- **No testing** — You write a skill, try it once in the same session, and call it done. Then it misfires in production because the description collides with three other skills.

Skill Smith was built after a research phase that analyzed Anthropic's skill documentation, community patterns, and 27 production skills. The methodology is encoded into the tools, not a doc you have to read.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/subsequence-ai/skill-smith/main/install.sh | bash
```

This installs the skill to `~/.claude/skills/skill-smith/`, the validator to `~/.claude/tools/validate-skill.sh`, and the eval scripts to `~/.claude/tools/eval/`. No dependencies beyond `bash` and `python3`.

### Manual install

1. Copy `skills/skill-smith/` to `~/.claude/skills/skill-smith/`
2. Copy `tools/validate-skill.sh` to wherever you want it
3. Copy `tools/eval/classify-eval.py` and `tools/eval/build-skill-catalog.py` alongside it

## Usage

### Building a skill

Just ask Claude Code to build a skill. Skill Smith triggers automatically on requests like:

- "Create a skill that does X"
- "Build a SKILL.md for my code review workflow"
- "I want to encode my deployment process as a skill"
- "Make a new skill"

It runs a 7-phase workflow:

1. **Qualification** — Is this actually a skill, or is it a one-off prompt? Checks recurrence, methodology-dependence, and consistency-sensitivity.
2. **Archetype** — Workflow, analysis, review/guardrail, orchestrator, or formatting? Each has structural guidance.
3. **Extraction** — Analyzes 10-20 examples of your best work across 5 dimensions. Falls back to intent-based if no examples exist (with a confidence warning).
4. **Construction** — Builds the SKILL.md with a routing-optimized description and all 6 required sections.
5. **Validation** — Runs the structural harness. Fixes all failures before proceeding.
6. **Agent-readiness** — Can an orchestrator find this skill? Can a downstream agent parse the output? Are failure modes defined?
7. **Done gate** — Structural validation passes, agent-readiness reviewed, user confirms.

### Validating a skill

```bash
bash validate-skill.sh ~/.claude/skills/my-skill
```

```
=== Skill Validation: my-skill ===
File: /Users/you/.claude/skills/my-skill/SKILL.md (89 lines)

── Structural Validation ──
  PASS YAML frontmatter is present and parses correctly
  PASS name field exists and is kebab-case: 'my-skill'
  PASS name matches directory: 'my-skill' == 'my-skill'
  PASS description is 187 chars (max 1,024)
  ...

── Required Sections ──
  PASS Section found: Purpose
  PASS Section found: Methodology
  FAIL Section missing: Edge Cases

── Summary ──
  Passed:   32
  Failed:   1
  Warnings: 2

RESULT: FAIL (1 issue(s) found)
```

35 checks across 7 categories: structural integrity, naming conventions, description quality, required sections with content depth, output format, methodology quality, and file organization.

### Testing trigger quality

Build a catalog of your installed skills, then test whether queries route correctly:

```bash
# Build the catalog (reads all ~/.claude/skills/*/SKILL.md)
python3 build-skill-catalog.py

# Test a single skill
python3 classify-eval.py --skill my-skill --eval-set my-skill-evals.json --verbose

# Test with multiple runs for statistical confidence
python3 classify-eval.py --skill my-skill --eval-set my-skill-evals.json --runs-per-query 3
```

Eval sets are JSON arrays of test queries:

```json
[
  {"query": "Create a skill for my review process", "should_trigger": true},
  {"query": "Review this pull request", "should_trigger": false}
]
```

The evaluator sends each query to Claude with your full skill catalog and checks which skill it picks. It reports pass rates, misroutes, and timeout failures separately so you know exactly what needs fixing.

For cross-skill disambiguation testing, use `--skill MULTI` mode with an `expected_skill` field per query.

## How it works

**Skill Smith** (the skill) encodes methodology extracted from a research synthesis of Anthropic's official documentation, community best practices, and analysis of 27 production skills. Key insights baked into the workflow:

- Descriptions truncate at ~250 characters in the system prompt. Front-load routing information.
- Skills under-trigger by default. Descriptions should be slightly pushy.
- The 6 required sections (Purpose, Methodology, Output Format, Edge Cases, Example, Quality Criteria) aren't arbitrary — each one prevents a specific class of failure.
- Intent-based skills (no examples) are unreliable. The workflow flags them and recommends collecting examples.

**validate-skill.sh** is pure bash with no dependencies. It parses YAML frontmatter, checks naming conventions, validates description quality heuristics, confirms all required sections exist and have content, and flags placeholder text and vague guidance.

**classify-eval.py** uses `claude -p` (Claude Code's headless mode) to simulate routing decisions. No API key needed — runs on your Claude Pro/Max subscription. Supports parallel workers, multiple runs per query, and description overrides for A/B testing.

## Requirements

- Claude Code (Pro or Max subscription)
- Bash
- Python 3.10+ (for eval scripts only)
- macOS or Linux

## License

MIT
