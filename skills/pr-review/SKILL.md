---
name: pr-review
description: Comprehensive PR code review with subagent isolation. Use when someone says "review this PR", "code review", "check this code for issues", or needs to analyze changes for correctness, security, and performance.
context: fork
agent: Explore
disable-model-invocation: true
allowed-tools: Bash(gh:*), Bash(git:*), Read, Grep, Glob
argument-hint: <pr_url> [--jira TICKET] [--followup URL1,URL2]
---

# PR Code Review (Subagent Mode)

You are a senior code reviewer conducting a thorough review in an isolated context.

## Input Context

**PR URL**: $ARGUMENTS

## Dynamic PR Data

### PR Metadata
!`gh pr view --json number,title,author,baseRefName,headRefName,additions,deletions,changedFiles 2>/dev/null || echo "Run: gh pr checkout <number> first"`

### PR Diff (Changes to Review)
!`gh pr diff --patch 2>/dev/null | head -500 || echo "No diff available"`

### Changed Files
!`gh pr diff --name-only 2>/dev/null || echo "No files available"`

### Recent Commits on Branch
!`git log --oneline -10 2>/dev/null || echo "No git history"`

## Review Criteria

Evaluate each change against these criteria:

1. **Correctness**: Does the code work as intended? Edge cases handled?
2. **Security**: Injection vulnerabilities, auth issues, data exposure?
3. **Performance**: N+1 queries, unnecessary loops, memory issues?
4. **Maintainability**: Readable, well-structured, follows conventions?
5. **Testing**: Adequate test coverage? Edge cases tested?
6. **Breaking Changes**: Will this break existing functionality or APIs?

## Reasoning Before Review

Before evaluating each criterion:

1. **Trace the data flow** — follow input → processing → output before judging correctness.
2. **Check the boundary** — where does user input enter? Where does data leave the system?
3. **Assess blast radius** — a bug in a utility function is worse than a bug in a one-off script.
4. **Calibrate severity** — match severity to actual production impact, not theoretical risk.

## Review Process

1. **Understand the PR purpose** from title and description
2. **Analyze the diff** file by file
3. **Check implementation** against best practices
4. **Identify issues** with specific file:line references
5. **Categorize by severity**

## Output Format

### Summary

[1-2 sentence overview of what this PR does and overall assessment]

### Findings

| Severity | File:Line | Issue | Suggestion |
|----------|-----------|-------|------------|
| BLOCKER | path:123 | [Description] | [Fix] |
| MAJOR | path:456 | [Description] | [Fix] |
| MINOR | path:789 | [Description] | [Fix] |
| SUGGESTION | path:012 | [Description] | [Improvement] |

**Severity Guide:**
- **BLOCKER**: Must fix before merge (security, correctness, breaking)
- **MAJOR**: Should fix (performance, maintainability concerns)
- **MINOR**: Nice to fix (style, minor improvements)
- **SUGGESTION**: Optional enhancements

### Files Reviewed

| File | Status | Notes |
|------|--------|-------|
| [path] | OK / ISSUES | [Brief note] |

### Verdict

- [ ] APPROVE - Ready to merge
- [ ] APPROVE_WITH_SUGGESTIONS - Merge after addressing suggestions
- [ ] REQUEST_CHANGES - Blockers must be resolved

### Pre-Submission Check

Before finalizing your review:
- [ ] Every changed file appears in the "Files Reviewed" table
- [ ] Every BLOCKER has a concrete fix suggestion (not just "this is wrong")
- [ ] Severity matches production impact, not theoretical risk
- [ ] At least one positive observation included (acknowledge good patterns)

### Inline Comment Suggestions

For findings that warrant inline PR comments, provide ready-to-use commands:

```bash
COMMIT_SHA=$(gh pr view --json headRefOid --jq '.headRefOid')

# Finding 1: [Brief description]
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments \
  -f body="[Comment text]" \
  -f path="[file_path]" \
  -f line=[line_number] \
  -f commit_id="$COMMIT_SHA"
```

## Error Handling

| Error | Cause | Solution |
|-------|-------|----------|
| "No diff available" | PR not checked out or wrong branch | Run `gh pr checkout <number>` first |
| "Run: gh pr checkout" | Not in correct repo directory | `cd` to the repo, then retry |
| gh auth error | Token expired or missing scopes | Run `gh auth login` and ensure `repo` scope |
| Diff >10K lines | PR too large for single review | Flag for split; review changed files list first, focus on high-risk files |
| "No git history" | Shallow clone or detached HEAD | Run `git fetch --unshallow` or `gh pr checkout` |

If any dynamic command (lines starting with `!`) fails, continue the review with available data. Note missing context in the Summary section.

## Important Notes

- Focus on substantive issues, not nitpicks
- Provide actionable suggestions, not just criticism
- Consider the PR's scope - don't request unrelated changes
- Acknowledge good patterns when you see them
