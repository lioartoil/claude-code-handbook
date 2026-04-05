---
name: spacetimedb-cli
description: >
  Use when setting up SpacetimeDB projects, running the dev server, publishing
  modules, or managing databases via CLI. Triggers on: "spacetime init",
  "start a SpacetimeDB project", "publish module", "spacetime logs",
  "spacetime sql", "spacetime generate", or any CLI workflow question.
context: fork
---

# SpacetimeDB CLI

> Target version: SpacetimeDB 2.0 | Last updated: April 2026

The `spacetime` CLI is the primary interface for SpacetimeDB development. It handles
project scaffolding, building, local dev, publishing, debugging, and identity management.

## Installation

```bash
# Install SpacetimeDB CLI
curl -sSf https://install.spacetimedb.com | bash

# Verify
spacetime version
```

## The Dev Loop

Every SpacetimeDB project follows this cycle:

```
spacetime init ──► edit module ──► spacetime build ──► spacetime dev ──► iterate
       │                                                      │
       │              spacetime generate (client types)        │
       │◄─────────────────────────────────────────────────────┘
       │
       └──► spacetime publish (when ready for production)
```

## Project Scaffolding

```bash
# Create a new Rust module (default)
spacetime init my-app

# Create with a specific language
spacetime init my-app --lang rust      # Rust (recommended)
spacetime init my-app --lang typescript # TypeScript (2.0+)
spacetime init my-app --lang csharp    # C# (Unity-friendly)
```

### Generated Structure (Rust)

```
my-app/
├── Cargo.toml          # spacetimedb dependency
├── src/
│   └── lib.rs          # Module entry point
└── .spacetime/         # Build artifacts (gitignored)
```

### Generated Structure (TypeScript)

```
my-app/
├── package.json
├── tsconfig.json
├── src/
│   └── lib.ts          # Module entry point
└── .spacetime/
```

## Command Reference

### Project Commands

| Command | What it does | Key flags |
|---------|-------------|-----------|
| `spacetime init <name>` | Scaffold a new module | `--lang rust\|typescript\|csharp` |
| `spacetime build` | Compile module to WASM | Outputs to `.spacetime/` |
| `spacetime generate` | Generate client types from module | `--lang typescript\|rust\|csharp`, `--out-dir` |

### Database Commands

| Command | What it does | Key flags |
|---------|-------------|-----------|
| `spacetime dev` | Build + run local dev server | Auto-reloads on changes |
| `spacetime publish <name>` | Deploy module to a database | `--delete-data` for breaking schema |
| `spacetime delete <name>` | Delete a database | Irreversible |
| `spacetime sql <db> "<query>"` | Run SQL against a database | Read-only queries |
| `spacetime logs <db>` | Stream module logs | `--follow` for tail |
| `spacetime call <db> <reducer> [args]` | Invoke a reducer directly | JSON args |
| `spacetime describe <db>` | Show tables, reducers, types | Inspect module schema |

### Identity Commands

| Command | What it does |
|---------|-------------|
| `spacetime identity new` | Create a new identity keypair |
| `spacetime identity list` | List all local identities |
| `spacetime identity set-default <id>` | Set the default identity |

### Server Commands

| Command | What it does |
|---------|-------------|
| `spacetime server add <name> <url>` | Register a remote server |
| `spacetime server set-default <name>` | Set the default server |
| `spacetime server list` | List registered servers |
| `spacetime server fingerprint <name>` | Show server fingerprint |

## Building

```bash
# Build the module (required before publish)
spacetime build

# The build compiles your Rust/TS/C# code to WASM
# Output goes to .spacetime/
```

**Anti-pattern:** Don't `spacetime publish` without `spacetime build` first. The CLI
may use a stale WASM artifact.

## Local Development

```bash
# Start local dev server with auto-reload
spacetime dev

# This:
# 1. Starts a local SpacetimeDB instance
# 2. Builds and publishes your module
# 3. Watches for file changes and rebuilds
```

The local dev server runs at `ws://localhost:3000` by default.

## Client Type Generation

After building your module, generate typed client code:

```bash
# Generate TypeScript client types
spacetime generate --lang typescript --out-dir ../client/src/generated

# Generate Rust client types
spacetime generate --lang rust --out-dir ../client/src/generated

# Generate C# client types
spacetime generate --lang csharp --out-dir ../client/Generated
```

This reads your module's table and reducer definitions and outputs type-safe client code.
**Run this every time you change tables or reducers.**

## Publishing

```bash
# First-time publish (creates the database)
spacetime publish my-app

# Update an existing database (safe schema changes only)
spacetime publish my-app

# Breaking schema change (deletes all data)
spacetime publish my-app --delete-data
```

### When You Need `--delete-data`

- Removing a column
- Changing a column type
- Removing a table that has data
- Any schema change that can't be auto-migrated

See `spacetimedb-concepts` for the migration philosophy and incremental migration pattern.

## Debugging

### Logs

```bash
# Stream logs from a database
spacetime logs my-app --follow

# Logs include:
# - Reducer invocations and results
# - println!/console.log output from your module
# - Errors and panics
```

### SQL Queries

```bash
# Run a read-only SQL query
spacetime sql my-app "SELECT * FROM users"
spacetime sql my-app "SELECT COUNT(*) FROM messages WHERE channel_id = 1"
```

### Inspect Schema

```bash
# Show all tables, reducers, and types
spacetime describe my-app
```

## Common Error Messages

| Error | Cause | Fix |
|-------|-------|-----|
| `Database not found` | Typo in database name or not published | Check `spacetime describe` |
| `Schema migration error` | Breaking change without `--delete-data` | Add `--delete-data` or use incremental migration |
| `WASM compilation failed` | Rust/TS build error in module code | Check `spacetime build` output |
| `Identity not found` | No default identity set | Run `spacetime identity new` |
| `Connection refused` | Local server not running | Run `spacetime dev` first |

## Quick Reference

| I want to... | Command |
|--------------|---------|
| Start a new project | `spacetime init my-app` |
| Run locally | `spacetime dev` |
| Generate client types | `spacetime generate --lang typescript --out-dir ./gen` |
| Deploy to production | `spacetime build && spacetime publish my-app` |
| Check what's in the DB | `spacetime sql my-app "SELECT * FROM users"` |
| See logs | `spacetime logs my-app --follow` |
| Inspect schema | `spacetime describe my-app` |
| Call a reducer manually | `spacetime call my-app create_user '["Alice","alice@test.com"]'` |
| Reset everything | `spacetime publish my-app --delete-data` |

## References

- [CLI Reference](https://spacetimedb.com/docs/cli-reference/)
- [Getting Started](https://spacetimedb.com/docs/getting-started/)
- [Chat App Tutorial](https://spacetimedb.com/docs/tutorials/chat-app/)
