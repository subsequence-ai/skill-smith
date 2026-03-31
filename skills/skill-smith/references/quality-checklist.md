# Quality Checklist

Full checklist from `research/skills-best-practices.md` Section 8. Each item tagged (S) for structural (automatable) or (M) for model-dependent (requires judgment).

---

## Structural Validation (S)

- [ ] **(S)** YAML frontmatter is present and parses correctly
- [ ] **(S)** `name` field exists and is kebab-case (lowercase letters, numbers, hyphens only)
- [ ] **(S)** `name` is max 64 characters
- [ ] **(S)** `name` matches parent directory name
- [ ] **(S)** `name` does not contain "anthropic" or "claude"
- [ ] **(S)** `name` does not start or end with a hyphen
- [ ] **(S)** `name` does not contain consecutive hyphens
- [ ] **(S)** `description` field exists and is non-empty
- [ ] **(S)** `description` is a single line (no newline characters within the value)
- [ ] **(S)** `description` is max 1,024 characters
- [ ] **(S)** `description` does not contain XML tags
- [ ] **(S)** SKILL.md body is under 500 lines
- [ ] **(S)** Required sections present: Purpose, Methodology, Output Format, Edge Cases, Example, Quality Criteria
- [ ] **(S)** Referenced files are one level deep from SKILL.md

## Description Quality

- [ ] **(S)** First 250 characters contain the primary routing information (what, when, trigger phrases)
- [ ] **(S)** Written in third person (no "I can," "you can," "we will")
- [ ] **(S)** Uses a meaningful portion of the available 1,024 characters (not a terse label)
- [ ] **(M)** Contains specific trigger phrases, not just domain labels
- [ ] **(M)** Specifies what the skill produces (output type / artifact type)
- [ ] **(M)** Specifies when the skill should fire (trigger conditions)
- [ ] **(M)** Includes output format hints
- [ ] **(M)** Avoids being so narrow it under-triggers on legitimate requests
- [ ] **(M)** Avoids being so broad it over-triggers on unrelated requests
- [ ] **(M)** For agent-callable skills: contains phrases an orchestrating agent would generate

## Output Format Specification

- [ ] **(S)** Output format section exists in the skill body
- [ ] **(S)** No vague output instructions ("produce a summary," "write a structured analysis")
- [ ] **(M)** Output format specifies exact sections or fields
- [ ] **(M)** Output format specifies exact order
- [ ] **(M)** Output format specifies structure (JSON, Markdown headings, etc.)
- [ ] **(M)** Field types and lengths are explicit where applicable
- [ ] **(M)** A downstream agent could parse the output programmatically without interpreting prose

## Edge Case Handling

- [ ] **(S)** Edge cases section exists in the skill body
- [ ] **(M)** Handles missing required data (specific behavior defined)
- [ ] **(M)** Handles ambiguous input (defined failure mode)
- [ ] **(M)** Handles partially out-of-scope requests (boundary defined)
- [ ] **(M)** For agent-callable skills: failure modes are machine-readable (error codes / structured responses), not prose
- [ ] **(M)** No scenario where Claude would be forced to improvise behavior

## Methodology Quality

- [ ] **(M)** Methodology expressed as principles and frameworks, not mechanical step-by-step procedures
- [ ] **(S)** No placeholder text (`[INSERT YOUR CRITERIA HERE]`, `[TODO]`, etc.)
- [ ] **(S)** No vague guidance ("use good judgment," "be thorough," "be creative")
- [ ] **(M)** Decision criteria are specific and actionable
- [ ] **(S)** At least one concrete example of good output is included (in SKILL.md or in a referenced file)
- [ ] **(S)** Body is under 150 lines of core methodology (reference material in separate files)

## Composability

- [ ] **(M)** Output contains only the structured deliverable
- [ ] **(M)** No conversational preamble in the output specification ("Here is the analysis...")
- [ ] **(M)** No trailing caveats or meta-commentary in output
- [ ] **(M)** Output could be consumed by another skill cleanly
- [ ] **(M)** Clean handoff: output of this skill can serve as input to another skill without transformation

## Agent-Readiness (the "2am Test")

- [ ] **(M)** Passes all 4 agent-readiness criteria (routing, output format, edge cases, composability)
- [ ] **(M)** For each criterion that fails: a concrete failure scenario can be articulated
- [ ] **(M)** If agent-callable: output format is JSON or strict Markdown with exact structure
- [ ] **(M)** If agent-callable: edge cases produce structured error responses, not prose
- [ ] **(M)** The skill would produce correct output at 2am with no human watching

## Qualification Pre-Check

- [ ] Task meets recurrence threshold (3+ times per month)
- [ ] Task is methodology-dependent (quality requires a specific approach, not just a good prompt)
- [ ] Task is consistency-sensitive (output variability has a real cost)
