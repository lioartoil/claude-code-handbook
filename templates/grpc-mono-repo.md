# CLAUDE.md Template for gRPC Mono-Repo

> Template | gRPC Mono-Repo | Go + Nuxt | GCP Cloud Run

---

## Quick Commands

```bash
# Protobuf & Mocks
make buf                 # Generate protobuf from yim-proto-hub
make mock-api            # Generate mocks for API service
make mock-process        # Generate mocks for Process service

# Development
make tidy                # go mod tidy all modules
make unit-test           # Run all unit tests
make integration-test    # Run integration tests (requires DB)
make golangci-lint       # Run linter

# Local Run
cd api && go run cmd/server/main.go      # Run API service
cd process && go run cmd/server/main.go  # Run Process service
```

**After every change, run in this order:**
1. `make golangci-lint` — fix lint errors
2. `make unit-test` — fix failing tests
3. `make integration-test` — verify DB integration (if applicable)

---

## BE (Backend)

### Code Style

- **Naming**: Follow [Go naming conventions](https://go.dev/wiki/CodeReviewComments#initialisms). US spelling. File names: snake_case. Packages: lowercase, max 10 chars.
- **SQL**: Prefer raw SQL with `pgx` + `squirrel`. No ORM.
- **Errors**: Always wrap with context: `fmt.Errorf("failed to get user: %w", err)`. Use gRPC status codes (`codes.InvalidArgument`, `codes.NotFound`, `codes.Internal`).
- **Logging**: Structured logging (your-core-lib). Always include `request_id`.

### Architecture

```
Client → API Gateway → BFF → API Service → Database
                         ↓
                    [Pub/Sub]
                         ↓
                  Process Service
```

- **CQRS**: Queries via direct gRPC → API service. Commands via Pub/Sub → Process service.
- **Deployment**: Cloud Run + Cloud SQL Proxy sidecar + Secret Manager.
- **Proto**: Git submodule (`yim-proto-hub`). Run `git submodule update --init --recursive` after clone.

### Hexagonal Architecture

```
cmd/server/main.go              # Entry point
internal/
├── handler/                    # gRPC handlers (input adapter)
├── core/
│   ├── port/                   # Interfaces (ports)
│   ├── service/                # Business logic
│   └── mocks/                  # Generated mocks (mockery)
├── adapter/                    # External service clients (output adapter)
├── repositories/postgres/      # Data access (output adapter)
└── publisher/                  # Pub/Sub publishers
shared/                         # Constants, enums, generated proto, utils
```

### Library Management

- **your-core-lib**: Middleware, utilities, infrastructure clients, gRPC interceptors. Never business logic.
- **shared/**: Independent Go module — constants, enums, generated proto, utilities.
- **Rule**: Code used by 3+ services → consider moving to core-lib.

---

## FE (Frontend)

- **Framework**: Nuxt 3 + TypeScript + Pinia
- **JSON payloads**: snake_case for all request/response fields
- **Naming**: PascalCase components, camelCase composables (`use*` prefix), camelCase utils
- **API calls**: `useFetch` or `$fetch`. Server routes (`/server/api/`) for BFF.

---

## Testing

| Type        | Backend                  | Frontend           |
| ----------- | ------------------------ | ------------------ |
| Unit        | `make unit-test`         | Vitest (`*.spec.ts`) |
| Integration | `make integration-test`  | —                  |
| E2E         | —                        | Playwright (`e2e/`) |
| Mocks       | `make mock-api` (mockery)| —                  |

**Test naming**: `TestServiceName_MethodName_Scenario`. Pattern: Arrange → Act → Assert.

---

## Git Conventions

**Branches**: `feature/PROJ-1234-description`, `fix/PROJ-1234-description`

**Commits**: [Conventional Commits](https://www.conventionalcommits.org/) — `feat(api):`, `fix(process):`, `test:`, `chore(ci):`

**PRs**: Must pass CI (lint, test, build). Requires 1 approval. Include summary, test plan, JIRA ticket.

---

## Environment Configuration

| Environment | Config              | GCP Project         | Branch    |
| ----------- | ------------------- | ------------------- | --------- |
| Local       | `configs/local.env` | —                   | —         |
| Development | `configs/dev.json`  | `your-project-dev`  | `develop` |
| SIT         | `configs/sit.json`  | `your-project-sit`  | `sit`     |
| UAT         | `configs/uat.json`  | `your-project-uat`  | `release` |
| Production  | `configs/prod.json` | `your-project-prod` | `main`    |

---

_Template version: 2.0 | Updated: April 2026_
