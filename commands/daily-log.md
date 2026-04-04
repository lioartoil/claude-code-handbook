# /daily-log

Create or update the daily task log for tracking accomplishments, blockers, and plans.

## Usage

```
/daily-log              # Create/update today's log
/daily-log yesterday    # Update yesterday's log
/daily-log 2025-12-01   # Update specific date
```

## Prompt

ultrathink, then create or update the daily log based on the current session's work.

**Reference Files:**

- Schedule: `tracking/schedule.md` (recurring meetings, sprint calendar, holidays)
- Template: `tracking/daily/_template.md`
- Context: `CLAUDE.md` (session handoff, sprint info)

**Steps:**

1. **Determine the date**: Use today's date unless a specific date is provided as argument: $ARGUMENTS
2. **Check schedule reference**: Read `tracking/schedule.md` for:
   - Current sprint info and day calculation
   - Today's scheduled meetings
   - Holidays and leave days
3. **Check for existing log**: Look for `tracking/daily/{date}.md`
4. **If creating new log**:

   - Copy template from `tracking/daily/_template.md`
   - Replace `{DATE}` with the actual date
   - Replace `{SPRINT_ID}` with current sprint from schedule/CLAUDE.md
   - Calculate sprint day from `tracking/schedule.md`
   - Replace `{TIMESTAMP}` with current timestamp
   - Add "Today's Meetings" section from schedule
   - Add "Plan for Today" based on:
     - Items from previous day's "Tomorrow's Plan"
     - Current sprint priorities from CLAUDE.md
     - Any pending items from recent sessions

5. **If updating existing log**:

   - Move completed items from "Plan for Today" to "Accomplished"
   - Update "In Progress" with current work status
   - Add any blockers encountered
   - Record discoveries and decisions from the session
   - Update "Tomorrow's Plan" if end of day

6. **Cross-reference**:

   - Check CLAUDE.md session handoff for context
   - Include relevant PR/issue numbers
   - Note any JIRA ticket progress

**Output format:**

- Show what was created/updated
- Summarize key items in the log
- Remind of tomorrow's priorities if end of day

**File location**: `tracking/daily/{YYYY-MM-DD}.md`

**Important**:

- Keep entries concise and actionable
- Focus on outcomes, not activities
- Link to issues/PRs where relevant
- Note time allocation if tracking capacity
