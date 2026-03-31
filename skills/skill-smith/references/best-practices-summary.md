# Best Practices Summary

Condensed from `research/skills-best-practices.md`. Load this file during SKILL.md construction (Phase 4).

---

## Description Field Rules

The description is a routing table entry, not a human-readable summary. It is the only part always in context — Claude uses it to choose from 100+ skills.

### Character Limits
- Max 1,024 characters (spec)
- Claude Code truncates to 250 characters in skill listing
- **Front-load** the first 250 chars with critical routing information

### 4 Required Components
1. **Document types / artifacts produced** — what the skill outputs
2. **Trigger phrases** — actual words a human or agent would use (e.g., "analyze our competitors," "build a comp set")
3. **Output format hints** — "Returns structured memo" or "Produces JSON report"
4. **When to fire** — conditions or contexts where this skill is relevant

### Hard Rules
- **Single line in YAML.** Multi-line descriptions silently break the skill — no error, skill just vanishes. Do not use `|` operator. Add `# prettier-ignore` if using formatters.
- **Third person.** "Processes Excel files and generates reports" — not "I can help you" or "You can use this."
- **Slightly pushy.** Skills under-trigger more than over-trigger. When in doubt, add more trigger phrases. Make Claude confident to use the skill, not cautious.

### Good vs. Bad

Bad: `Helps with competitive analysis`

Good: `Produces structured competitive analysis memos for product, market, and investment research. Use when asked to analyze competitors, assess market position, write a competitive landscape, or evaluate competitive dynamics. Applies to "analyze our competitors," "who are the players in X market," "build a comp set," or "how do we stack up against Y." Returns structured memo with market definition, player profiles, positioning matrix, strategic implications.`

---

## Methodology Body Requirements

### The 5 Must-Haves

Every skill body needs all five. A skill missing any one has a structural gap.

1. **Reasoning over procedures.** Explain how to approach the work — frameworks, quality criteria, principles behind decisions. Not "Step 1: Open file. Step 2: Extract revenue." Procedures are finite; reasoning generalizes to unanticipated cases.

2. **Specified output format.** Not "produce a summary." Exact sections in exact order. Exact fields. If the output is ambiguous, every caller must interpret it, and interpretation introduces variability.

3. **Explicit edge cases.** What happens when data is missing? Input is ambiguous? Request is partially out of scope? Everything a human handles with common sense must be written down.

4. **At least one example.** One concrete illustration of good output dramatically improves consistency. Can live in a reference file — does not need to be inlined. Use Good/Bad paired examples where applicable.

5. **Keep it lean.** 150 lines core methodology in SKILL.md. Move reference material to `references/`. A 200-line skill that fires reliably outperforms an 800-line skill where instructions compete for attention.

### Required SKILL.md Sections
- Purpose
- Methodology
- Output Format
- Edge Cases
- Example
- Quality Criteria

### Things to Avoid
- Excessive ALWAYS/NEVER in all caps — yellow flag for competing instructions. Reframe with reasoning so the model understands *why*.
- Vague output instructions: "produce a summary," "write a structured analysis" — specify exact structure.
- Placeholder text: `[INSERT YOUR CRITERIA HERE]`, `[TODO]` — everything must be filled in from the user's actual work.
- Mechanical step-by-step procedures without reasoning — brittle, breaks on unanticipated cases.

---

## Output-Extraction Method (5 Analysis Dimensions)

When analyzing examples to extract methodology, look for:

1. **Structural patterns** — What sections appear consistently? What order? What's always included vs. sometimes included?
2. **Decision patterns** — Where did the author make judgment calls? What criteria drive those calls?
3. **Quality signals** — What separates the best examples from merely adequate ones? What's present in all of them?
4. **Framework patterns** — Implicit frameworks: comparison structures, evaluation criteria, analytical sequences?
5. **Voice and tone patterns** — What register? How technical? How direct?

### Validation Questions (exit criteria for extraction)
1. "Does this capture how you actually approach this work, or did I miss something?"
2. "Is there a decision you make in this workflow that isn't reflected here?"
3. "Try giving me a vague, realistic request — the kind that actually arrives — and I'll run against this skill so we can see if the output matches your standard."

Iterate until the methodology matches the user's actual practice.

---

## Guardrails (What NOT to Do)

### Content Integrity
- Do not fabricate methodology the user's examples don't support. If uncertain, ask.
- Do not include placeholder text. Everything must be filled in from actual work.
- Do not invent tasks the user didn't describe.

### Qualification Honesty
- Do not suggest skills for tasks better handled by a direct prompt.
- Do not tell the user their skill is "good with minor tweaks" if it would fail in an agent pipeline. Be direct about failure severity.
- Impact statements must be concrete, not vague ("improves consistency" is not specific enough).

### Technical
- Description must be a single line in YAML (silent failure otherwise).
- Do not produce vague output format instructions.

### Process
- If <3 examples, flag the limitation — methodology extraction will be less reliable.
- If user responses are vague, ask follow-up questions before proceeding. Do not guess.
- If a criterion already passes, say so and move on. Don't rewrite what works.

---

## String Substitutions

Skills support dynamic content injection in SKILL.md:

- `$ARGUMENTS` — full argument string passed to the skill
- `$ARGUMENTS[N]` / `$N` — positional arguments
- `${CLAUDE_SESSION_ID}` — current session identifier
- `${CLAUDE_SKILL_DIR}` — path to the skill's folder
- `` !`command` `` — runs a shell command before skill content is sent to Claude

Use `$ARGUMENTS` when the skill takes user input. Use `${CLAUDE_SKILL_DIR}` to reference files relative to the skill directory.

---

## Optional Frontmatter Fields

Beyond required `name` and `description`:

| Field | When to Use |
|-------|-------------|
| `paths` | Limit skill activation to specific file patterns (e.g., `"*.py"`) |
| `context: fork` | Run skill in isolated subagent context (good for orchestrators) |
| `allowed-tools` | Pre-approve specific tools without user confirmation |
| `argument-hint` | Show hint during autocomplete (e.g., `[issue-number]`) |
| `disable-model-invocation: true` | User-only — prevent Claude from auto-triggering |
| `user-invocable: false` | Agent-only — hide from `/` menu |
| `model` | Override model when skill is active |
| `effort` | Override effort level (`low`, `medium`, `high`, `max`) |

Offer these when relevant to the skill being built. Don't include unnecessary fields.
