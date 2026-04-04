# Scope Management and Pull Request Discipline

> **CRITICAL:** This MUST be applied to EVERY task. Scope discipline is non-negotiable.

## Core Principle

**Golden Rule:** ONLY implement what is EXPLICITLY required to achieve the stated goal. Everything else MUST become a GitHub issue. NO EXCEPTIONS.

## Pre-Work Protocol

Before writing ANY code:

1. **Define Scope Boundaries** — list Core Scope (will implement) vs Out of Scope (create issues)
2. **"Is This Required?" Test** — if the core goal can be achieved without it, create an issue instead
3. **Hard Size Limits** — Target: 200-500 lines | Warning: 500-1,000 | STOP: 1,000+

## During-Work Protocol

1. **Reject Scope Creep Signals**
   - "While we're at it..." / "It would be nice to..." / "Since we're touching this file..." → STOP → Create issue
   - Only acceptable thought: "Is this required for the core goal?"

2. **When Tempted to Add Something** — STOP → Create GitHub issue → Link to current PR → Inform user → Return to core scope

3. **Bug Handling**: <5 lines blocking core goal = include | 5-10 lines = ask user | >10 lines = separate PR

4. **Documentation**: Fix wrong info = in scope | New comprehensive docs = out of scope → create issue

5. **Testing Rules**:
   - REQUIRED: Fix broken tests, update tests for changes, add tests for new code
   - OUT OF SCOPE: Tests for existing untested code, refactor test structure

## Post-Work Protocol

1. **Scope Compliance Audit** — `git diff --stat develop...HEAD` | If >500 lines, justify each file
2. **Self-Review** — Does EVERY change serve the core goal? Could ANY be a separate PR? Reviewable in <30 min?
3. **Scope Documentation** — PR description must list core scope delivered + issues created for out-of-scope work
4. **Verification Before Done** — Does it work? Lint/type/build errors? Output matches request? Tests pass?

## Size Reference

| Lines Changed | Status    | Action            |
| ------------- | --------- | ----------------- |
| < 200         | Excellent | Ideal PR          |
| 200-500       | Good      | Target range      |
| 500-700       | Warning   | Justify each file |
| 700-1,000     | Stop      | MUST split        |
| > 1,000       | Rejected  | Scope creep       |

## Enforcement Rules

1. Never implement "nice to have" features — create issues
2. Never add documentation unless explicitly requested — create issues
3. Never refactor code unless directly required — create issues
4. Never fix unrelated bugs — create issues
5. Never optimize unless blocking — create issues
6. Always ask "Is this required?" before writing ANY code
7. Always create issues for future work
8. Always add tests for new code — REQUIRED
9. Always fix/update tests broken by changes — REQUIRED
10. Never add tests for existing untested code — create issues

## Ambiguous Requests

STOP → ASK user with minimal vs extended scope options → WAIT for confirmation

## Scope Expansion Exceptions

Only acceptable when ALL conditions met: Critical Blocker + Tightly Coupled + User Explicitly Approved. Document in PR.

## PR #42 Post-Mortem (Reference)

User asked "Implement the playground approach" (200 lines core). Result: 2,404 lines (92% scope creep). Should have been 1 focused PR + 7 issues.

## Quick Decision Flowchart

```
Thinking of adding something?
→ Did user explicitly request it? NO → Create issue
→ YES → Is it required for core goal? NO → Create issue
→ YES → Implement in PR
```

## Immediate Rejection List (Auto-create issues)

- Comprehensive documentation, CONTRIBUTING.md, setup scripts, developer tooling
- Unrelated bugs, refactoring for "cleanliness", tests for existing untested code
- Error message improvements (unless blocking), logging/monitoring, performance optimization

**Exception:** User explicitly says "also do X"
