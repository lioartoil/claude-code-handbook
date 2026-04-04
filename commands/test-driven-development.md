# Test-Driven Development

Apply TDD methodology to implement the feature or fix described below. **If you didn't watch the test fail, you don't know if it tests the right thing.**

Task: $ARGUMENTS

---

## The Absolute Rule

**Production code MUST NEVER precede a failing test.**

If code was written before a test:
- DELETE the code entirely
- Write the test FIRST
- Watch it FAIL
- THEN implement

No exceptions for "reference" or "adaptation." Keeping unverified code is technical debt.

---

## The Red-Green-Refactor Cycle

### RED — Write ONE Minimal Failing Test

1. Write a single test demonstrating the desired behavior
2. Use real code, not mocks (where practical)
3. Test the smallest meaningful unit of behavior
4. The test name should describe the expected behavior

### Verify RED

Run the test. Confirm it fails **for the expected reason**:
- Fails because the feature doesn't exist yet
- NOT because of typos, import errors, or wrong test setup
- If it fails for the wrong reason, fix the test first

### GREEN — Write the Simplest Passing Code

1. Implement the **minimum** code to make the test pass
2. Do NOT add unrequested features
3. Do NOT optimize prematurely
4. Hardcoding is acceptable if only one test exists

### Verify GREEN

1. Run the test — confirm it passes
2. Run ALL tests — confirm nothing else broke
3. If existing tests break, fix them before proceeding

### REFACTOR — Clean Up While Green

1. Remove duplication
2. Improve naming
3. Extract helpers if needed
4. Run ALL tests after each refactoring step — they must stay green

---

## Anti-Rationalization Guide

When tempted to skip TDD, recognize these excuses:

| Rationalization | Reality |
|----------------|---------|
| "I'll write tests after" | Tests-after verify what you remembered, not what matters |
| "It's a simple change" | Simple changes cause subtle bugs. Tests catch them. |
| "I already know it works" | You know it works for the case you're thinking of. Tests find the others. |
| "It'll be faster without tests" | Debugging without tests takes 3-10x longer |
| "Just this once" | This IS the rationalization. Stop. Write the test. |
| "The existing code has no tests" | That's tech debt. Don't add more. Test YOUR changes. |
| "Manual testing is enough" | Manual tests aren't repeatable, documented, or automated |

**If you're rationalizing, you need TDD most.**

---

## Workflow

1. Understand the requirement from $ARGUMENTS
2. Identify the first small, testable behavior
3. Write the test (RED)
4. Verify it fails correctly
5. Implement (GREEN)
6. Verify all tests pass
7. Refactor if needed
8. Repeat for the next behavior
9. Continue until the full requirement is met
