# Scoring Checklist — 7 Binary Items

Score each item as PASS (1) or FAIL (0). Total score = sum of all items (0-7).

## Pre-Scoring Setup

Before scoring, fetch context needed for validation:

```bash
# Get the PR diff (for Item 3)
gh pr diff "$PR_URL" > /tmp/autoresearch-diff.txt

# Check if PR has prior reviews from your-username (for follow-up detection)
PRIOR_REVIEWS=$(gh api "repos/$REPO/pulls/$PR_NUMBER/comments?per_page=100" \
  --jq '[.[] | select(.user.login=="your-username") | select(.in_reply_to_id == null)] | length')
```

---

## Item 1: No Duplicate Findings

**Evidence**: PR #48 had 16 duplicate findings (76% false positive rate)

**Scoring**:

1. Extract all `DRY_RUN_COMMENT:` lines from output
2. Group by `path` field
3. For comments on the same file, compare body text — if >50% of non-stopword keywords overlap, mark as duplicate
4. PASS if zero duplicates found. FAIL if any duplicates exist.

```bash
# Extract comment paths and bodies
grep "DRY_RUN_COMMENT:" output.txt | while read -r line; do
  path=$(echo "$line" | sed 's/DRY_RUN_COMMENT: //' | jq -r '.path')
  body=$(echo "$line" | sed 's/DRY_RUN_COMMENT: //' | jq -r '.body')
  echo "$path|$body"
done > /tmp/ar-comments.txt

# Check for path duplicates with similar bodies
# Group by path, compare keyword sets within each group
```

If no `DRY_RUN_COMMENT:` lines exist (0 findings), score as PASS.

---

## Item 2: Every Comment Has a Suggested Fix

**Evidence**: PR #88 had 7 "what do you mean?" author replies

**Scoring**:

1. Extract each `DRY_RUN_COMMENT:` body
2. Check if body contains BOTH:
   - The phrase `Suggested Fix` (case-insensitive)
   - A code block (triple backticks: ```)
3. PASS if ALL comments have both. FAIL if ANY comment lacks either.

````bash
TOTAL=$(grep -c "DRY_RUN_COMMENT:" output.txt)
WITH_FIX=$(grep "DRY_RUN_COMMENT:" output.txt | grep -c "Suggested Fix")
WITH_CODE=$(grep "DRY_RUN_COMMENT:" output.txt | grep -c '```')
# PASS if TOTAL == 0 OR (WITH_FIX == TOTAL AND WITH_CODE == TOTAL)
````

If no `DRY_RUN_COMMENT:` lines exist, score as PASS.

---

## Item 3: Only Diff-Introduced Issues

**Evidence**: PR #89 had 8+ findings on pre-existing code; 6 outdated findings across PRs

**Scoring**:

1. Extract each `DRY_RUN_COMMENT:` path and line number
2. Check if the path appears in `gh pr diff` output
3. Check if the line number falls within a changed hunk (lines prefixed with `+` in unified diff)
4. PASS if ALL comments target lines in the diff. FAIL if ANY comment targets a line not in the diff.

```bash
# For each comment, verify path:line is in the diff
grep "DRY_RUN_COMMENT:" output.txt | while read -r line; do
  path=$(echo "$line" | sed 's/DRY_RUN_COMMENT: //' | jq -r '.path')
  lineno=$(echo "$line" | sed 's/DRY_RUN_COMMENT: //' | jq -r '.line')
  # Check if path exists in diff
  grep -q "^diff.*$path" /tmp/autoresearch-diff.txt || echo "NOT_IN_DIFF: $path:$lineno"
done
```

If no `DRY_RUN_COMMENT:` lines exist, score as PASS.

---

## Item 4: No Upstream-Guarded False Positives

**Evidence**: PR #88 had 4 "BFF handles this" replies; PR #48 had 2 "framework handles this"

**Scoring**:

1. Extract each `DRY_RUN_COMMENT:` body
2. Check if body contains words like "missing" combined with "validation", "check", "guard", "auth", "verify"
3. If so, verify the body ALSO contains one of:
   - A reference to the upstream caller/middleware (e.g., "BFF", "middleware", "interceptor", "upstream")
   - An explanation of why no upstream guard exists (e.g., "no middleware", "direct call", "public endpoint")
4. PASS if all "missing X" comments trace the call chain. FAIL if any just says "missing X" without context.

```bash
# Find comments about "missing" validation/checks
grep "DRY_RUN_COMMENT:" output.txt | while read -r line; do
  body=$(echo "$line" | sed 's/DRY_RUN_COMMENT: //' | jq -r '.body')
  # Check if it flags "missing" something
  if echo "$body" | grep -qi "missing.*\(validation\|check\|guard\|auth\|verify\)"; then
    # Must also reference upstream or explain absence
    if ! echo "$body" | grep -qi "upstream\|middleware\|interceptor\|BFF\|ingress\|caller\|call chain\|no.*guard"; then
      echo "UPSTREAM_FP: missing-check without call chain context"
    fi
  fi
done
```

If no comments match the "missing X" pattern, score as PASS.

---

## Item 5: Summary Under Character Limit

**Evidence**: Phase 7 rendering broke on GitHub with 18-row tables

**Scoring**:

1. Extract `DRY_RUN_REVIEW:` body
2. Determine if this is a follow-up review (output contains "Follow-up Review" or "Prior findings")
3. Measure character count of body
4. PASS if: follow-up ≤ 1,500 chars OR first review ≤ 3,000 chars. FAIL otherwise.

```bash
REVIEW_BODY=$(grep "DRY_RUN_REVIEW:" output.txt | sed 's/DRY_RUN_REVIEW: //' | jq -r '.body')
BODY_LEN=${#REVIEW_BODY}
IS_FOLLOWUP=$(echo "$REVIEW_BODY" | grep -ci "Follow-up Review\|Prior findings")
if [ "$IS_FOLLOWUP" -gt 0 ]; then
  [ "$BODY_LEN" -le 1500 ] && echo "PASS" || echo "FAIL ($BODY_LEN chars, limit 1500)"
else
  [ "$BODY_LEN" -le 3000 ] && echo "PASS" || echo "FAIL ($BODY_LEN chars, limit 3000)"
fi
```

If no `DRY_RUN_REVIEW:` line exists, score as FAIL (review should always be generated).

---

## Item 6: Correct Verdict

**Evidence**: Verdict must match severity count rules

**Scoring**:

1. Extract `event` from `DRY_RUN_REVIEW:` JSON
2. Extract finding counts from `REVIEW_COMPLETE:` line
3. Determine expected verdict:
   - Critical > 0 → `REQUEST_CHANGES`
   - High > 0 → `COMMENT`
   - Otherwise → `APPROVE`
4. PASS if actual event matches expected. FAIL otherwise.

```bash
EVENT=$(grep "DRY_RUN_REVIEW:" output.txt | sed 's/DRY_RUN_REVIEW: //' | jq -r '.event')
CRITICAL=$(grep "REVIEW_COMPLETE:" output.txt | sed -n 's/.*Critical: \([0-9]*\).*/\1/p')
HIGH=$(grep "REVIEW_COMPLETE:" output.txt | sed -n 's/.*High: \([0-9]*\).*/\1/p')

if [ "${CRITICAL:-0}" -gt 0 ]; then EXPECTED="REQUEST_CHANGES"
elif [ "${HIGH:-0}" -gt 0 ]; then EXPECTED="COMMENT"
else EXPECTED="APPROVE"
fi

[ "$EVENT" = "$EXPECTED" ] && echo "PASS" || echo "FAIL (got $EVENT, expected $EXPECTED)"
```

If no `REVIEW_COMPLETE:` line exists, score as FAIL (catastrophic output failure).

---

## Item 7: Findings Target High-Acceptance Categories

**Evidence**: review-outcomes.jsonl shows certain categories are consistently ignored by authors

**Scoring**:

1. Read `~/.claude/state/autoresearch/outcome-targets.json`
   - If file doesn't exist, score as PASS (no outcome data available — backward compatible)
2. Extract `scoring_item7.weak_categories` array and `scoring_item7.threshold_pct`
3. Extract all `DRY_RUN_COMMENT:` bodies from output
4. Classify each finding into a category using keyword matching:
   - `auth|injection|secret|XSS|CSRF|token|credential|permission` → `security`
   - `N\+1|query|latency|performance|index|cache|slow|timeout|memory` → `performance`
   - `bug|null|nil|panic|crash|infinite|race|logic|deadlock|overflow` → `logic`
   - `naming|convention|style|format|lint|comment|typo|spelling|casing` → `style`
   - Everything else → `maintainability`
5. Count findings in weak categories
6. PASS if weak-category findings < threshold_pct% of total. FAIL if >= threshold_pct%.

```bash
TARGETS_FILE="$HOME/.claude/state/autoresearch/outcome-targets.json"
if [[ ! -f "$TARGETS_FILE" ]]; then
  echo "PASS (no outcome targets — backward compatible)"
  ITEM7=1
else
  WEAK_CATS=$(jq -r '.scoring_item7.weak_categories[]' "$TARGETS_FILE" 2>/dev/null)
  THRESHOLD=$(jq -r '.scoring_item7.threshold_pct' "$TARGETS_FILE" 2>/dev/null || echo 30)

  if [[ -z "$WEAK_CATS" ]]; then
    echo "PASS (no weak categories identified)"
    ITEM7=1
  else
    TOTAL_COMMENTS=$(grep -c "DRY_RUN_COMMENT:" output.txt || echo 0)
    WEAK_COUNT=0

    while IFS= read -r line; do
      body=$(echo "$line" | sed 's/DRY_RUN_COMMENT: //' | jq -r '.body')
      body_lower=$(echo "$body" | tr '[:upper:]' '[:lower:]')

      category="maintainability"
      if echo "$body_lower" | grep -qE 'auth|injection|secret|xss|csrf|token|credential|permission'; then
        category="security"
      elif echo "$body_lower" | grep -qE 'n\+1|query|latency|performance|index|cache|slow|timeout|memory'; then
        category="performance"
      elif echo "$body_lower" | grep -qE 'bug|null|nil|panic|crash|infinite|race|logic|deadlock|overflow'; then
        category="logic"
      elif echo "$body_lower" | grep -qE 'naming|convention|style|format|lint|comment|typo|spelling|casing'; then
        category="style"
      fi

      if echo "$WEAK_CATS" | grep -q "$category"; then
        WEAK_COUNT=$((WEAK_COUNT + 1))
      fi
    done < <(grep "DRY_RUN_COMMENT:" output.txt)

    if [[ "$TOTAL_COMMENTS" -eq 0 ]]; then
      echo "PASS (0 findings)"
      ITEM7=1
    else
      WEAK_PCT=$((WEAK_COUNT * 100 / TOTAL_COMMENTS))
      if [[ "$WEAK_PCT" -lt "$THRESHOLD" ]]; then
        echo "PASS ($WEAK_COUNT/$TOTAL_COMMENTS = ${WEAK_PCT}% in weak categories, threshold ${THRESHOLD}%)"
        ITEM7=1
      else
        echo "FAIL ($WEAK_COUNT/$TOTAL_COMMENTS = ${WEAK_PCT}% in weak categories, threshold ${THRESHOLD}%)"
        ITEM7=0
      fi
    fi
  fi
fi
```

If no `DRY_RUN_COMMENT:` lines exist, score as PASS.

---

## Score Aggregation

```bash
SCORE=$((ITEM1 + ITEM2 + ITEM3 + ITEM4 + ITEM5 + ITEM6 + ITEM7))
echo "Score: $SCORE/7"
```

Write results to `scores.json` in the format:

```json
{
  "score": 5,
  "items": {
    "1_no_duplicates": true,
    "2_suggested_fix": true,
    "3_diff_only": false,
    "4_no_upstream_fp": true,
    "5_summary_length": true,
    "6_correct_verdict": true,
    "7_high_acceptance": true
  },
  "details": {
    "3_diff_only": "1 comment on handler.go:15 not in diff"
  },
  "traces": {
    "3_diff_only": {
      "checked": ["handler.go:15", "service.go:42"],
      "passed": ["service.go:42"],
      "failed": ["handler.go:15"],
      "reasoning": "handler.go:15 is in unchanged section, comment targets pre-existing code"
    }
  }
}
```

### Trace Logging Rules

For **every** checklist item (not just failures), populate the `traces` field:

- **`checked`**: All inputs examined (comment paths, body text excerpts, char counts, etc.)
- **`passed`**: Inputs that passed the check
- **`failed`**: Inputs that failed the check (empty array if PASS)
- **`reasoning`**: One-sentence explanation of *why* it passed or failed — not just *that* it did

**Why traces matter**: When the optimization loop (Step 3a) only sees binary pass/fail, it cannot diagnose root causes. Traces give the meta-agent the failure trajectory needed to make targeted fixes. Without them, improvement rate drops significantly (per AutoAgent research: scores-only optimization performs 40-60% worse than trace-informed optimization).

**Per-item trace examples**:

| Item                | `checked` contains                                          | `reasoning` example                                              |
| ------------------- | ------------------------------------------------------------ | -------------------------------------------------------------- |
| 1 (duplicates)      | Comment pairs compared, keyword overlap %                    | "auth.go had 2 comments with 65% keyword overlap on validation" |
| 2 (suggested fix)   | Each comment body's fix/code presence                          | "3/4 comments had fixes; service.go:88 missing code block"      |
| 3 (diff only)       | Each path:line vs diff hunk ranges                             | "handler.go:15 is outside hunk range 20-45"                      |
| 4 (upstream FP)     | Comments matching "missing X" pattern, upstream refs found     | "flagged missing auth but body references BFF middleware"       |
| 5 (summary length)  | Char count, follow-up detection result                        | "2,847 chars, first review, under 3,000 limit"                   |
| 6 (verdict)         | Critical/High counts, expected vs actual event                | "Critical:0 High:2 → expected COMMENT, got COMMENT"              |
