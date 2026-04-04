# CLAUDE.md Template for gRPC Mono-Repo

> **Template** | gRPC Mono-Repo | Go + Nuxt | GCP Cloud Run

This is a template for creating CLAUDE.md files in gRPC mono-repo projects. Customize sections based on your project needs.

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

---

## BE (Backend)

### Code Style

1. **Naming and spelling**:
   - Strictly follow Go naming conventions: https://go.dev/wiki/CodeReviewComments#initialisms
   - US spelling (e.g., `color` not `colour`, `initialize` not `initialise`)
   - Acronyms: Use consistent casing (`ID`, `HTTP`, `URL` - all caps or all lower)

2. **Prefer raw SQL** instead of ORM:
   - Use `pgx` for PostgreSQL driver
   - Use `squirrel` for query building
   - Complex queries: Write raw SQL with named parameters

3. **Cases**:

   | Type                 | Convention | Example                           |
   | -------------------- | ---------- | --------------------------------- |
   | File names           | snake_case | `user_repository.go`              |
   | Package names        | lowercase  | `userservice`                     |
   | Constants            | MixedCaps  | `MaxRetryCount`, `DefaultTimeout` |
   | Exported functions   | PascalCase | `GetUserByID`                     |
   | Unexported functions | camelCase  | `validateInput`                   |

4. **Error handling**:
   - Always wrap errors with context: `fmt.Errorf("failed to get user: %w", err)`
   - Use appropriate gRPC status codes:

     | Situation         | Code                     |
     | ----------------- | ------------------------ |
     | Invalid input     | `codes.InvalidArgument`  |
     | Not found         | `codes.NotFound`         |
     | Already exists    | `codes.AlreadyExists`    |
     | Permission denied | `codes.PermissionDenied` |
     | Internal error    | `codes.Internal`         |

5. **Logging**:
   - Use structured logging (your-core-lib logger)
   - Always include `request_id` in logs
   - Log levels: `Debug` (development), `Info` (normal ops), `Warn` (recoverable), `Error` (failures)

### Architecture

```
Client → API Gateway → BFF → API Service → Database
                         ↓
                    [Pub/Sub]
                         ↓
                  Process Service
```

1. **Request flow**: Client → GW → BFF → API/Process services
2. **CQRS pattern**:
   - Queries: Direct gRPC calls to API service
   - Commands: Pub/Sub events for async processing → Process service
3. **Deployment** (GCP):
   - Cloud Run with service account impersonation
   - Cloud SQL Proxy as sidecar (PostgreSQL)
   - Secret Manager for credentials (DB passwords, API keys)
4. **Testing exclusions**: Defined in `sonar-project.properties`

### Hexagonal Architecture Pattern

```
cmd/server/main.go              # Entry point
internal/
├── handler/                    # gRPC handlers (input adapter)
├── core/
│   ├── port/                   # Interfaces (ports)
│   │   ├── adapter.go          # External service interfaces
│   │   ├── repository.go       # Data access interfaces
│   │   ├── publisher.go        # Event publishing interfaces
│   │   └── service.go          # Business logic interface
│   ├── service/                # Business logic implementation
│   └── mocks/                  # Generated mocks (mockery)
├── adapter/                    # External service clients (output adapter)
├── repositories/               # Data access layer (output adapter)
│   ├── postgres/
│   ├── redis/
│   └── misc/
├── publisher/                  # Pub/Sub publishers
└── server/                     # Server initialization
```

### Library Management

1. **your-core-lib** (shared library):
   - ✅ **Put in core-lib**:
     - Middleware (logging, tracing, auth)
     - Common utilities (string, time, validation)
     - Infrastructure clients (Redis, Pub/Sub wrappers)
     - gRPC interceptors
   - ❌ **Don't put**:
     - Business logic
     - Domain-specific code
     - Service-specific handlers
   - 🤖 **AI suggestion rule**: If code is used by 3+ services → consider moving to core-lib

2. **yim-proto-hub**: Git submodule for protobuf definitions
   - Run `git submodule update --init --recursive` after clone
   - Generate with `make buf`

3. **shared/** folder: Independent Go module within mono-repo
   - `shared/constant/` - Application-wide constants
   - `shared/enum/` - Enumeration definitions
   - `shared/gen/` - Generated protobuf code
   - `shared/infrastructure/` - Infrastructure utilities
   - `shared/util/` - General utilities

---

## FE (Frontend)

### Code Style

1. **JSON payload**: snake_case for all request/response fields

   ```typescript
   // ✅ Correct
   { user_name: "john", created_at: "2025-01-01" }

   // ❌ Incorrect
   { userName: "john", createdAt: "2025-01-01" }
   ```

2. **TypeScript naming**:
   | Type | Convention | Example |
   |------|------------|---------|
   | Variables | camelCase | `userName`, `isLoading` |
   | Functions | camelCase | `fetchUser`, `handleSubmit` |
   | Components | PascalCase | `UserProfile.vue`, `LoginForm.vue` |
   | Constants | SCREAMING_SNAKE | `API_BASE_URL`, `MAX_RETRY` |
   | Types/Interfaces | PascalCase | `UserResponse`, `LoginRequest` |

3. **File naming**:
   - Components: PascalCase (`UserCard.vue`)
   - Composables: camelCase with `use` prefix (`useAuth.ts`)
   - Utils: camelCase (`formatDate.ts`)

### Architecture

1. **Framework**: Nuxt 3 with TypeScript
2. **State management**: Pinia (only when needed for shared state)
3. **API integration**:
   - Use `useFetch` or `$fetch` for API calls
   - Server routes (`/server/api/`) for BFF communication
4. **Composables**: Reusable logic in `composables/` directory

### Project Structure

```
components/           # Vue components
├── common/           # Shared components
├── forms/            # Form components
└── [feature]/        # Feature-specific components
composables/          # Reusable composition functions
├── useAuth.ts
├── useFetch.ts
└── useToast.ts
pages/                # Route pages (file-based routing)
server/
├── api/              # API routes (BFF layer)
└── middleware/       # Server middleware
stores/               # Pinia stores
types/                # TypeScript type definitions
utils/                # Utility functions
```

---

## Testing

### Backend

| Type              | Location                | Command                 | Coverage Target        |
| ----------------- | ----------------------- | ----------------------- | ---------------------- |
| Unit tests        | `*_test.go`             | `make unit-test`        | 80%+ for service layer |
| Integration tests | `*_integration_test.go` | `make integration-test` | Critical paths         |
| Mocks             | `core/mocks/`           | `make mock-api`         | Auto-generated         |

**Unit test pattern**:

```go
func TestServiceName_MethodName_Scenario(t *testing.T) {
    // Arrange
    mockRepo := mocks.NewRepository(t)
    mockRepo.On("GetByID", mock.Anything, "123").Return(entity, nil)

    svc := NewService(mockRepo)

    // Act
    result, err := svc.GetByID(ctx, "123")

    // Assert
    assert.NoError(t, err)
    assert.Equal(t, expected, result)
    mockRepo.AssertExpectations(t)
}
```

### Frontend

| Type            | Tool       | Location    |
| --------------- | ---------- | ----------- |
| Component tests | Vitest     | `*.spec.ts` |
| E2E tests       | Playwright | `e2e/`      |

---

## Git Conventions

### Branch Naming

```
feature/PROJ-1234-short-description
fix/PROJ-1234-short-description
hotfix/PROJ-1234-short-description
refactor/PROJ-1234-short-description
docs/PROJ-1234-short-description
```

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(api): add user authentication endpoint
fix(process): resolve race condition in event handler
docs(readme): update setup instructions
refactor(shared): extract common validation logic
test(api): add unit tests for user service
chore(ci): update GitHub Actions workflow
```

### Pull Request

1. Must pass all CI checks (lint, test, build)
2. Requires at least 1 approval
3. Use PR template with:
   - Summary of changes
   - Test plan
   - Related JIRA ticket

---

## Code Review Focus

### Security

- [ ] No hardcoded secrets or credentials
- [ ] Input validation on all endpoints
- [ ] SQL injection prevention (parameterized queries)
- [ ] Proper authentication/authorization checks

### Performance

- [ ] No N+1 query problems
- [ ] Appropriate use of indexes
- [ ] Pagination for list endpoints
- [ ] Caching where appropriate (Redis)

### Error Handling

- [ ] Errors are wrapped with context
- [ ] Appropriate gRPC status codes
- [ ] Errors are logged with request_id
- [ ] No sensitive data in error messages

### Code Quality

- [ ] Functions are single-purpose
- [ ] No duplicate code (DRY)
- [ ] Interfaces used for dependencies (testability)
- [ ] Clear naming (self-documenting code)

---

## Environment Configuration

| Environment | Config File         | GCP Project         | Branch    |
| ----------- | ------------------- | ------------------- | --------- |
| Local       | `configs/local.env` | -                   | -         |
| Development | `configs/dev.json`  | `your-project-dev`  | `develop` |
| SIT         | `configs/sit.json`  | `your-project-sit`  | `sit`     |
| UAT         | `configs/uat.json`  | `your-project-uat`  | `release` |
| Production  | `configs/prod.json` | `your-project-prod` | `main`    |

---

## Troubleshooting

### Proto generation fails

```bash
git submodule update --init --recursive
make buf
```

### Module not found

```bash
go work sync
make tidy
```

### Mock generation fails

```bash
go install github.com/vektra/mockery/v2@latest
make mock-api
```

### Local DB connection

```bash
# Start Cloud SQL Proxy
cloud_sql_proxy -instances=PROJECT:REGION:INSTANCE=tcp:5432
```

---

## Related Documents

- [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments)
- [Effective Go](https://go.dev/doc/effective_go)
- [gRPC Status Codes](https://grpc.io/docs/guides/status-codes/)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

_Template version: 1.0_
_Created: December 2025_
_For: gRPC Mono-Repo Projects_
