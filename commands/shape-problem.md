---
name: shape-problem
description: Use BEFORE proposing solutions. Transforms ambiguous requirements into structured, actionable problem definitions. Does NOT propose solutions.
argument-hint: "<requirement-or-question>"
---

# Shape Problem

Transform ambiguous requirements into structured, actionable problem definitions.
**Do NOT propose solutions. Define the problem space first.**

Input: $ARGUMENTS

---

## Phase 1: Extract Raw Signal

1. **Source the requirement** — read JIRA ticket, Confluence page, or use the description in $ARGUMENTS
   - Use `jira issue view` or Atlassian MCP tools to fetch ticket details
   - If a URL is provided, fetch the content
2. **Identify the requestor** — who asked for this and why?
3. **Capture the pain point** — what is actually broken or missing?
4. **Note what's NOT said** — what assumptions are embedded in the requirement?

## Phase 2: Define Constraints

| Constraint Type | Description | Source | Negotiable? |
|-----------------|-------------|--------|-------------|
| Technical | [e.g., must work with existing auth service] | [who stated/implied] | Yes/No |
| Timeline | [e.g., needed by Sprint 26.3] | [who stated] | Yes/No |
| Resource | [e.g., 2 BE engineers available] | [team capacity] | Yes/No |
| Compatibility | [e.g., must not break existing BFFs] | [inferred/stated] | Yes/No |
| Dependencies | [e.g., blocked by PR #88 merge] | [technical analysis] | No |

## Phase 3: Define Success

| Criterion | Measurable Target | How to Verify |
|-----------|-------------------|---------------|
| [e.g., Session expiry works] | [e.g., cookie expires at session_expires_at] | [e.g., manual test + unit test] |
| [e.g., No performance regression] | [e.g., p95 latency < 200ms] | [e.g., load test] |

## Phase 4: Risk Assessment

| Risk | Likelihood | Impact | Mitigation | Owner |
|------|-----------|--------|------------|-------|
| [e.g., Breaking change to BFF contract] | High/Med/Low | High/Med/Low | [action] | [person/team] |

Rate each risk: **Critical** (High × High), **Significant** (High × Med or Med × High), **Moderate** (all others).

## Phase 5: Scope Boundary

### In Scope (MUST HAVE)

- [Explicit requirement 1]
- [Explicit requirement 2]

### Out of Scope (CREATE ISSUES FOR)

- [Related but not required 1]
- [Related but not required 2]

### Open Questions (MUST RESOLVE BEFORE IMPLEMENTATION)

- [Ambiguity 1] — Ask [person/team]
- [Ambiguity 2] — Ask [person/team]

---

## Anti-Patterns

You are violating this process if you:

- [ ] Propose solutions before completing all 5 phases
- [ ] Skip the constraints phase (that's where 80% of rework comes from)
- [ ] Assume unstated requirements (list them as Open Questions)
- [ ] Skip risk assessment for "simple" features (simple features break complex systems)
- [ ] Define success without measurable targets

## Output

A single markdown document containing all 5 phases. This output feeds into:

- `/explore-solution` — for multi-approach exploration when the approach is unclear
- `/decompose-story` — for subtask creation when the approach is known
- Plan Mode — for implementation design
- Sprint planning — for capacity allocation and risk-aware scheduling

## When to Use

- New feature requests with ambiguous scope
- Cross-team initiatives with unclear ownership
- Requirements from non-technical stakeholders
- Any task where "what to build" isn't obvious
