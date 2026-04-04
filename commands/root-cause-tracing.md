# Root Cause Tracing

Trace the bug or issue below backward through the call chain to find the original trigger. **NEVER fix just where the error appears.**

Issue: $ARGUMENTS

---

## Core Principle

Bugs manifest deep in the call stack, but the root cause is upstream. Your instinct is to fix at the symptom — resist it. Trace backward until you find the original trigger, then fix at the source.

---

## The 5-Step Tracing Process

### Step 1: Observe the Symptom

Document exactly what you see:

- Error message and full stack trace
- Which component/service reports the error
- When it happens (always? intermittent? under load?)

### Step 2: Find the Immediate Cause

What code directly produces this error?

- Read the error line in source code
- Identify what value/state is wrong at that point
- Example: `db.Where("space_id = ?", spaceID)` returns 0 rows — is `spaceID` empty?

### Step 3: Ask "What Called This?"

Trace one level up:

- Who passed the invalid value?
- Where did they get it from?
- What transformation happened between caller and callee?

### Step 4: Keep Tracing Up

Repeat Step 3 until you can't go further:

```
Error in handler → called by middleware → called by router → bad value from request parsing → invalid client state
```

At each level, ask:

- What value was passed?
- Was it already wrong at this point?
- Where did it come from?

### Step 5: Find the Original Trigger

The root cause is where valid data first becomes invalid:

- A default value that should have been set
- A race condition between initialization and use
- A missing validation at system boundary
- A config/environment difference between environments

---

## Adding Instrumentation

When you can't trace manually, add diagnostic logging at each boundary:

```go
// Before the problematic operation
func processRequest(ctx context.Context, spaceID string) error {
    log.Info("processRequest called",
        "spaceID", spaceID,
        "caller", runtime.Caller(1),
        "goroutine", runtime.NumGoroutine(),
    )
    // ... rest of function
}
```

```sql
-- For PostgreSQL query issues
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT ... FROM hierarchy_positions WHERE space_id = $1;
```

**Tips:**

- Log BEFORE the dangerous operation, not after it fails
- Include: input values, caller info, timestamps, environment context
- Use structured logging (key=value) for searchability
- For Cloud Run: use `severity` field for Cloud Logging integration

---

## Defense-in-Depth After Fixing

After fixing the root cause, add validation at EACH layer to prevent recurrence:

```
Layer 1: Entry point — validate input (reject empty/invalid early)
Layer 2: Service layer — assert preconditions
Layer 3: Data layer — constrain at database level (NOT NULL, CHECK, indexes)
Layer 4: Monitoring — alert on anomalous patterns
```

Each layer should independently prevent the bug, so if any one layer fails, the others catch it.

---

## Decision Flow

```
Found the error location?
  → What value is wrong here?
    → Who passed that value?
      → Was it already wrong there?
        → YES: Keep tracing up (repeat)
        → NO: The corruption happens HERE — this is your root cause
          → Fix at this point
          → Add validation at every layer below
```

---

## Process

1. Document the symptom from $ARGUMENTS
2. Find the immediate cause in source code
3. Trace backward through call chain (Steps 2-4)
4. Identify the original trigger (Step 5)
5. Fix at the SOURCE, not the symptom
6. Add defense-in-depth at each layer
7. Verify the fix resolves the original symptom
