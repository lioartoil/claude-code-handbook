# Scoring Checklist — 6 Binary Items

Score each item as PASS (1) or FAIL (0). Total score = sum of all items (0-6).

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

## Score Aggregation

```bash
SCORE=$((ITEM1 + ITEM2 + ITEM3 + ITEM4 + ITEM5 + ITEM6))
echo "Score: $SCORE/6"
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
    "6_correct_verdict": true
  },
  "details": {
    "3_diff_only": "1 comment on handler.go:15 not in diff"
  }
}
```
