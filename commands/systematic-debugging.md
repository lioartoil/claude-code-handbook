# Systematic Debugging

Apply this structured debugging methodology to investigate the issue described below. **NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST.**

Issue: $ARGUMENTS

---

## Mandatory Phases

### Phase 1: Root Cause Investigation

1. **Analyze the error** — read the full error message, stack trace, and logs
2. **Reproduce the issue** — confirm you can trigger it consistently
3. **Review recent changes** — check git log, recent deploys, config changes
4. **Gather evidence across boundaries** — trace data flow through components (API → service → database → response)
5. **Map the data flow** — identify where valid data becomes invalid

### Phase 2: Pattern Analysis

1. **Find working examples** — locate similar code/queries that work correctly
2. **Compare implementations** — diff working vs broken paths
3. **Identify differences** — what's unique about the failing case?
4. **Check dependencies** — are upstream/downstream services healthy?

### Phase 3: Hypothesis and Testing

1. **Form a specific, testable theory** — "The query fails because X index is missing"
2. **Test ONE variable at a time** — never change multiple things simultaneously
3. **Verify with evidence** — use metrics, logs, or query plans to confirm/deny
4. **Document what you tried** — record each hypothesis and result

### Phase 4: Implementation

1. **Write a test that reproduces the bug** (if applicable)
2. **Apply a single, minimal fix** at the root cause
3. **Verify the fix** — confirm the test passes, metrics improve
4. **Check for regressions** — ensure nothing else broke

---

## Safeguards

### STOP After 3 Failed Fixes

If 3+ attempted fixes have failed:
- **STOP fixing symptoms**
- Question whether the architecture is sound
- Re-examine your assumptions from Phase 1
- Consider whether you're debugging the wrong layer

### Red Flags (Process Violations)

You are violating this process if you:
- [ ] Attempt a "quick fix" before understanding the root cause
- [ ] Propose a solution before tracing the data flow
- [ ] Skip reproduction and go straight to code changes
- [ ] Change multiple things at once
- [ ] Say "let's try this" without a specific hypothesis
- [ ] Fix at the symptom point instead of the source

### Multi-Component Instrumentation

When the issue spans multiple layers (e.g., Cloud Run → API → PostgreSQL):

1. Add diagnostic logging at EACH boundary:
   - Request entry point (headers, params, timing)
   - Service layer (input/output, duration)
   - Database layer (query, params, execution plan, duration)
   - Response (status, payload size, total duration)
2. Identify WHERE failure occurs before analyzing WHY
3. Use `EXPLAIN ANALYZE` for query issues, Cloud Logging for service issues

---

## Expected Outcome

- Resolution in 15-30 minutes with 95% first-time fix rate (systematic)
- vs 2-3 hours with 40% success rate (random approach)
