# Explore Solution

Generate and compare solution approaches BEFORE committing to implementation.
**The first version should be wrong. Explore the solution space.**

Problem: $ARGUMENTS

---

## Rules

1. Generate EXACTLY 2-3 approaches (not 1, not 5)
2. Each approach must be genuinely different (not minor variations)
3. Do NOT recommend one yet — present trade-offs neutrally
4. Spend more time on constraints than on features
5. Search the codebase for existing patterns before inventing new ones

## Phase 1: Understand the Problem Space

1. Read the problem definition (from `/shape-problem` output or $ARGUMENTS)
2. Identify the **core technical decision(s)** — the choice that shapes everything else
3. Search the codebase for existing patterns that constrain the solution
4. Check sibling repositories for prior art (use `gh api` if needed)
5. List what is NOT negotiable (hard constraints from the problem definition)

## Phase 2: Generate Approaches

For each approach, provide:

### Approach A: [Descriptive Name]

**Core Idea**: [1 sentence — what makes this approach different]

**How It Works**:

1. [Step 1]
2. [Step 2]
3. [Step 3]

**Affected Components**: [list services, repos, or layers touched]

**Fits Existing Patterns?**: [Yes/No — cite specific files or patterns in the codebase]

**Rough Effort**: [T-shirt size: S / M / L / XL with brief justification]

### Approach B: [Descriptive Name]

[Same structure as above]

### Approach C: [Descriptive Name] (optional)

[Same structure — only if genuinely different from A and B]

## Phase 3: Trade-off Matrix

| Dimension                 | Approach A | Approach B | Approach C |
| ------------------------- | ---------- | ---------- | ---------- |
| Complexity                |            |            |            |
| Time to implement         |            |            |            |
| Risk of breaking existing |            |            |            |
| Long-term maintainability |            |            |            |
| Team familiarity          |            |            |            |
| Reversibility             |            |            |            |
| Operational overhead      |            |            |            |

## Phase 4: Decision Inputs (NOT Decision)

- **Recommend exploring further**: [which approach and why — but explicitly not a final recommendation]
- **Key question to resolve**: [the ONE thing that would make the choice obvious]
- **Who should weigh in**: [team member or stakeholder with relevant context]
- **What would change the answer**: [if X is true, pick A; if Y is true, pick B]

---

## Anti-Patterns

You are violating this process if you:

- [ ] Present only one real approach with strawman alternatives
- [ ] Recommend a specific approach in Phase 2 (save for Phase 4)
- [ ] Skip searching the codebase for existing patterns
- [ ] Evaluate approaches only on technical merit (consider team, timeline, risk)
- [ ] Converge too early — the goal is to hold ambiguity and explore

## Output

A comparison document suitable for:

- Team discussion in sprint planning or architecture review
- Input to Plan Mode (once approach is chosen)
- Async review on Confluence or GitHub Discussion
- Informal Architecture Decision Record (ADR)

## Integration

- **Input**: `/shape-problem` output or well-defined requirement
- **Output feeds**: Plan Mode → `/decompose-story` → Implementation
- **When approach is chosen**: Enter Plan Mode with the selected approach as context
