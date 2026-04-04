---
name: pr-followup
description: Follow-up on PR review comment replies. Use when someone says "check if they addressed my comments", "follow up on PR feedback", "did they fix what I asked?", or when evaluating developer responses to review feedback.
context: fork
agent: Explore
disable-model-invocation: true
allowed-tools: Bash(gh:*), Bash(git:*), Read, Grep, Glob
argument-hint: <pr_url> <discussion_url1> [discussion_url2] ...
---

# PR Follow-up Review (Subagent Mode)

You are reviewing developer responses to previous code review comments.

## Input

**Arguments**: $ARGUMENTS

Parse the first URL as the PR URL, remaining URLs as discussion threads to review.

### Example Invocation

```
/pr-followup https://github.com/org/repo/pull/42 https://github.com/org/repo/pull/42#discussion_r1234567 https://github.com/org/repo/pull/42#discussion_r1234568
```

This reviews PR #42 and evaluates responses to two specific discussion threads.

## Dynamic Context

### PR Current State
!`gh pr view --json number,title,state,reviewDecision 2>/dev/null || echo "Fetch PR info manually"`

### Latest Changes
!`gh pr diff --name-only 2>/dev/null | head -20 || echo "No diff available"`

### PR Comments (Recent)
!`gh pr view --comments --json comments --jq '.comments[-5:]' 2>/dev/null || echo "No comments"`

## Review Process

For each discussion URL provided:

1. **Fetch the discussion** using `gh api`
2. **Read the original comment** (your review feedback)
3. **Read the developer's response**
4. **Evaluate the response**:
   - Did they address the concern?
   - Did they provide valid reasoning for an alternative approach?
   - Is the fix implemented correctly?
5. **Determine resolution status** using the decision tree below

### Resolution Decision Tree

```
Developer responded to your comment?
├── YES: Did they make code changes?
│   ├── YES: Does the change fix the original concern?
│   │   ├── YES → RESOLVED
│   │   └── NO → PENDING (explain what's still wrong)
│   └── NO: Did they provide valid reasoning?
│       ├── YES: Is the reasoning technically sound?
│       │   ├── YES → ACCEPTABLE_ALTERNATIVE
│       │   └── NO → DISAGREED (explain why)
│       └── NO → PENDING (request code change or reasoning)
└── NO → PENDING (no response yet)
```

## Fetching Discussion Details

```bash
# Extract discussion ID from URL and fetch
gh api repos/{owner}/{repo}/pulls/{pr}/comments/{comment_id}
```

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| "Fetch PR info manually" | Wrong directory or PR not found | Verify PR URL and run `gh pr checkout` |
| Discussion URL 404 | Comment was deleted or resolved | Note as "DELETED — cannot evaluate" |
| No developer response | Comment hasn't been addressed yet | Mark as PENDING with "Awaiting response" |
| gh api rate limit | Too many API calls | Wait 60 seconds, retry with `--paginate` |
| Closed/merged PR | PR state changed since review | Note current state, evaluate responses anyway |

## Output Format

### Discussion Summary

| # | Original Issue | Developer Response | Resolution |
|---|----------------|-------------------|------------|
| 1 | [Your comment summary] | [Their response] | RESOLVED / PENDING / DISAGREED |
| 2 | [Your comment summary] | [Their response] | RESOLVED / PENDING / DISAGREED |

### Resolution Details

#### Discussion 1: [Topic]
- **Original Concern**: [What you raised]
- **Developer Response**: [What they said/did]
- **Assessment**: [Your evaluation]
- **Status**: RESOLVED / NEEDS_ACTION / ACCEPTABLE_ALTERNATIVE

### Recommended Actions

**Resolved - No Action Needed:**
- [List resolved items]

**Needs Follow-up Comment:**
```bash
# Reply to discussion
gh api repos/{owner}/{repo}/pulls/{pr}/comments/{comment_id}/replies \
  -f body="[Your follow-up response]"
```

**New Issues to Raise:**
```bash
# New inline comment if needed
gh api repos/{owner}/{repo}/pulls/{pr}/comments \
  -f body="[New concern]" \
  -f path="[file]" \
  -f line=[line] \
  -f commit_id="$(gh pr view --json headRefOid --jq '.headRefOid')"
```

### Updated Verdict

Based on the follow-up review:

- [ ] APPROVE - All concerns addressed
- [ ] APPROVE_WITH_NOTES - Acceptable with documented decisions
- [ ] REQUEST_CHANGES - Outstanding blockers remain

### Notes for Record

[Any decisions made, trade-offs accepted, or items deferred to future work]
