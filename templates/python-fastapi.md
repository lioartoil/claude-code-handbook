# CLAUDE.md Template for Python + FastAPI

> Template | Python 3.12+ | FastAPI | uv | ruff | pytest

---

## Quick Commands

```bash
uv sync                    # Install dependencies
uv run fastapi dev         # Dev server (http://localhost:8000)
uv run pytest              # Run tests
uv run pytest -k "test_auth"  # Single test
uv run ruff check .        # Lint
uv run ruff format .       # Format
uv run pyright             # Type check
```

**After every change, run in this order:**
1. `uv run pyright` — fix type errors
2. `uv run pytest` — fix failing tests
3. `uv run ruff check . --fix` — fix lint errors

---

## Code Style

- **Type hints**: Mandatory on all functions (Python 3.12+ syntax, PEP 695)
- **Imports**: Group: 1) stdlib, 2) third-party, 3) local. Managed by ruff.
- **Naming**: snake_case functions/variables, PascalCase classes, SCREAMING_SNAKE constants
- **Errors**: Raise specific exceptions with context, never bare `except:`
- **Logging**: Use `structlog` or `logging` — never `print()` in production
- **JSON**: snake_case for all request/response fields

---

## Architecture

```
src/
├── main.py                # FastAPI app entry point
├── config.py              # Settings (pydantic-settings)
├── routers/               # API route handlers
│   ├── auth.py
│   └── users.py
├── models/                # Pydantic models (request/response)
├── services/              # Business logic
├── repositories/          # Data access layer
├── dependencies.py        # FastAPI dependency injection
└── exceptions.py          # Custom exception classes
tests/
├── conftest.py            # Fixtures
├── test_routers/
└── test_services/
alembic/                   # Database migrations
```

**Dependency injection**: Use FastAPI's `Depends()` for services and repositories.

**Database**: SQLAlchemy 2.0 async with Alembic migrations. Raw SQL via `text()` for complex queries.

---

## Testing

| Type        | Command                   | Coverage    |
| ----------- | ------------------------- | ----------- |
| Unit        | `uv run pytest`           | 80%+ target |
| Integration | `uv run pytest -m integration` | Critical paths |

**Fixtures**: Use `conftest.py` with `httpx.AsyncClient` for API tests.

---

## Git Conventions

**Branches**: `feature/PROJ-123-description`, `fix/PROJ-123-description`

**Commits**: [Conventional Commits](https://www.conventionalcommits.org/) — `feat(api):`, `fix(auth):`, `test:`, `chore:`

---

_Template version: 1.0 | Created: April 2026_
