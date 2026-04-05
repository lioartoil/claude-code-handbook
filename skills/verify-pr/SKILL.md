---
name: verify-pr
description: Run the full PR verification checklist — code organization, build, test, mocks, squash, push, update PR description, and validate all review comments.
context: fork
allowed-tools: Bash, Read, Edit, Glob, Grep, Agent, Write
argument-hint: '[PR number]'
---

# Verify PR

## Confirmation

Before proceeding, confirm with the user:

- This will run the full verification checklist (build, test, mocks, lint)
- It may squash commits, force-push, and update the PR description on GitHub
- All review comments will be validated and marked as resolved

Ask using AskUserQuestion. If the user declines, stop immediately.

---

Run the complete verification checklist for the current branch's PR.

## Input

`$ARGUMENTS` — optional PR number (e.g., `101`). If omitted, detect from current branch.

## Repo Detection

Detect the project type by checking files in the repo root:

| Signal                  | Type            | Stack                             |
| ----------------------- | --------------- | --------------------------------- |
| `go.mod` exists         | **Go Service**  | Go, gRPC, Cloud Run               |
| `nuxt.config.ts` exists | **Nuxt Portal** | Nuxt 4, Vue 3, TypeScript, Vitest |

Run the checklist matching the detected type. If both exist, prefer Go (monorepo with frontend subfolder).

---

## Checklist — Go Service

### 1. Code Organization

- Read all changed files (`git diff --name-only develop...HEAD`)
- Check: types/functions ordered logically, no noise comments
- Check: import grouping (stdlib | external+shared | internal)
- Fix any issues found

### 1.5. Simplify

- Invoke `/simplify` on all changed files
- Fix findings rated as real issues (skip false positives)
- **CRITICAL (Session 100 retro)**: Do NOT remove or modify router/handler wiring.
  Before simplifying `router.go` or `server.go`, save the current function signatures
  and route registrations. After simplify, verify all handler params and routes are
  still present. If any were removed, restore them immediately.
- **CRITICAL**: Do NOT remove imports used by handler wiring. The simplify pass may
  flag an import as "unused" if the handler was just added. Verify by building
  (`go build`), not by static analysis alone.
- **Shotgun Surgery check**: Any new `UpdateCampaignStatus(StatusEnded/StatusFailed)` MUST go
  through `completeCampaign`. Direct calls = Shotgun Surgery risk. Verify with:
  `grep -rn "UpdateCampaignStatus.*StatusEnded\|UpdateCampaignStatus.*StatusFailed" campaign-*.go | grep -v completeCampaign | grep -v _test`

### 2. Build & Test

```bash
go build ./api/... ./shared/... ./broker/... ./engagement/...
go vet ./api/... ./shared/...
go test ./api/... ./shared/...
```

### 2.5. E2E Test (Best-Effort)

- Identify what the PR changes (new endpoints, external integrations, storage operations)
- If the changes involve external services (GCS, LINE API, Pub/Sub, etc.):
  1. Search for SA key files in the current repo and sibling repos (check file size > 0)
  2. Write a standalone Go test or script that exercises the real integration
  3. Run it and report results
- If E2E is not feasible (missing credentials, no external deps), report as SKIPPED with reason
- Never block the PR on E2E failure — report as advisory

### 3. Generated Files

- Check mocks are in sync with port interfaces (no stale methods)
- Check if swagger/docs need regeneration

### 4. Git Operations

- Count commits (`git log --oneline develop..HEAD`)
- If multiple commits: squash to single commit
- Push to origin (`git push --force-with-lease`)
- Update PR description if needed (`gh pr edit`)

### 5. Review Comments

- Fetch all PR comments (`gh api repos/.../pulls/{PR}/comments`)
- For each unreplied comment: evaluate validity, fix if needed, reply
- Report: X/Y comments resolved

### 5.5. Self-Review Loop (until clean)

- Run headless review analysis on all changed files (same logic as `/review-and-comment` but without posting comments)
- For each finding with confidence >= 75: fix the code immediately
- For findings below threshold: skip (no comment needed)
- After fixing: re-run steps 2 (Build & Test) to verify fixes don't break anything
- Repeat review → fix → build cycle until no new actionable findings (max 3 iterations)
- After loop completes: amend commit + push once
- Report: N iterations, M total fixes applied

---

## Checklist — Nuxt Portal

### 1. Code Organization

- Read all changed files (`git diff --name-only develop...HEAD`)
- Check: `<script setup lang="ts">` first, then `<template>`, then `<style>` in Vue SFCs
- Check: imports grouped logically (vue | nuxt/composables | external | internal)
- Check: composable naming uses `use*` prefix
- Check: no hardcoded paths (use route constants from `app/constants/routes.ts`)
- Fix any issues found

### 1.5. Simplify

- Invoke `/simplify` on all changed files
- Fix findings rated as real issues (skip false positives)
- **CRITICAL**: Do NOT remove or simplify `useCustomFetch` wrappers or `defineProps`/`defineEmits` type annotations — these are required patterns

### 2. Lint, Type Check & Test

```bash
pnpm lint
pnpm typecheck
pnpm test:run
```

- If lint issues found: run `pnpm lint:fix` then re-check
- If type errors found: fix them
- If test failures found: investigate and fix

### 2.5. Build Check (Best-Effort)

```bash
pnpm build:dev
```

- Report as advisory — build failures may be due to env config, not code issues

### 3. Env & Config

- If new env vars were added: verify they exist in ALL `.env.*` files (dev, sit, uat, prod)
- If `nuxt.config.ts` was changed: verify `runtimeConfig` entries match env var names
- Check no secrets or API keys in committed `.env.*` files

### 4. Git Operations

- Count commits (`git log --oneline develop..HEAD`)
- If multiple commits: squash to single commit
- Push to origin (`git push --force-with-lease`)
- Update PR description if needed (`gh pr edit`)

### 5. Review Comments

- Fetch all PR comments (`gh api repos/.../pulls/{PR}/comments`)
- For each unreplied comment: evaluate validity, fix if needed, reply
- Report: X/Y comments resolved

### 5.5. Self-Review Loop (until clean)

- Run review analysis on all changed files
- For each finding with confidence >= 75: fix immediately
- After fixing: re-run lint + typecheck + test to verify
- Repeat until clean (max 3 iterations)
- After loop: amend commit + push once
- Report: N iterations, M total fixes applied

---

## Output

Report each check with a status and details for failures:

**Go Service:**

```
Code Organization: [status] [details]
Simplify:          [status] [N issues fixed or "clean"]
Build:             [status]
Vet:               [status]
Test:              [status] [X passed, Y packages]
E2E Test:          [status] [details or SKIPPED reason]
Mocks:             [status]
Commits:           [status] [single commit: hash]
Push:              [status]
PR Description:    [status]
Review Comments:   [status] [X/Y resolved]
Self-Review Loop:  [status] [N iterations, M fixes or "clean on first pass"]
```

**Nuxt Portal:**

```
Code Organization: [status] [details]
Simplify:          [status] [N issues fixed or "clean"]
Lint:              [status] [N issues or "clean"]
Type Check:        [status]
Test:              [status] [X passed, Y failed]
Build:             [status] [or SKIPPED]
Env Config:        [status] [N vars verified across M env files]
Commits:           [status] [single commit: hash]
Push:              [status]
PR Description:    [status]
Review Comments:   [status] [X/Y resolved]
Self-Review Loop:  [status] [N iterations, M fixes or "clean on first pass"]
```

### Reminder: /e2e-test

After the report, if the PR changes trigger files, print:

**Go Service** trigger files:

- `**/server/server.go`, `**/router/router.go`, `**/adapter/handler/**`, `**/property/property.go`, `**/configs/*.env`

> **Tip:** This PR touches server wiring / handlers / router. Consider running `/e2e-test` to validate the full running service locally.

**Nuxt Portal** trigger files:

- `app/composables/useCustomFetch.ts`, `app/composables/useUploadFile.ts`, `nuxt.config.ts`, `.env.*`, `app/services/**`

> **Tip:** This PR touches API integration / config. Consider running `/e2e-test portal` to validate the dev server locally.
