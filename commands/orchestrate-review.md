# Orchestrate Review

Run a multi-agent PR review with specialized reviewers in parallel.
For standard PRs (< 300 lines, single concern), use `/review-and-comment` instead.

PR: $ARGUMENTS

---

## Agent Roster

| Agent               | Focus Area                                        | Activate When               | Key Criteria                                        |
| ------------------- | ------------------------------------------------- | --------------------------- | --------------------------------------------------- |
| **Correctness**     | Logic bugs, edge cases, error handling, data flow | Always                      | Does it work? Edge cases handled?                   |
| **Security**        | OWASP Top 10, auth, injection, data exposure      | Always                      | Reuses `/owasp-security` checklist                  |
| **Performance**     | N+1 queries, memory, concurrency, DB indexes      | BE files changed            | Missing indexes, unbounded queries, goroutine leaks |
| **JIRA Compliance** | Acceptance criteria coverage, requirement gaps    | When `--jira` flag provided | AC met? Story points justified?                     |

## Step 1: Setup

1. Parse PR URL/number from $ARGUMENTS
2. Fetch PR metadata:
   ```bash
   gh pr view $PR --json number,title,author,baseRefName,headRefName,additions,deletions,changedFiles
   ```
3. Fetch changed files:
   ```bash
   gh pr diff $PR --name-only
   ```
4. Determine which agents to activate:
   - **Always**: Correctness, Security
   - **If `.go`, `.sql`, or migration files changed**: Performance
   - **If `--jira TICKET` provided**: JIRA Compliance
5. Fetch PR diff for distribution to agents

## Step 2: Parallel Dispatch

For each activated agent, launch a Task with `subagent_type: "general-purpose"`:

- **Provide**: PR diff (relevant files only), changed file list, specific review criteria
- **Constrain**: "Only report findings in your focus area. Do not duplicate other agents' work."
- **Format**: Standardized finding table:

```
| Severity | File:Line | Issue | Suggestion |
|----------|-----------|-------|------------|
| BLOCKER  | path:123  | ...   | ...        |
```

### Agent Prompts

**Correctness Agent**: "Review this PR diff for logic bugs, unhandled edge cases, incorrect error handling, and data flow issues. Trace each change through its call chain."

**Security Agent**: "Review this PR diff for OWASP Top 10 vulnerabilities: injection, broken auth, sensitive data exposure, XSS, CSRF, insecure deserialization. Check for hardcoded secrets."

**Performance Agent**: "Review this PR diff for N+1 queries, missing database indexes, unbounded queries, goroutine leaks, unnecessary memory allocation, and missing pagination."

**JIRA Agent**: "Compare this PR diff against the JIRA ticket acceptance criteria. Verify each AC is addressed. Flag any AC not covered by the changes."

## Step 3: Synthesis

After all agents complete:

1. **Merge** all finding tables into one consolidated list
2. **Deduplicate** findings on the same file:line from multiple agents
3. **Resolve conflicts** (e.g., security says "block", performance says "ok" — security wins)
4. **Rank** by severity: BLOCKER > MAJOR > MINOR > SUGGESTION
5. **Count** findings per agent for the activity summary

## Step 4: Output

### Agent Activity Summary

| Agent       | Findings | Blockers | Status       |
| ----------- | -------- | -------- | ------------ |
| Correctness | X        | Y        | Done         |
| Security    | X        | Y        | Done         |
| Performance | X        | Y        | Done/Skipped |
| JIRA        | X        | Y        | Done/Skipped |

### Consolidated Findings

| #   | Severity | File:Line | Issue | Source Agent | Suggestion |
| --- | -------- | --------- | ----- | ------------ | ---------- |
| 1   | BLOCKER  | path:123  | ...   | Security     | ...        |

### Verdict

- [ ] APPROVE — No blockers, minor suggestions only
- [ ] APPROVE_WITH_SUGGESTIONS — No blockers, but improvements recommended
- [ ] REQUEST_CHANGES — Blockers must be resolved

---

## When to Use (vs `/review-and-comment`)

| Criterion   | `/review-and-comment` | `/orchestrate-review`         |
| ----------- | --------------------- | ----------------------------- |
| PR size     | < 300 lines           | > 500 lines                   |
| Risk level  | Standard              | Auth, payment, data-sensitive |
| Reviewer    | Single agent pass     | Multi-agent parallel          |
| Speed       | Faster                | More thorough                 |
| Team member | Experienced           | New (more thorough review)    |
