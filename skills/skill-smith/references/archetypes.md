# Skill Archetypes

Five structural patterns for common skill types. Identify the archetype early to apply the right structural guidance. Not mutually exclusive — some skills blend types. When a skill spans archetypes, pick the primary and note the secondary; load guidance for both.

---

## Archetype Table

| Archetype | What It Does | Key Structural Needs | Examples |
|-----------|-------------|---------------------|----------|
| **Workflow** | Orchestrates a multi-step process with sequencing and handoffs | Decision trees, phase gates, handoff contracts, escalation triggers | `agent-team-protocol`, `executing-plans` |
| **Analysis / Methodology** | Encodes how to approach a specific type of knowledge work | Pattern dimensions, quality criteria, framework selection logic, output templates | `competitive-analysis`, `test-driven-development` |
| **Review / Guardrail** | Enforces behavioral constraints or quality gates | Constraint tables (MUST/MUST NOT), rationalization prevention, red flag lists, verification checklists | `verification-before-completion` |
| **Orchestrator** | Dispatches work to other skills or agents and integrates results | Routing logic, dispatch templates, integration checks, failure handling for delegated work | `parallel-dispatch` |
| **Formatting / Standards** | Enforces consistent output structure, voice, or compliance | Template definitions, constraint tables, before/after examples | Brand voice skills, Tier 1 standards |

---

## Structural Guidance Per Archetype

### Workflow
- Define clear phase boundaries with entry/exit criteria
- Specify what happens at each decision point — no ambiguous branching
- Include handoff contracts: what one phase passes to the next, in what format
- Define escalation triggers: when does the workflow stop and ask for human input?
- Consider `context: fork` frontmatter if phases should run in isolated contexts

### Analysis / Methodology
- Lead with the analytical framework, not step-by-step procedures
- Define pattern dimensions: what to look for in the input
- Specify quality criteria: what separates good analysis from adequate
- Include framework selection logic if multiple frameworks apply (when to use which)
- Output template should specify exact sections, order, and field types

### Review / Guardrail
- Use constraint tables with explicit MUST / MUST NOT rules
- Build in rationalization prevention: anticipate how the model might justify skipping a constraint
- Include red flag lists: specific patterns that should trigger a warning or failure
- Verification checklists should be checkable, not subjective
- For agent-callable: failure responses must be structured (error codes), not prose

### Orchestrator
- Define routing logic: how to decide which sub-skill or agent handles each piece
- Include dispatch templates: exact format for handing off work to sub-agents
- Specify integration checks: how to verify sub-agent output before combining
- Define failure handling: what happens when a delegated task fails or returns unexpected output
- Consider `allowed-tools` frontmatter to pre-approve tools sub-agents need

### Formatting / Standards
- Provide exact templates with placeholder markers
- Use before/after examples to show the transformation
- Constraint tables for voice, tone, terminology, compliance rules
- Keep rules concrete: "Use Oxford comma" not "Be consistent with punctuation"
- These are Tier 1 skills — deploy first, before methodology or workflow skills
