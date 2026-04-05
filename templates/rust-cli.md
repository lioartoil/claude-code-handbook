# CLAUDE.md Template for Rust CLI Project

> Template | Rust | Cargo | CLI Application

---

## Quick Commands

```bash
cargo build                          # Debug build
cargo build --release                # Optimized build
cargo test                           # Run all tests
cargo test test_name                 # Single test
cargo clippy -- -D warnings         # Lint (treat warnings as errors)
cargo fmt --check                    # Format check
cargo fmt                            # Auto-format
```

**After every change, run in this order:**
1. `cargo test` — fix failing tests
2. `cargo build` — confirm it compiles (no warnings)
3. `cargo clippy -- -D warnings` — fix lint issues
4. `cargo fmt --check` — verify formatting

---

## Code Style

- **No `unwrap()`**: Use `expect("context")` or propagate with `?`
- **Error handling**: `thiserror` for library errors, `anyhow` for application errors
- **Naming**: snake_case functions/variables, PascalCase types/traits, SCREAMING_SNAKE constants
- **Strings**: Prefer `&str` over `String` in function parameters. Use `Cow<'_, str>` for conditional ownership.
- **Iterators**: Prefer iterator chains over explicit `for` loops
- **Clone**: Minimize `.clone()` — borrow where possible
- **Dependencies**: Declare in workspace `Cargo.toml` only (if workspace)

---

## Architecture

```
src/
├── main.rs                # Entry point, CLI argument parsing (clap)
├── cli.rs                 # CLI argument definitions
├── commands/              # Subcommand implementations
│   ├── mod.rs
│   ├── init.rs
│   └── run.rs
├── config.rs              # Configuration loading (serde + toml/yaml)
├── error.rs               # Custom error types (thiserror)
└── lib.rs                 # Library root (for reuse and testing)
tests/
├── integration_test.rs    # Integration tests
└── fixtures/              # Test data files
```

**CLI parsing**: Use `clap` with derive macros. Each subcommand is a separate module.

**Configuration**: Load from file → env vars → CLI args (in priority order). Use `serde` for deserialization.

---

## Testing

| Type        | Location                 | Command                |
| ----------- | ------------------------ | ---------------------- |
| Unit        | Inline `#[cfg(test)]`    | `cargo test`           |
| Integration | `tests/`                 | `cargo test`           |
| Doc tests   | `///` comments           | `cargo test --doc`     |

**Test naming**: `test_function_name_scenario` (e.g., `test_parse_config_missing_file`)

---

## Git Conventions

**Branches**: `feature/PROJ-123-description`, `fix/PROJ-123-description`

**Commits**: [Conventional Commits](https://www.conventionalcommits.org/) — `feat(cli):`, `fix(config):`, `test:`, `chore:`

---

_Template version: 1.0 | Created: April 2026_
