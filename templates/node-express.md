# CLAUDE.md Template for Node.js + Express Monorepo

> Template | Node.js 22 | Express | TypeScript | pnpm Workspace

---

## Quick Commands

```bash
pnpm install              # Install all packages
pnpm dev                  # Dev server (all packages)
pnpm build                # Build all packages
pnpm test                 # Run tests
pnpm lint                 # ESLint
pnpm typecheck            # TypeScript check (all packages)
```

**After every change, run in this order:**
1. `pnpm typecheck` — fix type errors
2. `pnpm test` — fix failing tests
3. `pnpm lint` — fix lint errors
4. `pnpm build` — confirm it builds

---

## Code Style

- **Modules**: ESM (`import/export`), never CommonJS (`require`)
- **Types**: Strict TypeScript — no `any`, all functions typed
- **Naming**: camelCase functions/variables, PascalCase classes/interfaces, SCREAMING_SNAKE constants
- **Errors**: Custom error classes extending `Error`. Always include HTTP status codes.
- **Logging**: Structured logging (pino/winston) — never `console.log` in production
- **Async**: Always `async/await`, never raw `.then()` chains

---

## Architecture

```
packages/
├── api/                   # Express API server
│   ├── src/
│   │   ├── routes/        # Route handlers
│   │   ├── middleware/     # Auth, validation, error handling
│   │   ├── services/      # Business logic
│   │   ├── repositories/  # Data access
│   │   └── app.ts         # Express app setup
│   └── tests/
├── shared/                # Shared types, utils, constants
│   └── src/
├── worker/                # Background job processor (optional)
│   └── src/
└── config/                # Shared config (ESLint, TSConfig, Vitest)
pnpm-workspace.yaml        # Workspace definition
```

**Package references**: Use `workspace:*` in `package.json` for inter-package deps.

**Database**: Prisma ORM with migrations. Raw queries via `$queryRaw` for complex cases.

---

## Testing

| Type        | Tool    | Location      | Command              |
| ----------- | ------- | ------------- | -------------------- |
| Unit        | Vitest  | `*.test.ts`   | `pnpm test`          |
| Integration | Vitest  | `*.int.test.ts` | `pnpm test:integration` |
| E2E         | Supertest | `e2e/`      | `pnpm test:e2e`      |

---

## Git Conventions

**Branches**: `feature/PROJ-123-description`, `fix/PROJ-123-description`

**Commits**: [Conventional Commits](https://www.conventionalcommits.org/) with scope: `feat(api):`, `fix(shared):`, `chore(config):`

**Changesets**: Run `pnpm changeset` before merging to track version bumps.

---

_Template version: 1.0 | Created: April 2026_
