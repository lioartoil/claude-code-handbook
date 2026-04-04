# /quarterly-review

Review and update quarterly goals and OKRs progress.

## Usage

```
/quarterly-review           # Current quarter
/quarterly-review Q4        # Specific quarter
/quarterly-review --create  # Create new quarter goals
```

## Prompt

ultrathink, then review and update quarterly goals.

**Steps:**

1. **Determine the quarter**:

   - Use current quarter unless specified: $ARGUMENTS
   - Calculate quarter boundaries (Q1: Jan-Mar, Q2: Apr-Jun, Q3: Jul-Sep, Q4: Oct-Dec)

2. **Find or create quarterly file**:

   - Look for `tracking/quarterly/{YYYY}-Q{X}-goals.md`
   - If not exists or --create, create from `tracking/quarterly/_template.md`

3. **If creating new quarter**:

   - Review previous quarter's outcomes
   - Carry over incomplete items if still relevant
   - Set new OKRs based on:
     - Team/company objectives
     - Technical debt priorities
     - Infrastructure needs
     - Team development goals

4. **If reviewing existing quarter**:

   - **Update OKR progress**:

     - Calculate current vs target for each key result
     - Update progress percentages
     - Assess confidence levels (High/Med/Low)

   - **Review technical initiatives**:

     - Check sprint history for completed items
     - Update status of each initiative

   - **Assess team development**:

     - Check progress on skill development
     - Update certification status

5. **Analyze trends**:

   - Compare velocity across sprints in quarter
   - Track technical debt reduction
   - Measure against quarterly metrics

6. **Add review log entry**:
   - Date of review
   - Key observations
   - Action items

**Output format:**

```
## Q{X} {YEAR} Progress Review

**Review Date**: {date}
**Days Remaining**: X

### OKR Summary

| Objective | Progress | Confidence |
|-----------|----------|------------|
| Objective 1 | X% | 🟢/🟡/🔴 |
| Objective 2 | X% | 🟢/🟡/🔴 |

### Key Results at Risk
- KR description (currently at X%, target Y%)

### Recommendations
1. Action item 1
2. Action item 2

### Next Review
{next_review_date}
```

**File location**: `tracking/quarterly/{YYYY}-Q{X}-goals.md`

**Best Practice**:

- Full review monthly (1st of each month)
- Quick check bi-weekly
- Deep planning at quarter start
