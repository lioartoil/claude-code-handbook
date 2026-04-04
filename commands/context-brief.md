# Context Brief

Assemble the right context for the right task. Do NOT start the task — prepare the context package first.

Task: $ARGUMENTS

---

## Task Type Detection

Analyze $ARGUMENTS to determine the task category:

| Task Type | Key Sources | Tools |
|-----------|-------------|-------|
| **PR Review** | PR diff, JIRA ticket, related files, test coverage | `gh pr view`, `jira issue view` |
| **Debugging** | Error logs, recent deploys, service topology, metrics | `gcloud logging read`, `git log` |
| **Sprint Planning** | JIRA board, team capacity, velocity, blockers | `jira`, Atlassian MCP |
| **Feature Design** | User story, existing architecture, related services | Confluence, codebase search |
| **Incident Response** | Alert details, runbooks, service dependencies, recent changes | `gcloud`, `git log`, dashboards |
| **Candidate Interview** | Resume, role requirements, challenge problems, scoring rubric | `candidates/` directory |

## Phase 1: Identify Required Context

Based on the detected task type, create a checklist:

- [ ] [Context item 1] — **Why**: [reason needed] — **Source**: [where to get it]
- [ ] [Context item 2] — **Why**: [reason needed] — **Source**: [where to get it]
- [ ] [Context item 3] — **Why**: [reason needed] — **Source**: [where to get it]

### Context Depth Guide

| Task Complexity | Context Depth | Token Budget |
|----------------|---------------|-------------|
| Simple fix | Essential only | ~2,000 tokens |
| Standard task | Essential + key supporting | ~5,000 tokens |
| Complex feature | Essential + supporting + related | ~10,000 tokens |
| Cross-team initiative | Full context across boundaries | ~15,000 tokens |

## Phase 2: Gather Context

For each item in the checklist, fetch the actual content:

1. **Local files**: Use `Read` tool for specific files, `Grep` for searching
2. **GitHub**: Use `gh pr view`, `gh issue view`, `gh api` for API calls
3. **JIRA**: Use `jira issue view` or Atlassian MCP `searchJiraIssuesUsingJql`
4. **Confluence**: Use Atlassian MCP `getConfluencePage` or `searchConfluenceUsingCql`
5. **GCP**: Use `gcloud logging read`, `gcloud sql instances describe`
6. **Git history**: Use `git log`, `git diff`, `git blame`

## Phase 3: Context Package

### Essential Context (MUST include)

[Assembled content with source attribution — this is what the agent needs to do the task]

### Supporting Context (Include if token budget allows)

[Secondary context that helps but isn't critical — background, related decisions, team preferences]

### Explicitly Excluded (NOT needed — prevents re-gathering)

- [What was considered but excluded] — **Why excluded**: [reason]

### Example Output (PR Review Context Brief)

```markdown
## Context Brief: Review PR #88 (hierarchy_positions index)

### Essential Context
- **PR**: your-repo PR #88 — adds index on `hierarchy_positions(space_id)`
- **JIRA**: PROJ-1850 — "Slow queries on hierarchy_positions table"
- **Evidence**: 40% of slow queries (>1s) hit this table without index
- **Risk**: Index creation on 2M+ row table may lock writes for 30-60s

### Supporting Context
- Current instance: db-instance-name (3.75 GB RAM)

### Explicitly Excluded
- BigQuery federated query issues — separate root cause, separate PR
```

---

## Output

A structured context block that can be:

- Pasted as input to any other command (`/shape-problem`, `/systematic-debugging`, etc.)
- Used as the context preamble for a new Claude session
- Saved alongside task artifacts for reproducibility

## When to Use

- Starting a new task where context isn't obvious
- Resuming work after a session break (complement to `/session-handoff`)
- Preparing for a complex debugging session
- Setting up context for agent teams or parallel reviews
- Onboarding someone (human or agent) to an unfamiliar area
