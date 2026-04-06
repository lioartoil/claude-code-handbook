---
name: weekly-review
description: Use when generating a weekly engineering summary. Aggregates accomplishments, learnings, and plans from daily logs.
disable-model-invocation: true
---

# /weekly-review

Create a weekly summary of accomplishments, learnings, and plans.

## Usage

```
/weekly-review          # Current week
/weekly-review W48      # Specific week
/weekly-review last     # Last week
```

## Prompt

ultrathink, then create or update the weekly review.

**Steps:**

1. **Determine the week**:

   - Use current ISO week unless specified: $ARGUMENTS
   - Calculate week start (Monday) and end (Sunday) dates

2. **Find or create weekly file**:

   - Look for `tracking/weekly/{YYYY}-W{XX}.md`
   - If not exists, create from `tracking/weekly/_template.md`

3. **Gather data from daily logs**:

   - Read all daily logs for the week from `tracking/daily/`
   - Aggregate accomplishments
   - Collect blockers encountered
   - Summarize discoveries and decisions

4. **Fetch external data**:

   - PRs merged this week: `gh pr list --state merged --search "merged:>={start_date}"`
   - Issues closed: `gh issue list --state closed --search "closed:>={start_date}"`
   - Compare with last week's metrics

5. **Synthesize the review**:

   - **Week Summary**: 2-3 sentence overview
   - **Key Accomplishments**: Top 5-7 achievements
   - **PRs Merged**: Table with links
   - **Issues Closed**: Table with links
   - **Challenges**: What was difficult
   - **Learnings**: Technical and process insights
   - **Next Week Focus**: Prioritized P0/P1/P2 items

6. **Calculate metrics**:

   - PRs reviewed/merged count
   - Issues closed count
   - Compare trends with previous week

**Output format:**

```
## Week {YYYY}-W{XX} Summary

**Period**: {start} - {end}

### Highlights
- Accomplishment 1
- Accomplishment 2
- Accomplishment 3

### Metrics
| Metric | This Week | Last Week | Trend |
|--------|-----------|-----------|-------|
| PRs Merged | X | Y | ↑/↓ |

### Next Week Priorities
1. Priority 1
2. Priority 2
```

**File location**: `tracking/weekly/{YYYY}-W{XX}.md`

**Best Practice**: Run this on Friday afternoon or Monday morning
