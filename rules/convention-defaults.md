# Convention Defaults (Shared Fallback)

> Applies when a repo has no CONVENTIONS.md or CLAUDE.md with convention sections.
> These are minimum standards observed across all repos in your organization.
> Referenced by HRP Phase 4.5 Pass 1 as the final fallback in the convention chain.

## Go (Backend / BFF)

- **Function length**: max 50 lines per function body (count actual lines, do not estimate)
- **File size**: max 400 lines (warning at 300)
- **Package name**: max 10 characters, lowercase, no underscores
- **Package alias**: max 10 characters when importing
- **Import grouping**: stdlib | external | internal (separated by blank lines)
- **Error wrapping**: use `fmt.Errorf("context: %w", err)` — never discard errors silently
- **Magic values**: extract string/number literals to named constants
- **Naming**: exported = PascalCase, unexported = camelCase; max 5 words / 20 chars
- **Interface naming**: `Reader`, `Writer`, `Handler` — no `I` prefix
- **Test co-location**: `_test.go` files in same package
- **Cyclomatic complexity**: max 15 per function
- **Nesting depth**: max 3 levels

## TypeScript / Vue (Frontend)

- **Component structure**: `<script setup lang="ts">` first, then `<template>`, then `<style>`
- **Composable naming**: `use*` prefix (e.g., `useAuth`, `useFetch`)
- **Route strings**: use route constants, never hardcode paths
- **Color values**: use design tokens, no arbitrary hex/rgb
- **i18n**: no hardcoded user-facing strings in templates
- **Reactivity cleanup**: `onUnmounted` for listeners, intervals, subscriptions
- **Props**: define with `defineProps<T>()` — always typed
- **Emits**: define with `defineEmits<T>()` — always typed

## All Languages

- **File naming**: kebab-case for files, PascalCase for components
- **No console.log / fmt.Println**: in production code (use structured logging)
- **No commented-out code**: remove dead code, use version control
- **TODO format**: `// TODO(username): description — TICKET-NNN`
- **No hardcoded URLs**: use environment variables or config files
- **No secrets in code**: use environment variables or secret managers
