# /sprint-status

Check and update the current sprint's progress status.

## Usage

```
/sprint-status          # Current sprint status
/sprint-status sp25.24  # Specific sprint
/sprint-status --sync   # Sync with JIRA and GitHub
```

## Prompt

ultrathink, then check and update the sprint status.

**Steps:**

1. **Identify current sprint**:
   - Check CLAUDE.md for current sprint ID
   - Or use sprint ID from argument: $ARGUMENTS

2. **Find or create status file**:
   - Look for `tracking/sprints/{sprint_id}-status.md`
   - If not exists, create from `tracking/sprints/_template-status.md`

3. **Gather data** (if --sync or first time):
   - Fetch JIRA sprint data using `jira` CLI
   - Fetch GitHub issues using `gh` CLI
   - Check `docs/sprint-{sprint_id}-assignments.md` for assignments

4. **Update status sections**:
   - **Progress Overview**: Calculate points done/remaining
   - **Team Status**: Update each assignee's progress
   - **Completed**: List items marked done since last update
   - **In Progress**: Current work items
   - **Blocked**: Any blockers identified
   - **Risks**: Flag items at risk of missing sprint

5. **Calculate metrics**:
   - Velocity percentage
   - Days remaining vs work remaining
   - Burndown trend

**Output format:**

```md
## Sprint {sprint_id} Status - Day X of Y

### Progress: XX% (X of Y points)

| Status      | Count | Points |
| ----------- | ----- | ------ |
| Done        | X     | X      |
| In Progress | X     | X      |
| Blocked     | X     | X      |
| Remaining   | X     | X      |

### Team Summary

[Brief status per team member]

### Risks

[Any items at risk]

### Next Actions

[Priority items for focus]
```

**File location**: `tracking/sprints/{sprint_id}-status.md`

**Integration**:

- JIRA: `jira sprint list --current`
- GitHub: `gh issue list --label sprint-{id}`
