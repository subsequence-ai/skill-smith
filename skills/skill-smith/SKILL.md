---
name: skill-smith
description: Builds production-quality Claude Code skills from examples or intent — use when asked to create a skill, build a SKILL.md, encode a methodology, make a new skill, convert a workflow into a reusable tool, or package expertise. Runs a 7-phase workflow (qualification, archetype, extraction, construction, validation, agent-readiness, done gate). Produces a complete skill directory with SKILL.md and reference files that pass structural validation. Returns structured artifacts, not advice.
---

# Skill Creator

## Purpose

Build skills that work unattended at 2am. This skill guides the creation of Claude Code skills from raw examples or stated intent, producing a complete skill directory (`SKILL.md` + optional `references/`) that passes structural validation and is ready for agent pipelines.

## Methodology

Work through all 7 phases in order. Do not skip phases. Load reference files only when their phase begins.

### Phase 1: Qualification Gate

Ask the user what task they want to encode. Evaluate against three signals — all three must pass:

1. **Recurrence** — Does this happen 3+ times per month? One-off tasks are prompts, not skills.
2. **Methodology-dependence** — Would you write a methodology doc for a new employee before asking them to do this? If any reasonable prompt gets it done, it doesn't need encoding.
3. **Consistency-sensitivity** — Does output variability have a real cost? If ad-hoc results are fine, skip the skill.

If any signal fails, tell the user directly: this is not a skill. Explain which criteria failed and why. Suggest a direct prompt instead.

If all pass, score ROI: frequency × quality variance × downstream impact. Note the score for prioritization context.

### Phase 2: Archetype Selection

Read `references/archetypes.md`. Present the 5 archetypes and help the user identify which fits:

- **Workflow** — multi-step process with sequencing and handoffs
- **Analysis / Methodology** — how to approach a specific type of knowledge work
- **Review / Guardrail** — behavioral constraints or quality gates
- **Orchestrator** — dispatches work to other skills/agents
- **Formatting / Standards** — consistent output structure, voice, compliance

If the skill spans archetypes, pick the primary and note the secondary. Load structural guidance for both.

### Phase 3: Methodology Extraction

Read `references/best-practices-summary.md`.

**Primary path — output extraction (preferred):**
Ask the user for 10-20 examples of their best work. Analyze across 5 dimensions: structural patterns, decision patterns, quality signals, framework patterns, voice/tone. Then interview about embedded decisions with 3-5 targeted questions.

If the user provides fewer than 3 examples, flag: "Methodology extraction will be less reliable with fewer examples. The resulting skill may need revision once you have more examples to validate against."

**Fallback — intent-based:**
If the user has no examples, build from stated intent. Flag the output as low-confidence methodology: "This skill was built from intent, not observed practice. Collect examples of actual output and revise — intent-based skills are less reliable."

**Exit criteria — do not proceed until the user confirms all three:**
1. "Does this capture how you actually approach this work, or did I miss something?"
2. "Is there a decision you make in this workflow that isn't reflected here?"
3. "Try giving me a vague, realistic request — the kind that actually arrives — and I'll run against this methodology so we can see if the output matches your standard."

### Phase 4: SKILL.md Construction

Build the skill file with all required sections. Reference `references/best-practices-summary.md` for rules.

**Description field (do this first — it's the most important part):**
Write a single-line YAML description containing all four components:
1. Document types / artifacts produced
2. Trigger phrases (actual words a human or agent would use)
3. Output format hints
4. When-to-fire conditions

Front-load the first 250 characters with primary routing information. Use third person. Make it slightly pushy — skills under-trigger by default. Use a meaningful portion of the 1,024-char limit.

**Body sections — all six required:**
- **Purpose** — what the skill does and why it exists (2-5 lines)
- **Methodology** — reasoning and frameworks, not mechanical procedures. No placeholder text, no hand-wavy directives.
- **Output Format** — exact sections, exact order, exact structure. No vague deliverable descriptions.
- **Edge Cases** — specific behavior for missing data, ambiguous input, out-of-scope requests
- **Example** — at least one concrete example of good output (can reference a file)
- **Quality Criteria** — what separates good output from adequate

**Line budget:** Keep core methodology under 150 lines. If it exceeds this, move supplementary content (detailed examples, reference tables, templates) to `references/`. Do not cut required sections to meet the target — move content to references instead.

### Phase 5: Structural Validation

Run the validation harness against the produced skill:

```bash
bash harness/validate-skill.sh <skill-directory-path>
```

If the harness is not available, manually verify: frontmatter parses, name is kebab-case and matches directory, description is single-line and under 1,024 chars, body under 500 lines, all 6 required sections present, no placeholder text.

Fix all failures before proceeding. This is a gate.

### Phase 6: Agent-Readiness Audit

Walk through 4 criteria conversationally with the user:

1. **Routing** — Would an orchestrating agent find this skill from the description alone? Are trigger phrases the ones an agent would generate, not just human language?
2. **Output format** — Can a downstream agent parse this output without interpreting prose? Is the structure exact enough to be a contract?
3. **Edge cases** — Are failure modes defined for every scenario? For agent-callable skills: are errors structured (codes/JSON), not prose?
4. **Composability** — Can the output serve as input to another skill without transformation? No conversational preamble, no trailing caveats?

Recommend the user test in a separate Claude session (Claude A/B pattern) for a blind test — the authoring session's context can mask issues.

### Phase 7: Done Gate

Done when: (1) structural validation passes, (2) agent-readiness reviewed, (3) user confirms. If the user is satisfied but structural validation fails, fix structural issues first — the minimum bar is non-negotiable.

## Output Format

A skill directory: `<skill-name>/SKILL.md` (required) + optional `references/` subdirectory for supplementary content loaded on demand.

SKILL.md structure: YAML frontmatter (`name` in kebab-case, `description` as single-line routing-optimized string under 1,024 chars) followed by Markdown body with sections in order: Purpose, Methodology, Output Format, Edge Cases, Example, Quality Criteria.

## Edge Cases

- **User wants to encode a one-off task** — Fail at Phase 1. Explain which qualification signal failed. Suggest a direct prompt.
- **User has no examples (intent-only)** — Allow but flag as low-confidence. Recommend collecting examples for future revision.
- **User provides fewer than 3 examples** — Proceed but flag that extraction is less reliable.
- **Skill exceeds 150-line core target** — Move content to `references/`. Do not cut required sections.
- **Skill spans multiple archetypes** — Pick primary, note secondary, apply structural guidance from both.
- **Structural validation unavailable** — Fall back to manual verification checklist (Phase 5 describes the checks).
- **User says "good enough" but structural validation fails** — Fix structural issues first. The minimum bar is non-negotiable.

## Example

A user asks: "I write competitive analysis memos every week. Can you make that a skill?"

**Phase 1:** Recurrence ✓ (weekly), methodology-dependent ✓ (specific analytical framework), consistency-sensitive ✓ (client-facing). Passes.

**Phase 2:** Analysis/Methodology archetype. Load structural guidance for pattern dimensions and output templates.

**Phase 3:** User provides 5 example memos. Analysis reveals: consistent 4-section structure (Market Definition → Player Profiles → Positioning Matrix → Strategic Implications), decision pattern around which competitors to include (revenue threshold + strategic relevance), quality signal in the positioning matrix (always includes 3+ evaluation dimensions).

**Phase 4:** Build SKILL.md with extracted methodology, exact output format matching the 4-section structure, edge cases for insufficient competitor data.

**Phase 5:** Run harness — all structural checks pass.

**Phase 6:** Agent-readiness walkthrough confirms routing, output format, edge cases, composability.

## Quality Criteria

A well-built skill:
- Passes all structural validation checks without modification
- Has a description that triggers correctly on realistic requests (not just engineered test phrases)
- Produces structurally consistent output across multiple runs
- Handles edge cases with defined behavior, not improvisation
- Could run unattended in an agent pipeline at 2am and produce correct output
- Encodes actual methodology from real examples, not aspirational intent
