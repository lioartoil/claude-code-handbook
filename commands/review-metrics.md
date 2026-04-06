---
name: review-metrics
description: Use when analyzing HRP review effectiveness metrics and outcomes data. Identifies improvement areas across review periods.
argument-hint: "[period]"
---

# Review Effectiveness Metrics

Analyze HRP review effectiveness by reading metrics and outcomes data.

## Arguments

- `$ARGUMENTS` — optional period filter: `7d` (default), `30d`, or `all`

## Instructions

Read both JSONL files:
- `~/.claude/state/review-metrics.jsonl` — review-time data (findings, severity, confidence, PR size)
- `~/.claude/state/review-outcomes.jsonl` — outcome data (author replies, acceptance, dismissals)

Parse each line as JSON. Join on `pr_url + head_sha`. Filter by period argument (default 7 days from today).

**All line/file metrics MUST use `reviewable_*` fields, not `total_*`.** Raw totals include lock files, generated code, and binaries — they are noise.

Generate a report with these 7 sections:

### 1. Overview
- Total reviews in period
- Total findings posted (by severity)
- Avg findings per review
- Avg reviewable lines per PR

### 2. Acceptance Rate (Two Measures)

**Code-Addressed Rate** = `sum(findings_addressed) / sum(comments_posted) * 100`
- Files we commented on were modified in a post-review commit
- Conservative measure — misses squash-merge fixes and deferred fixes

**Engagement-Adjusted Rate** = `sum(findings_addressed + positive_replies) / sum(comments_posted) * 100` (capped at 100%)
- Code fixes + positive acknowledgments ("fixed", "good catch", "will fix")
- More realistic measure — captures intent even when code wasn't changed in this PR

Report BOTH rates. Industry baseline: 70%+ (Cursor Bugbot benchmark).

**Category × Acceptance cross-reference** — for each category (security, logic, performance, maintainability, style):
- Count findings in that category (from `findings_by_category` in metrics)
- Calculate code-addressed rate for PRs dominated by that category
- Flag categories with <15% acceptance — these are candidates for HRP tuning
- This tells us WHICH types of findings are valuable vs noise

**Trend**: compare current period vs previous same-length period

### 3. False Positive Rate
- Overall: `sum(confirmed_fp) / sum(total_findings) * 100`
- By category (from findings_by_category in metrics + fp_category in outcomes)
- Compare against thresholds:
  - Security: <3% (CodeAnt target)
  - Logic/Bugs: <3%
  - Maintainability: <5%
  - Style: <2%
  - Overall: <10%
- Flag any category exceeding its threshold

### 4. Author Engagement
- Reply rate: `reviews_with_replies / total_reviews * 100`
- Avg replies per review
- Sentiment breakdown: positive / neutral / negative counts and percentages
- Sample replies (up to 3 from author_reply_samples)

### 5. Review Credibility
- Dismissal rate: `dismissed_reviews / total_reviews * 100`
- Positive reaction rate: `thumbs_up / (thumbs_up + thumbs_down + confused) * 100`
- Flag if dismissal rate > 20%

### 6. Normalization
- Findings per 100 reviewable lines: `(total_comments / total_reviewable_lines) * 100`
- By category: same formula per category
- Compare across repos if data spans multiple repos

### 7. Alerts
Flag any metric crossing these thresholds (from CodeAnt/CodeRabbit research):
- FP rate > 10% overall or > 3% for security/logic
- Engagement-adjusted rate < 50% (use engagement-adjusted, not code-addressed, for alerts)
- Dismissal rate > 20%
- Escaped defects > 0
- FP rate trend: increasing >2% over prior period signals model drift

Format as a clean markdown table. If either JSONL file is missing or empty, report that and suggest running `cron-review-outcomes.sh` first.
