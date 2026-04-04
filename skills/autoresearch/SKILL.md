---
name: autoresearch
description: Hill-climbing optimizer for the headless review prompt. Runs test-score-mutate loops against a real PR. Use when someone says "autoresearch", "optimize the review prompt", or "improve the headless review".
context: fork
allowed-tools: Read,Write,Edit,Grep,Glob,Bash(gh:*),Bash(git:*),Bash(jq:*),Bash(claude:*),Bash(cp:*),Bash(diff:*),Bash(cat:*),Bash(mkdir:*),Bash(wc:*),Bash(sed:*),Bash(date:*),Bash(rm:*),Bash(tail:*),Bash(head:*),Bash(grep:*),Bash(open:*),Bash(echo:*)
argument-hint: <pr_url> [--iterations N]
---

# Autoresearch: Headless Review Prompt Optimizer

You are an optimization agent applying Karpathy's autoresearch method to the headless PR review prompt. You will run a hill-climbing loop: make one small change → test against a real PR → score → keep if better, revert if worse.

**Input**: $ARGUMENTS

## Step 0: Setup

### Parse Arguments

Extract from `$ARGUMENTS`:
- **PR_URL** (required): A GitHub PR URL, e.g. `https://github.com/your-org/your-service/pull/100`
- **--iterations N** (optional, default 3, max 5): Number of optimization rounds

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

Print the baseline score: `Baseline: X/6 — [PASS/FAIL per item]`

## Step 3: Optimization Loop

For each iteration `i` from 1 to N:

### 3a. Analyze Failures

Read `scores.json`. Identify which checklist items FAIL. If all pass (6/6), attempt meta-improvements:
- Tighten confidence thresholds (e.g., Medium 80→85)
- Add worked examples to phases
- Strengthen false positive exclusion rules

### 3b. Map Failure to Target Phase

| Failing Item | Target Phase | Strategy |
|-------------|-------------|----------|
| 1 (duplicates) | Phase 5.75 | Add keyword overlap detection, strengthen dedup rules |
| 2 (no fix) | Phase 6 | Add "MUST include Suggested Fix with code block" |
| 3 (not in diff) | Phase 4.5 | Add "verify line in diff before flagging" |
| 4 (upstream FP) | Phase 4 | Add "trace call chain before flagging missing validation" |
| 5 (length) | Phase 7 | Tighten compact format, add char count reminder |
| 6 (verdict) | Phase 7 | Move verdict logic closer to API call, add verification step |

If multiple items fail, prioritize: 3 > 4 > 1 > 2 > 6 > 5 (items that cause author frustration first).

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
**Score**: X/6 (was Y/6)
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
- Score progression (X/6 per round)
- Pass/fail grid per checklist item
- Changelog entries with kept/reverted status
- Current status (running/complete)

## Step 5: Final Report

After all iterations complete:

1. Clean up worktree: `cd ~/workspace/your-org/$REPO_NAME && git worktree remove "$WORKTREE_PATH" 2>/dev/null`

2. Print final report:

```
## Autoresearch Complete

**PR**: <PR_URL>
**Baseline**: X/6 → **Final**: Y/6
**Iterations**: N (Z kept, W reverted)

### Changes Applied
[from changelog.md]

### Files
- Optimized prompt: ~/.claude/scripts/headless-review-prompt.optimized.md
- Changelog: ~/.claude/state/autoresearch/changelog.md
- Dashboard: ~/.claude/state/autoresearch/dashboard.html
- Scores: ~/.claude/state/autoresearch/scores.json

### Diff
[output of: diff ~/.claude/scripts/headless-review-prompt.md ~/.claude/scripts/headless-review-prompt.optimized.md]
```

3. Ask: "Apply the optimized prompt as the new default? This will replace `headless-review-prompt.md` with the optimized version."

## Important Notes

- **NEVER modify** `~/.claude/scripts/headless-review-prompt.md` directly. Always work on `.optimized.md`.
- **NEVER post** real GitHub comments during testing. The dry-run preamble prevents this.
- **Each `claude -p` run takes 5-15 minutes**. Be patient and track progress via dashboard.
- **The same PR is used for all iterations** to ensure consistent scoring baseline.
- **If `claude -p` fails** (non-zero exit, no REVIEW_COMPLETE line), score as 0/6 and revert.
