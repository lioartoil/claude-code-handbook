# Inline Comment Patterns

> Ready-to-use patterns for GitHub PR inline comments.

## Severity Prefixes

| Prefix | When | Example |
|--------|------|---------|
| `BLOCKER:` | Must fix before merge | Security vulnerability, data loss risk |
| `MAJOR:` | Should fix | Performance issue, missing validation |
| `MINOR:` | Nice to fix | Style, naming, minor improvement |
| `SUGGESTION:` | Optional | Alternative approach, future consideration |

## Comment Templates

### Security Issue

```
BLOCKER: [Vulnerability type]

This [code] is vulnerable to [attack vector]. Consider [specific fix].

Reference: OWASP [category] — https://owasp.org/Top10/
```

### Performance Issue

```
MAJOR: Potential N+1 query

This query inside the loop at line [N] will execute once per iteration.
Consider using batch loading or a JOIN:

[code suggestion]
```

### Missing Error Handling

```
MAJOR: Unhandled error

`[function]` can return an error that is silently ignored here.
This could cause [consequence] in production.

Suggestion: wrap and return the error:
if err != nil {
    return fmt.Errorf("[context]: %w", err)
}
```

### Missing Test Coverage

```
MAJOR: No test coverage for [scenario]

This [function/endpoint] handles [critical logic] but has no test for [edge case].
Consider adding a test case for [specific scenario].
```

### Positive Feedback

```
Nice pattern — clean use of [pattern/approach]. This makes [benefit].
```

### Scope Concern

```
SUGGESTION: Out of scope?

This change to [file/function] doesn't appear directly related to the PR's stated goal.
Consider splitting into a separate PR if it's not blocking.
```

## GitHub API Command Template

```bash
COMMIT_SHA=$(gh pr view --json headRefOid --jq '.headRefOid')

# [Finding description]
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments \
  -f body="BLOCKER: [comment text]" \
  -f path="[file_path]" \
  -f line=[line_number] \
  -f commit_id="$COMMIT_SHA"
```
