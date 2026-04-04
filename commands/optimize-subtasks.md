# optimize-subtasks

Analyze user story subtasks and suggest consolidation opportunities for more efficient development.

## Usage

```
/optimize-subtasks <path-to-subtasks-file>
```

Or if in a user story directory:

```
/optimize-subtasks
```

## Implementation

1. Read the subtasks file (subtasks.md, SUBTASKS.md, or similar)

2. Parse subtasks looking for:
   - Task ID/name
   - Type (Frontend, Backend, QA, etc.)
   - Effort estimation (points/days)
   - Dependencies
   - Scope description

3. Apply engineering optimization heuristics:

   **Default: Moderate Consolidation Approach**
   - Balance clean architecture with practical efficiency
   - Keep API contracts as separate tasks
   - Consolidate within same layer/service
   - Merge trivial pass-through layers (e.g., BFF with Backend)
   - Include testing in development tasks

   **Consolidation Opportunities**:
   - Backend + BFF when BFF is just pass-through
   - Multiple frontend components in same feature
   - Configuration + implementation of same component
   - Sequential tasks with strong dependencies
   - Small related tasks (< 0.5 days each)

   **Always Keep Separate**:
   - API contract definitions (proto, OpenAPI)
   - Cross-layer tasks (Frontend vs Backend)
   - Database migrations
   - Infrastructure changes
   - Tasks that enable parallelization
   - High-risk tasks needing isolation

4. Consider modern development practices:
   - Developers should own testing
   - Vertical slices over horizontal layers
   - Minimize handoffs
   - Reduce context switching
   - Enable parallel development

5. Generate optimization report with:
   - Current state analysis
   - Specific merge recommendations
   - Efficiency gains calculation
   - Risk assessment
   - Optimized task breakdown

## Example Output

```markdown
# Task Optimization Analysis

## Current Structure

- 5 subtasks across 3 developers
- 4 handoff points
- Sequential dependencies

## Optimization Recommendations

### Merge Tasks A & B

**Rationale**: Both modify same service layer
**Efficiency Gain**: -0.5 days, -1 handoff
**New Scope**: Combined implementation with integrated testing

### Keep Task C Separate

**Rationale**: Different technology stack, can parallelize

## Optimized Breakdown

1. Backend Implementation (includes API + DB) - 2.5 pts
2. Frontend Implementation (includes UI + tests) - 2 pts
3. Infrastructure Setup - 1 pt

## Metrics

- Time Saved: 20% (1 day)
- Handoffs Reduced: 75% (from 4 to 1)
- Parallel Paths: 2 (was 1)
```

## Best Practices

1. **Don't Over-Consolidate**: Keep logical boundaries
2. **Consider Team Skills**: Match tasks to expertise
3. **Enable Parallelism**: Identify independent work streams
4. **Include Testing**: Modern devs test their own code
5. **Reduce Handoffs**: Each handoff adds overhead
6. **Vertical Slices**: Full features over layers

## Default Optimization Principles

The command defaults to **Option B: Moderate Consolidation** which balances:

1. **API Contracts First**: Keep proto/OpenAPI definitions separate for clear interfaces
2. **Same-Layer Consolidation**: Merge implementation tasks within same layer
3. **Trivial Task Merging**: Combine pass-through tasks (e.g., BFF) with main implementation
4. **Developer-Owned Testing**: Include tests in implementation tasks, not separate
5. **Enable Parallelism**: Structure to allow frontend/backend parallel development
6. **Pragmatic PR Sizes**: Not too many small PRs, not unwieldy large ones

## Anti-Patterns to Flag

- Separate "testing" tasks (integrate instead)
- Artificial layer separation for small features
- Sequential tasks that could be parallel
- Multiple config tasks (consolidate)
- Handoffs for trivial changes
- Over-consolidation that breaks logical boundaries
