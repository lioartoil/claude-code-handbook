---
name: implement
description: Single-shot feature implementation from ticket to merged PR. Orchestrates brainstorming, API research, pattern scanning, TDD, code review, and verification — designed to deliver production-grade code in one pass.
context: fork
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Agent, AskUserQuestion, WebFetch, WebSearch, Skill, TaskCreate, TaskUpdate, TaskList
argument-hint: <TICKET-ID> [--draft] [--skip-review]
---

# Single-Shot Feature Implementation

## Confirmation

Before proceeding, confirm with the user:

- This will implement a full feature from ticket to PR (branch, code, tests, commit, push)
- Uses TDD — writes tests first, then implementation
- Creates a PR on GitHub when complete

Ask using AskUserQuestion. If the user declines, stop immediately.

---

You are an expert engineer implementing a feature from a ticket. Your goal is **production-grade code in a single pass** — no rework cycles.

This skill was refined through 4 retrospectives covering 53 issues: wrong abstractions, schema misalignment, missed patterns, naming inconsistency, config safety, DB robustness, and validation gaps. Each phase directly addresses one or more of these patterns.

## Input

`$ARGUMENTS` — a ticket ID (e.g., `PROJ-1784`, `1784`).

Optional flags:

- `--draft` — stop after Phase 3 (plan only, don't implement)
- `--skip-review` — skip Phase 6 review agents (faster but less thorough)

---

## Phase 0: Fetch & Understand (addresses: wrong abstraction)

1. **Fetch ticket** from your issue tracker:
   - Get story summary, description, acceptance criteria, subtasks
   - Get parent epic for broader context
   - Note assignee, sprint, story points

2. **Locate story docs** — search for existing documentation:
   - Check your team's standard docs locations (wiki, Notion, repo docs/)
   - Look for technical design docs, prototypes, or grooming notes

3. **Ask clarifying questions** using AskUserQuestion:
   - "How does the client submit this?" (single-form vs multi-step vs separate endpoint)
   - "Which services consume these types?" (domain vs shared package)
   - "Are there any design decisions already made?" (grooming notes, prototype)
   - "What does FE need after this operation?" (preview, render, lifecycle — catches related endpoints)

**Gate**: Do NOT proceed until client interaction pattern is confirmed.

---

## Phase 1: Research (addresses: schema misalignment, missed patterns)

Launch 3 parallel Explore agents:

### Agent 1: External API Research

- If the feature involves a third-party API: fetch current docs (official docs, SDK examples, or library documentation tools)
- If the feature uses cloud storage/messaging: check your org's shared utility libraries
- **Extract exact field names, types, required/optional, constraints**

### Agent 2: Existing Pattern Scan

- Scan the target repo for how similar features are implemented
- Check: import grouping, error handling, validation patterns, test patterns
- Check: CONVENTIONS.md, typed enums, Unicode handling, DB type casts
- Check: existing shared packages that should be reused
- Check: constructor return types — must return interfaces (not concrete structs)
- Check: test tooling — use your org's standard mocking + assertion libraries (not hand-written stubs)
- **HTTP handler pattern**: Search 3+ similar repos in your org for the exact framework + handler convention. Use the established framework — NOT a different one
- **Package naming**: Check sibling directories for naming pattern. Match existing siblings, don't invent new conventions
- **Convention scan** (BEFORE creating packages): Run `ls` on sibling directories to confirm naming patterns. Check acronym conventions (all-caps or mixed?), spelling conventions (American or British?), mock generation patterns
- **Config defaults**: Environment-specific values (callback URLs, service URLs) must have empty defaults. Let environment variables and deployment config set the actual values
- **Infrastructure client errors**: New infrastructure clients must return errors gracefully — NOT crash the process. Match existing graceful degradation patterns

### Agent 3: Prototype & Design Alignment

- If a prototype exists, extract field definitions
- If tech design exists, extract proposed structs
- Cross-reference: API schema x prototype x tech design
- **Flag any mismatches BEFORE coding**

**Gate**: All 3 agents must complete. Review their findings. Flag and resolve any mismatches.

---

## Phase 2: Architect (addresses: inconsistency across types)

1. **Design all related types together** — if multiple content types or entities are involved, design them ALL before implementing any. Check for:
   - Same field pattern across similar types
   - Shared constants (typed enums, not magic strings)
   - Shared validation helpers

2. **Write the implementation plan** to the plan file:
   - List every file to create/modify
   - List every struct/type with all fields (cross-referenced against API + prototype)
   - List every validation rule with its constraint source
   - List every test case

3. **Ask for plan approval** before proceeding.

**Gate**: Plan approved by user.

---

## Phase 3: Test-Driven Implementation (addresses: validation gaps)

**Test tooling**: Use your org's standard mocking + assertion libraries. Do NOT use hand-written stub structs.

**API gateway/BFF rule**: If working on a thin proxy layer, the service layer should be pure passthrough (no validation). The handler validates input format. The backend service validates business rules. Do NOT duplicate validation across layers.

For each component in the plan:

1. **Write tests FIRST** — for every validation rule, including:
   - Happy path (valid input)
   - Required field missing
   - Field exceeds max length (use multi-byte text like Thai/emoji for Unicode testing)
   - Invalid enum value
   - Edge cases: null, empty string, empty array, JSON `null`
   - Boundary: max+1 items, max+1 characters
   - **Edge case checklist** (for every new function):
     - What if input is nil/empty/zero?
     - What if the DB row doesn't exist?
     - What if the external API returns error?
     - What if the message is malformed (bad encoding, invalid JSON)?
     - What if the result set is 0 items after filtering?
     - What if the operation partially succeeds (some batches fail)?
     - What if the context is canceled mid-operation?

2. **Run tests** — confirm they FAIL (red phase)

3. **Implement code** to make tests pass (green phase)

4. **Refactor** — check for:
   - Nested conditions (max 2 levels, use early return / continue / extract helper)
   - Magic strings (use typed constants)
   - Inconsistent trim-before-length (trim THEN check length)
   - Import grouping (stdlib | external+shared | internal)

5. **Run tests** — confirm they PASS

---

## Phase 4: Verify (addresses: missed conventions)

Run all checks (adapt commands to your language/toolchain):

```bash
# Build
your-build-command ./...

# Lint
your-lint-command ./...

# Test
your-test-command ./...
```

**IMPORTANT**: Run EVERY checklist item on ALL changed files (not just new files). Do not skip.

### Universal Checks

- [ ] Unicode-aware string length (not byte length) for all character length checks
- [ ] String truncation must be character-aware (not byte slice)
- [ ] Proper type casting for complex DB column types (JSON, arrays, etc.)
- [ ] Package/module comments present
- [ ] Shared imports in correct grouping — check ALL changed files
- [ ] No variable shadowing in tests
- [ ] No duplicate validation: one layer owns trim + validate, others pass raw values
- [ ] All mocks up-to-date with interfaces
- [ ] Constructors return interfaces (not concrete types)
- [ ] Error wrapping includes context (not bare nil checks)
- [ ] Spell check: add any new terms to project dictionary (keep sorted)
- [ ] No magic strings (use constants for HTTP methods, MIME types, domain values)
- [ ] No duplicated helpers — search existing packages before writing
- [ ] After extracting shared helper: grep ALL call sites and migrate
- [ ] Sanitize user input in file/storage paths (reject path traversal)
- [ ] Input length caps for external service limits
- [ ] Function length <= 50 lines — check ALL changed files
- [ ] File size <= 400 lines — check ALL changed files, create issues for pre-existing
- [ ] Environment variables added to ALL config files
- [ ] Domain values cross-checked against live docs + external API docs
- [ ] DB: UPDATE checks rows affected (returns error, not silent success)
- [ ] DB: SELECT handles "not found" (return empty/nil, not 500 error)
- [ ] Config: environment-specific values have empty defaults (not localhost)
- [ ] Config: validate non-empty before wiring adapter (skip with warning if empty)
- [ ] Infrastructure: new clients return errors (not crash the process)
- [ ] Naming: new packages match sibling directory naming (no redundant suffixes)
- [ ] .gitignore: no accidental data files

### Naming Conventions

- [ ] Acronyms follow your org's convention (all-caps vs CamelCase)
- [ ] Verb-first function names (`FindDeepest` not `DeepestFind`)
- [ ] Function names <= 20 chars, <= 5 words
- [ ] Filenames follow project convention (kebab-case, snake_case, etc.)
- [ ] Import/package aliases follow length limits
- [ ] Regular words not treated as acronyms

### Wiring (critical — bugs caught in retrospectives)

- [ ] New handlers wired in BOTH router AND server initialization
- [ ] New handlers passed through dependency injection chain
- [ ] New routes verified: start server locally, hit endpoint, confirm not 404

### Choreography (prevents scattered state transitions)

- [ ] Terminal state transitions use centralized methods, not scattered direct calls
- [ ] Multi-step operations centralized in one method — grep for scattered calls

---

## Phase 5: Self-Review Loop (skip with --skip-review)

Iterative review-fix cycle until clean (max 3 iterations):

1. **Run simplification pass** on all changed files — fix any findings
2. **Run internal review** (same analysis as your review command but WITHOUT posting comments):
   - Convention compliance, naming limits, nesting depth
   - Validation completeness, error handling, edge cases
   - Type safety, constructor patterns, typed enums vs strings
   - Code reuse, duplication, efficiency
3. **Fix findings >= 75 confidence** immediately
4. **Re-run build + test** to verify fixes
5. **Repeat** steps 2-4 until no new actionable findings (or max 3 iterations)

After loop completes: amend commit, push once.

---

## Phase 6: Ship

1. **Squash** all commits to a single commit with descriptive message
2. **Push** to origin
3. **Create or update PR** with comprehensive description:
   - What changed (with API mapping rationale)
   - Architecture decisions
   - Checklist (build/lint/test/mocks/review)
4. **Update tech design docs** if schemas changed
5. **Validate PR description** — cross-check tables/lists against actual code (types, test counts, validation rules)
6. **Validate PR comments** — fetch and reply to any automated review comments

---

## Quality Checklist (verify before marking complete)

- [ ] Client interaction pattern confirmed (not assumed)
- [ ] External API schemas fetched and cross-referenced
- [ ] Existing repo patterns followed (not reinvented)
- [ ] All related types designed together (consistent patterns)
- [ ] Tests written BEFORE implementation (standard mocking, not stubs)
- [ ] Edge cases tested (null, empty, max+1, multi-byte text, path traversal, Unicode truncation)
- [ ] No nesting > 2 levels
- [ ] No magic strings
- [ ] Unicode-aware string length and truncation
- [ ] Proper DB type casting
- [ ] Import grouping correct (ALL changed files)
- [ ] Constructors return interfaces
- [ ] Shared helpers migrated to ALL call sites
- [ ] Self-review loop passed (0 findings >= 75)
- [ ] Single squashed commit
- [ ] PR description cross-checked against code
