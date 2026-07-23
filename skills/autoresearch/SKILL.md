---
name: autoresearch
description: Hill-climbing optimizer for the headless review prompt. Runs test-score-mutate loops against a real PR. Use when someone says "autoresearch", "optimize the review prompt", or "improve the headless review".
context: fork
allowed-tools: Read,Write,Edit,Grep,Glob,Bash(gh:*),Bash(git:*),Bash(jq:*),Bash(claude:*),Bash(cp:*),Bash(diff:*),Bash(cat:*),Bash(mkdir:*),Bash(wc:*),Bash(sed:*),Bash(date:*),Bash(rm:*),Bash(tail:*),Bash(head:*),Bash(grep:*),Bash(open:*),Bash(echo:*)
argument-hint: <pr_url> [--iterations N]
---

# Autoresearch: Headless Review Prompt Optimizer

## Confirmation

Before proceeding, confirm with the user:

- This will run iterative test-score-mutate loops against a real PR
- Each iteration creates a worktree, runs a headless review, and scores the output
- Typical runs: 5-10 iterations, each taking 1-2 minutes

Ask using AskUserQuestion. If the user declines, stop immediately.

---

You are an optimization agent applying Karpathy's autoresearch method to the headless PR review prompt. You will run a hill-climbing loop: make one small change → test against a real PR → score → keep if better, revert if worse.

**Input**: $ARGUMENTS

## Step 0: Setup

### Parse Arguments

Extract from `$ARGUMENTS`:

- **PR_URL** (required): A GitHub PR URL, e.g. `https://github.com/your-org/your-service/pull/100`
- **--iterations N** (optional, default 3, max 5): Number of optimization rounds
- **--skip-regression** (optional): Skip golden-set regression gate in Step 4.5 (for rapid iteration during testing)

If no PR URL provided, pick one from the state file that has existing reviews (for follow-up testing):

```bash
# Pick a PR with prior reviews from your-username
cat ~/.claude/state/reviewed-prs.txt | awk '{print $1}' | sort -u | tail -10
```

### Initialize State

```bash
mkdir -p ~/.claude/state/autoresearch
cp ~/.claude/scripts/headless-review-prompt.md ~/.claude/scripts/headless-review-prompt.optimized.md
```

Parse the PR URL to extract REPO and PR_NUMBER:

```bash
REPO_NAME=$(echo "$PR_URL" | sed -n 's|.*github.com/[^/]*/\([^/]*\)/pull/.*|\1|p')
PR_NUMBER=$(echo "$PR_URL" | sed -n 's|.*/pull/\([0-9]*\).*|\1|p')
OWNER="your-org"
REPO="$OWNER/$REPO_NAME"
```

Fetch PR branch and set up worktree:

```bash
PR_BRANCH=$(gh pr view "$PR_URL" --json headRefName --jq '.headRefName')
WORKTREE_PATH="/tmp/autoresearch-${REPO_NAME}-${PR_NUMBER}"
```

If the repo exists locally at `~/workspace/your-org/$REPO_NAME`:

```bash
cd ~/workspace/your-org/$REPO_NAME
git fetch origin
git worktree add "$WORKTREE_PATH" "origin/$PR_BRANCH" 2>/dev/null || true
```

If it doesn't exist, clone it:

```bash
gh repo clone "$REPO" ~/workspace/your-org/$REPO_NAME -- --no-checkout
cd ~/workspace/your-org/$REPO_NAME
git fetch origin
git worktree add "$WORKTREE_PATH" "origin/$PR_BRANCH"
```

Initialize `scores.json`:

```json
{
  "pr_url": "<PR_URL>",
  "iterations": 3,
  "started_at": "<ISO_TIMESTAMP>",
  "baseline": null,
  "runs": []
}
```

Initialize `changelog.md`:

```markdown
# Autoresearch Changelog

**PR**: <PR_URL>
**Date**: <TODAY>
**Iterations**: N

---
```

## Step 0.5: Outcome-Informed Targeting

If `~/.claude/state/review-outcomes.jsonl` exists and has >10 records, run the meta-analysis to identify the weakest finding category and target HRP phase:

```bash
OUTCOMES_FILE="$HOME/.claude/state/review-outcomes.jsonl"
OUTCOME_COUNT=$(wc -l < "$OUTCOMES_FILE" 2>/dev/null || echo 0)

if [[ "$OUTCOME_COUNT" -gt 10 ]]; then
  echo "Running outcome meta-analysis ($OUTCOME_COUNT records)..."
  META_OUTPUT=$(~/.local/bin/claude -p "Read the file ~/.claude/scripts/autoresearch-meta-prompt.md and follow ALL instructions in it exactly. Output the required META_ markers at the end." \
    --allowedTools "Read,Bash(jq:*),Bash(wc:*)" \
    --output-format text \
    2>/dev/null)

  if echo "$META_OUTPUT" | grep -q "META_TARGET_PHASE:"; then
    echo "$META_OUTPUT" > ~/.claude/state/autoresearch/meta-output.txt

    # Parse targeting markers
    TARGET_PHASE=$(echo "$META_OUTPUT" | grep "^META_TARGET_PHASE:" | sed 's/^META_TARGET_PHASE: //')
    EDIT_REC=$(echo "$META_OUTPUT" | grep "^META_EDIT_RECOMMENDATION:" | sed 's/^META_EDIT_RECOMMENDATION: //')
    SCORING_ITEM7=$(echo "$META_OUTPUT" | grep "^META_SCORING_ITEM7:" | sed 's/^META_SCORING_ITEM7: //')
    REASONING=$(echo "$META_OUTPUT" | grep "^META_REASONING:" | sed 's/^META_REASONING: //')

    # Write outcome targets
    jq -n \
      --argjson target "$TARGET_PHASE" \
      --argjson edit "$EDIT_REC" \
      --argjson scoring "$SCORING_ITEM7" \
      --arg reasoning "$REASONING" \
      '{target_phase: $target, edit_recommendation: $edit, scoring_item7: $scoring, reasoning: $reasoning}' \
      > ~/.claude/state/autoresearch/outcome-targets.json

    PHASE_NAME=$(echo "$TARGET_PHASE" | jq -r '.phase')
    CATEGORY=$(echo "$TARGET_PHASE" | jq -r '.category')
    ACC_RATE=$(echo "$TARGET_PHASE" | jq -r '.acceptance_rate')
    echo "Outcome targeting: $PHASE_NAME ($CATEGORY, $ACC_RATE acceptance)"
  else
    echo "WARNING: Meta-analysis failed to produce markers. Proceeding without targeting."
  fi
else
  echo "Skipping outcome targeting ($OUTCOME_COUNT records, need >10)"
fi
```

If Step 0.5 produces `outcome-targets.json`, the optimization loop (Step 3) will use it. If not, the loop works exactly as before (backward compatible).

## Step 1: Build Dry-Run Prompt

Read the optimized prompt and prepend the dry-run preamble:

```bash
# Template substitution (same pattern as cron-pr-review.sh)
JIRA_TICKET=$(gh pr view "$PR_URL" --json body --jq '.body' | grep -oE '(PROJ|FEAT|BUG|TASK)-[0-9]+' | head -1)
JIRA_TICKET="${JIRA_TICKET:-auto}"

PROMPT=$(sed \
  -e "s|{{PR_URL}}|$PR_URL|g" \
  -e "s|{{JIRA_TICKET}}|$JIRA_TICKET|g" \
  -e "s|{{WORKSPACE}}|$HOME/workspace/your-org|g" \
  -e "s|{{CEP_WORKSPACE}}|$HOME/workspace/your-username/cep|g" \
  -e "s|{{WORKTREE_PATH}}|$WORKTREE_PATH|g" \
  "$HOME/.claude/scripts/headless-review-prompt.optimized.md")
```

Prepend the dry-run preamble to `$PROMPT`:

```
## DRY RUN MODE — DO NOT POST TO GITHUB

You are running in dry-run optimization mode. All analysis phases (1-5.75) execute normally.

For Phase 6: Instead of calling `gh api repos/$REPO/pulls/$PR_NUMBER/comments --method POST`, output each comment to stdout as a single line:
DRY_RUN_COMMENT: {"path": "<file>", "line": <N>, "body": "<full comment body>"}

For Phase 7: Instead of calling `gh api repos/$REPO/pulls/$PR_NUMBER/reviews --method POST`, output:
DRY_RUN_REVIEW: {"event": "<APPROVE|COMMENT|REQUEST_CHANGES>", "body": "<full review body>"}

The REVIEW_COMPLETE: line in Phase 8 MUST still be emitted exactly as specified.

CRITICAL: DO NOT call `gh api` with `--method POST`, `--method PUT`, or `--method PATCH`. Read-only GET calls are fine for analysis.
```

## Step 2: Run Baseline + Score

Execute the baseline review:

```bash
~/.local/bin/claude -p "$FULL_PROMPT" \
  --allowedTools "Read,Grep,Glob,Bash(gh:*),Bash(git:*),Bash(jq:*),Bash(cd:*),Bash(ls:*),Bash(wc:*),Bash(mkdir:*),Bash(cat:*),Bash(jira:*),Bash(curl:*)" \
  2>&1 > ~/.claude/state/autoresearch/baseline-output.txt
```

This takes 5-15 minutes. After completion, run the **Scoring Function** (see references/scoring-checklist.md) against `baseline-output.txt`.

Update `scores.json` with baseline results. Generate the initial `dashboard.html` from the template. Open it:

```bash
open ~/.claude/state/autoresearch/dashboard.html
```

Print the baseline score: `Baseline: X/7 — [PASS/FAIL per item]`

## Step 3: Optimization Loop

For each iteration `i` from 1 to N:

### 3a. Analyze Failures

Read `scores.json`. Identify which checklist items FAIL. If all pass (7/7), attempt meta-improvements:

- Tighten confidence thresholds (e.g., Medium 80→85)
- Add worked examples to phases
- Strengthen false positive exclusion rules
- If `~/.claude/state/autoresearch/outcome-targets.json` exists and its `edit_recommendation.action` is not `"no_change_needed"`, apply the recommended edit to the target phase

### 3b. Map Failure to Target Phase

| Failing Item        | Target Phase                | Strategy                                                                 |
| -------------------- | ---------------------------- | -------------------------------------------------------------------------- |
| 1 (duplicates)       | Phase 5.75                   | Add keyword overlap detection, strengthen dedup rules                      |
| 2 (no fix)           | Phase 6                       | Add "MUST include Suggested Fix with code block"                           |
| 3 (not in diff)      | Phase 4.5                     | Add "verify line in diff before flagging"                                  |
| 4 (upstream FP)      | Phase 4                        | Add "trace call chain before flagging missing validation"                  |
| 5 (length)           | Phase 7                        | Tighten compact format, add char count reminder                            |
| 6 (verdict)          | Phase 7                        | Move verdict logic closer to API call, add verification step               |
| 7 (low-acceptance)   | From `outcome-targets.json`   | Apply `edit_recommendation`: raise threshold, add exclusion, narrow scope   |

If multiple items fail, prioritize: 3 > 4 > 7 > 1 > 2 > 6 > 5 (outcome-targeting before cosmetic items).

### 3c. Make ONE Small Change

1. Back up current prompt: `cp ~/.claude/scripts/headless-review-prompt.optimized.md ~/.claude/state/autoresearch/prompt-backup.md`
2. Read the target phase section from `.optimized.md`
3. Make ONE surgical edit using the Edit tool. Change types:
   - Add a clarifying sentence or constraint
   - Add a "MUST" or "DO NOT" rule
   - Add a worked example showing expected behavior
   - Tighten or loosen a numerical threshold
   - Add to the false positive exclusion list
4. The change should be 1-5 lines. Never rewrite entire phases.

### 3d. Record Change

Append to `changelog.md`:

```markdown
## Iteration N — [KEPT/REVERTED]

**Target**: Phase X (Item Y — [description])
**Change**: [exact diff summary]
**Rationale**: [why this should fix the failing item]
**Score**: X/7 (was Y/7)
```

### 3e. Run Test

Rebuild the dry-run prompt with the modified `.optimized.md` (same Step 1 process). Execute:

```bash
~/.local/bin/claude -p "$FULL_PROMPT" \
  --allowedTools "Read,Grep,Glob,Bash(gh:*),Bash(git:*),Bash(jq:*),Bash(cd:*),Bash(ls:*),Bash(wc:*),Bash(mkdir:*),Bash(cat:*),Bash(jira:*),Bash(curl:*)" \
  2>&1 > ~/.claude/state/autoresearch/iteration-${i}-output.txt
```

### 3f. Score + Compare

Run the Scoring Function against `iteration-${i}-output.txt`. Compare to previous best:

- **New score ≥ previous best**: KEEP the change. Update `scores.json`.
- **New score < previous best**: REVERT via `cp ~/.claude/state/autoresearch/prompt-backup.md ~/.claude/scripts/headless-review-prompt.optimized.md`

### 3g. Update Dashboard

Regenerate `dashboard.html` with updated scores. The HTML auto-refreshes every 30 seconds.

## Step 4: Dashboard Generation

Write a self-contained HTML file to `~/.claude/state/autoresearch/dashboard.html`. Use the template from `references/dashboard-template.html`, filling in data from `scores.json`.

The dashboard shows:

- PR URL and iteration count
- Score progression (X/7 per round)
- Pass/fail grid per checklist item
- Changelog entries with kept/reverted status
- Current status (running/complete)

## Step 4.5: Golden-Set Regression Gate

If `--skip-regression` was passed, skip to Step 5 and note "Regression gate: SKIPPED" in the report.

This gate validates that the optimized HRP doesn't regress on previously-correct reviews. It runs once (end-only, not per-iteration) to keep cost reasonable.

### 4.5a. Load & Sample Golden Set

```bash
GOLDEN_SET="$HOME/.claude/state/golden-set.jsonl"
if [[ ! -f "$GOLDEN_SET" ]]; then
  echo "WARNING: No golden set found at $GOLDEN_SET — skipping regression gate"
  # Continue to Step 5 without gating
fi

GOLDEN_COUNT=$(wc -l < "$GOLDEN_SET")
echo "Golden set: $GOLDEN_COUNT records"
```

Sample 5 golden PRs, preferring repo diversity:

```bash
# Select 5 PRs: 1 from each unique repo, then fill remaining randomly
SAMPLED=$(jq -s '
  group_by(.repo) |
  [.[] | .[0]] |          # one per repo
  if length >= 5 then .[:5]
  else . + ([inputs] | map(select(.id as $id | [.[]] | map(.id) | index($id) | not)) | .[:(5 - length)])
  end |
  .[:5] | .[].id
' "$GOLDEN_SET")
```

### 4.5b. Run Golden PRs in Parallel

For each sampled golden PR, run a dry-run HRP review. Launch up to 3 concurrent `claude -p` processes:

```bash
REGRESSION_DIR="$HOME/.claude/state/autoresearch/regression"
mkdir -p "$REGRESSION_DIR"

for GOLDEN_ID in $SAMPLED; do
  GOLDEN_RECORD=$(jq -r "select(.id == \"$GOLDEN_ID\")" "$GOLDEN_SET")
  GOLDEN_PR_URL=$(echo "$GOLDEN_RECORD" | jq -r '.pr_url')
  GOLDEN_SHA=$(echo "$GOLDEN_RECORD" | jq -r '.head_sha')
  GOLDEN_REPO=$(echo "$GOLDEN_RECORD" | jq -r '.repo')

  # Build dry-run prompt using .optimized.md (same as Step 1)
  GOLDEN_JIRA=$(gh pr view "$GOLDEN_PR_URL" --json body --jq '.body' | grep -oE '(PROJ|FEAT|BUG|TASK)-[0-9]+' | head -1)
  GOLDEN_JIRA="${GOLDEN_JIRA:-auto}"
  GOLDEN_WORKTREE="/tmp/regression-${GOLDEN_REPO}-$(echo $GOLDEN_ID | sed 's/golden-//')"

  # Setup worktree for golden PR at specific SHA
  cd ~/workspace/your-org/$GOLDEN_REPO
  git fetch origin
  git worktree add "$GOLDEN_WORKTREE" "$GOLDEN_SHA" 2>/dev/null || true

  GOLDEN_PROMPT=$(sed \
    -e "s|{{PR_URL}}|$GOLDEN_PR_URL|g" \
    -e "s|{{JIRA_TICKET}}|$GOLDEN_JIRA|g" \
    -e "s|{{WORKSPACE}}|$HOME/workspace/your-org|g" \
    -e "s|{{CEP_WORKSPACE}}|$HOME/workspace/your-username/cep|g" \
    -e "s|{{WORKTREE_PATH}}|$GOLDEN_WORKTREE|g" \
    "$HOME/.claude/scripts/headless-review-prompt.optimized.md")

  # Prepend dry-run preamble (same as Step 1)
  GOLDEN_FULL_PROMPT="$DRY_RUN_PREAMBLE

$GOLDEN_PROMPT"

  # Launch in background (max 3 concurrent)
  ~/.local/bin/claude -p "$GOLDEN_FULL_PROMPT" \
    --allowedTools "Read,Grep,Glob,Bash(gh:*),Bash(git:*),Bash(jq:*),Bash(cd:*),Bash(ls:*),Bash(wc:*),Bash(mkdir:*),Bash(cat:*),Bash(jira:*),Bash(curl:*)" \
    2>&1 > "$REGRESSION_DIR/${GOLDEN_ID}-output.txt" &

  # Throttle: wait if 3 background jobs running
  while [[ $(jobs -r | wc -l) -ge 3 ]]; do sleep 5; done
done

# Wait for all background jobs
wait
```

### 4.5c. Score Each Golden PR

For each sampled golden PR, compare actual output against expected values:

```bash
PASS_COUNT=0
TOTAL_SAMPLED=0
REGRESSION_RESULTS="[]"

for GOLDEN_ID in $SAMPLED; do
  GOLDEN_RECORD=$(jq -r "select(.id == \"$GOLDEN_ID\")" "$GOLDEN_SET")
  OUTPUT_FILE="$REGRESSION_DIR/${GOLDEN_ID}-output.txt"
  TOTAL_SAMPLED=$((TOTAL_SAMPLED + 1))

  EXPECTED_VERDICT=$(echo "$GOLDEN_RECORD" | jq -r '.expected_verdict')
  MIN_CRITICAL=$(echo "$GOLDEN_RECORD" | jq -r '.min_findings.critical')
  MIN_HIGH=$(echo "$GOLDEN_RECORD" | jq -r '.min_findings.high')

  # Extract actual values from dry-run output
  ACTUAL_VERDICT=$(grep "DRY_RUN_REVIEW:" "$OUTPUT_FILE" | sed 's/DRY_RUN_REVIEW: //' | jq -r '.event' 2>/dev/null || echo "NONE")
  ACTUAL_CRITICAL=$(grep "REVIEW_COMPLETE:" "$OUTPUT_FILE" | sed -n 's/.*Critical: \([0-9]*\).*/\1/p' || echo "0")
  ACTUAL_HIGH=$(grep "REVIEW_COMPLETE:" "$OUTPUT_FILE" | sed -n 's/.*High: \([0-9]*\).*/\1/p' || echo "0")

  # Check: verdict matches OR is stricter (REQUEST_CHANGES > COMMENT > APPROVE)
  VERDICT_OK=false
  if [[ "$ACTUAL_VERDICT" == "$EXPECTED_VERDICT" ]]; then
    VERDICT_OK=true
  elif [[ "$EXPECTED_VERDICT" == "APPROVE" && "$ACTUAL_VERDICT" =~ ^(COMMENT|REQUEST_CHANGES)$ ]]; then
    VERDICT_OK=true  # stricter is acceptable
  elif [[ "$EXPECTED_VERDICT" == "COMMENT" && "$ACTUAL_VERDICT" == "REQUEST_CHANGES" ]]; then
    VERDICT_OK=true  # stricter is acceptable
  fi

  # Check: findings meet minimums
  FINDINGS_OK=true
  if [[ "${ACTUAL_CRITICAL:-0}" -lt "$MIN_CRITICAL" || "${ACTUAL_HIGH:-0}" -lt "$MIN_HIGH" ]]; then
    FINDINGS_OK=false
  fi

  # Overall: both checks must pass
  if [[ "$VERDICT_OK" == true && "$FINDINGS_OK" == true ]]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    STATUS="PASS"
  else
    STATUS="FAIL"
  fi

  echo "$GOLDEN_ID: $STATUS (verdict: $ACTUAL_VERDICT vs $EXPECTED_VERDICT, C:$ACTUAL_CRITICAL/$MIN_CRITICAL H:$ACTUAL_HIGH/$MIN_HIGH)"

  # Build result JSON for scores.json
  REGRESSION_RESULTS=$(echo "$REGRESSION_RESULTS" | jq \
    --arg id "$GOLDEN_ID" \
    --arg pr "$GOLDEN_PR_URL" \
    --arg exp_v "$EXPECTED_VERDICT" \
    --arg act_v "$ACTUAL_VERDICT" \
    --argjson v_ok "$VERDICT_OK" \
    --argjson f_ok "$FINDINGS_OK" \
    --arg status "$STATUS" \
    '. + [{id: $id, pr_url: $pr, expected_verdict: $exp_v, actual_verdict: $act_v, verdict_match: $v_ok, findings_match: $f_ok, overall: $status}]')
done
```

### 4.5d. Gate Decision

```bash
PASS_PCT=$((PASS_COUNT * 100 / TOTAL_SAMPLED))
GATE_THRESHOLD=80

if [[ "$PASS_PCT" -ge "$GATE_THRESHOLD" ]]; then
  GATE_STATUS="PASSED"
  echo "REGRESSION GATE PASSED — $PASS_COUNT/$TOTAL_SAMPLED ($PASS_PCT%) golden PRs matched"
else
  GATE_STATUS="FAILED"
  echo "⚠ REGRESSION GATE FAILED — $PASS_COUNT/$TOTAL_SAMPLED ($PASS_PCT%) golden PRs matched (threshold: $GATE_THRESHOLD%)"
  echo "The optimized prompt may have regressed on previously-correct reviews."
fi
```

### 4.5e. Update State & Cleanup

Write regression results to `scores.json`:

```json
{
  "regression_gate": {
    "status": "PASSED",
    "sampled": 5,
    "passed": 4,
    "threshold_pct": 80,
    "results": [ /* per-golden-PR results */ ]
  }
}
```

Clean up regression worktrees:

```bash
for GOLDEN_ID in $SAMPLED; do
  GOLDEN_REPO=$(jq -r "select(.id == \"$GOLDEN_ID\") | .repo" "$GOLDEN_SET")
  GOLDEN_WORKTREE="/tmp/regression-${GOLDEN_REPO}-$(echo $GOLDEN_ID | sed 's/golden-//')"
  cd ~/workspace/your-org/$GOLDEN_REPO
  git worktree remove "$GOLDEN_WORKTREE" 2>/dev/null || rm -rf "$GOLDEN_WORKTREE"
done
```

## Step 5: Final Report

After all iterations complete:

1. Clean up worktree: `cd ~/workspace/your-org/$REPO_NAME && git worktree remove "$WORKTREE_PATH" 2>/dev/null`

2. Print final report:

```
## Autoresearch Complete

**PR**: <PR_URL>
**Baseline**: X/7 → **Final**: Y/7
**Iterations**: N (Z kept, W reverted)

### Regression Gate
[PASSED/FAILED/SKIPPED] — X/5 golden PRs matched expectations

| Golden PR | Expected | Actual | Findings | Status |
|-----------|----------|--------|----------|--------|
| golden-001 (service#128) | COMMENT | COMMENT | 2C/3H ✓ | PASS |
| ... | ... | ... | ... | ... |

### Changes Applied
[from changelog.md]

### Files
- Optimized prompt: ~/.claude/scripts/headless-review-prompt.optimized.md
- Changelog: ~/.claude/state/autoresearch/changelog.md
- Dashboard: ~/.claude/state/autoresearch/dashboard.html
- Scores: ~/.claude/state/autoresearch/scores.json
- Regression outputs: ~/.claude/state/autoresearch/regression/

### Diff
[output of: diff ~/.claude/scripts/headless-review-prompt.md ~/.claude/scripts/headless-review-prompt.optimized.md]
```

3. Promotion decision:
   - If regression gate **PASSED** or **SKIPPED**: Ask "Apply the optimized prompt as the new default? This will replace `headless-review-prompt.md` with the optimized version."
   - If regression gate **FAILED**: Ask "⚠ Regression gate failed — X/5 golden PRs regressed. Apply anyway (risky), or revert to baseline?"

## Important Notes

- **NEVER modify** `~/.claude/scripts/headless-review-prompt.md` directly. Always work on `.optimized.md`.
- **NEVER post** real GitHub comments during testing. The dry-run preamble prevents this.
- **Each `claude -p` run takes 5-15 minutes**. Be patient and track progress via dashboard.
- **The same PR is used for all iterations** to ensure consistent scoring baseline.
- **If `claude -p` fails** (non-zero exit, no REVIEW_COMPLETE line), score as 0/7 and revert.
- **Golden-set regression** runs once at end (Step 4.5), not per-iteration. Use `--skip-regression` for rapid testing.
- **Regression gate requires** `~/.claude/state/golden-set.jsonl`. If missing, gate is skipped with a warning.
