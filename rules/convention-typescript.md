---
paths:
  - '**/*.ts'
  - '**/*.tsx'
  - '**/*.vue'
---

# TypeScript / Vue Conventions (Frontend)

- **Component structure**: `<script setup lang="ts">` first, then `<template>`, then `<style>`
- **Composable naming**: `use*` prefix (e.g., `useAuth`, `useFetch`)
- **Route strings**: use route constants, never hardcode paths
- **Color values**: use design tokens, no arbitrary hex/rgb
- **i18n**: no hardcoded user-facing strings in templates
- **Reactivity cleanup**: `onUnmounted` for listeners, intervals, subscriptions
- **Props**: define with `defineProps<T>()` — always typed
- **Emits**: define with `defineEmits<T>()` — always typed
