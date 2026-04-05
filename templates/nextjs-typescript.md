# CLAUDE.md Template for Next.js + TypeScript

> Template | Next.js 15 | React 19 | TypeScript | Tailwind CSS | shadcn/ui

---

## Quick Commands

```bash
pnpm dev              # Dev server (http://localhost:3000)
pnpm build            # Production build
pnpm lint             # ESLint
pnpm test             # Tests (Vitest)
npx tsc --noEmit      # Type check
```

**After every change, run in this order:**
1. `npx tsc --noEmit` — fix type errors
2. `pnpm test` — fix failing tests
3. `pnpm lint` — fix lint errors
4. `pnpm build` — confirm it builds

---

## Code Style

- **Components**: Server Components by default, `"use client"` only when needed
- **Imports**: Group: 1) React/Next, 2) third-party, 3) local (`@/*`)
- **Types**: No `any` — use `unknown` and narrow. All props typed with interfaces.
- **Naming**: PascalCase components, camelCase functions, SCREAMING_SNAKE constants
- **Events**: `handle` prefix for handlers (`handleSubmit`, `handleClick`)
- **Early returns**: Prefer guard clauses over nested conditionals
- **Comments**: Explain *why*, never *what*

---

## Architecture

```
app/                    # App Router (file-based routing)
├── (auth)/             # Route groups
├── api/                # API routes
├── layout.tsx          # Root layout
└── page.tsx            # Home page
components/
├── ui/                 # shadcn/ui components (generated)
└── [feature]/          # Feature-specific components
lib/                    # Utilities, configs, types
hooks/                  # Custom hooks (use* prefix)
```

**Colocation rule**: Components used by a single page live next to that page. Shared across 2+ pages → `components/`.

**Data fetching**: Server Components fetch directly (no `useEffect`). Client Components use React Query or SWR.

---

## Testing

| Type      | Tool                      | Location      | Command     |
| --------- | ------------------------- | ------------- | ----------- |
| Unit      | Vitest + Testing Library  | `*.test.tsx`  | `pnpm test` |
| E2E       | Playwright                | `e2e/`        | `pnpm e2e`  |

---

## Git Conventions

**Branches**: `feature/PROJ-123-description`, `fix/PROJ-123-description`

**Commits**: [Conventional Commits](https://www.conventionalcommits.org/) — `feat(ui):`, `fix(api):`, `test:`, `chore:`

---

_Template version: 1.0 | Created: April 2026_
