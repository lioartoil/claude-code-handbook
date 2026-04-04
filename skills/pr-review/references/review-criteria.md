# PR Review Criteria — Detailed Reference

> Loaded on demand during PR reviews for deep-dive guidance.

## 1. Correctness

- Verify logic against PR description/JIRA acceptance criteria
- Check edge cases: null, empty, boundary values, concurrent access
- Trace data flow through changed functions
- Confirm error paths return appropriate responses

## 2. Security (OWASP Top 10)

- SQL injection: parameterized queries only, no string concatenation
- XSS: output encoding, CSP headers, sanitize user input
- Auth: proper middleware, token validation, session handling
- Secrets: no hardcoded credentials, use env vars or secret managers
- CSRF: verify tokens on state-changing operations
- Access control: check authorization at every endpoint

## 3. Performance

- N+1 queries: look for loops with DB calls, use batch/preload
- Missing indexes on WHERE/JOIN columns
- Unbounded queries: ensure LIMIT/pagination on list endpoints
- Memory: large collections, streaming vs buffering
- Caching: appropriate cache invalidation strategy
- Connection pooling: proper pool sizing and timeout configuration

## 4. Maintainability

- Functions < 50 lines, single responsibility
- Clear naming, no magic numbers or strings
- Consistent with existing codebase patterns and conventions
- Appropriate abstraction level (not over-engineered, not duplicated)
- Error messages are descriptive and actionable

## 5. Testing

- New code has corresponding tests
- Existing tests updated to match behavior changes
- Edge cases covered (empty, null, boundary, error paths)
- Mocks/stubs appropriate (not over-mocked, testing real behavior)
- Test names describe the scenario being tested

## 6. Breaking Changes

- API contract changes (request/response shape, status codes)
- Database migrations (backward compatible? rollback plan?)
- Config changes (new env vars documented? defaults provided?)
- Message format changes (event schemas, queue payloads)
- Dependency version bumps (check changelogs for breaking changes)

## 7. JIRA Requirements

- Acceptance criteria from ticket are fully met
- Story points justified by actual complexity
- Cross-reference implementation with ticket description
- Edge cases from AC are handled

## 8. Go-Specific (when applicable)

- Error handling: no ignored errors, wrap with `fmt.Errorf("context: %w", err)`
- Goroutine leaks: context cancellation, WaitGroups, proper cleanup
- Interface compliance: small interfaces, accept interfaces return structs
- Nil pointer: check nil before dereferencing, especially from external data
- Race conditions: proper mutex usage, `go vet -race` clean

## 9. Vue.js-Specific (when applicable)

- Reactive data: proper use of `ref`/`reactive`, avoid direct mutation
- Component lifecycle: cleanup in `onUnmounted`, no memory leaks
- Props validation: proper type definitions, required vs optional
- Event handling: emit declarations, proper v-model bindings
- Router guards: auth checks, navigation protection
