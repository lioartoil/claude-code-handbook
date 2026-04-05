---
name: spacetimedb-concepts
description: >
  Use when learning SpacetimeDB architecture, evaluating it for a project,
  or needing conceptual grounding before writing modules. Triggers on:
  "what is SpacetimeDB", "should I use SpacetimeDB", "how does SpacetimeDB work",
  "explain SpacetimeDB", or any architectural discussion about SpacetimeDB.
context: fork
---

# SpacetimeDB Concepts

> Target version: SpacetimeDB 2.0 | Last updated: April 2026

SpacetimeDB is a database that runs your server logic inside it. No separate backend.
Clients connect directly via WebSocket, subscribe to data with SQL queries, and call
functions (reducers) that mutate state. Think of it as **database + application server
in a single process**.

## Architecture

```
Client (React/Unity/Rust)
    │
    │ WebSocket
    ▼
┌──────────────────────────────────────┐
│  SpacetimeDB Instance                │
│  ┌────────────────────────────────┐  │
│  │  WASM Module (your code)       │  │
│  │  ├── Tables (schema + data)    │  │
│  │  ├── Reducers (mutations)      │  │
│  │  ├── Views (computed queries)  │  │
│  │  └── Lifecycle hooks           │  │
│  └────────────────────────────────┘  │
│  Subscription Engine                 │
│  Identity Manager                    │
└──────────────────────────────────────┘
```

**No REST. No GraphQL. No ORM. No BFF.** The module IS the backend.

## The Zen of SpacetimeDB

Five principles that shape every design decision:

| # | Principle | What it means |
|---|-----------|---------------|
| 1 | **Your database is your server** | Logic lives inside the database, not in a separate service |
| 2 | **Subscriptions, not requests** | Clients subscribe to queries; data flows when it changes |
| 3 | **The server is the authority** | All mutations go through reducers; clients never write directly |
| 4 | **Identity is built in** | Every connection has an identity; auth is a first-class concept |
| 5 | **Schema is your contract** | Table definitions auto-generate client types; no separate API spec |

## Core Concepts

| Concept | What it is | Analogy |
|---------|-----------|---------|
| **Table** | A strongly-typed data collection defined as a struct | Database table / Firestore collection |
| **Reducer** | A function that mutates tables inside a transaction | API endpoint / stored procedure |
| **Subscription** | A SQL query the client registers; server pushes matching row changes | Firestore `onSnapshot` / GraphQL subscription |
| **Identity** | A permanent cryptographic ID for each user | User ID / Firebase UID |
| **ConnectionId** | A per-session ID (changes on reconnect) | Session ID |
| **Energy** | Compute billing unit on SpacetimeDB Cloud | AWS Lambda invocations |
| **Module** | Your compiled code (WASM) deployed to SpacetimeDB | Microservice / Cloud Function |

## Mental Model: Traditional vs SpacetimeDB

### Traditional Stack

```
React App → REST/GraphQL → Express/Go API → Prisma/GORM → PostgreSQL
     │           │              │                │            │
  Frontend    Protocol       Backend          ORM          Database
```

5 layers. Types drift. API specs maintained separately. Backend is a translation layer.

### SpacetimeDB Stack

```
React App → WebSocket → SpacetimeDB (Module + Tables)
     │          │                    │
  Frontend  Protocol          Everything else
```

2 layers. Types auto-generated from table definitions. No API spec to maintain.

**The trade-off:** You gain simplicity and real-time sync. You lose the flexibility of a
traditional backend for complex integrations, multi-service orchestration, and granular
HTTP semantics.

## Identity & Auth

SpacetimeDB has two layers of identity:

| Layer | What | Persists across sessions? | Use for |
|-------|------|--------------------------|---------|
| **Identity** | Cryptographic ID generated on first connect | Yes (if token saved) | User identification, ownership |
| **ConnectionId** | Ephemeral session handle | No | Online presence, active sessions |

### Auth Options

1. **Built-in Identity** — SpacetimeDB generates a keypair. Simple, no external deps.
   Store the token client-side for persistence.

2. **External OIDC** — Bring your own provider (Auth0, Firebase, Keycloak). SpacetimeDB
   validates the JWT. Configure `issuer` to restrict which providers are accepted.

3. **Anonymous** — No auth. Useful for public read-only data.

Inside a reducer, access the caller via `ctx.sender` (Identity) or `ctx.connection_id` (ConnectionId).

## Subscription Model

Clients don't poll. They **subscribe** to SQL queries:

```
Client: "SELECT * FROM messages WHERE channel_id = 42"
                    │
                    ▼
Server tracks this query. When any reducer inserts/updates/deletes a matching row:
                    │
                    ▼
Server pushes the diff (inserted/deleted rows) to the client automatically.
```

**Key behaviors:**
- Subscriptions are **server-authoritative** — the server decides what data matches
- Multiple subscriptions compose — each client can have many active queries
- Row callbacks fire on the client: `onInsert`, `onDelete`, `onUpdate`
- The client SDK maintains a **local cache** of subscribed data
- Subscriptions are SQL, but only a subset is supported (no aggregations, no subqueries)

### Good: Think in Subscriptions

```
// Subscribe to what you need, react to changes
conn.subscribe("SELECT * FROM tasks WHERE assignee = :sender");
Task.onInsert((task) => addToUI(task));
Task.onDelete((task) => removeFromUI(task));
```

### Bad: Polling Like REST

```
// Don't do this — you're fighting the subscription model
setInterval(async () => {
  const tasks = await fetch("/api/tasks"); // SpacetimeDB doesn't work this way
  setTasks(tasks);
}, 1000);
```

## Migration Philosophy

Tables are strict structs. Schema evolution follows these rules:

| Change | Safety | Action |
|--------|--------|--------|
| Add a new table | Safe | Auto-migrated |
| Add a column with default | Safe | Auto-migrated |
| Add an index | Safe | Auto-migrated |
| Remove a column | Breaking | Requires `--delete-data` |
| Change a column type | Breaking | Requires `--delete-data` |
| Rename a table | Forbidden | Create new table, migrate data |
| Remove a primary key | Forbidden | Create new table |

### The Append-Only Rule

Like gRPC/protobuf: **only add fields, never remove or rename**. This avoids breaking
changes entirely. When you must make a breaking change, use the incremental migration
pattern:

1. Create a new table (`users_v2`) with the desired schema
2. Write a reducer that lazily migrates rows from `users` to `users_v2`
3. Update client subscriptions to read from `users_v2`
4. Deprecate `users` after migration completes

This pattern avoids `--delete-data` and preserves production data.

## When to Use SpacetimeDB

| Scenario | Fit | Why |
|----------|-----|-----|
| Real-time app (chat, collaboration) | Excellent | Subscriptions are the native model |
| Game server (multiplayer state sync) | Excellent | Built for this (Supercell backs it) |
| Small team / no backend devs | Great | Eliminates backend layer entirely |
| Rapid prototype / hackathon | Great | Init to working app in minutes |
| Internal tool with live data | Good | Real-time updates with minimal code |
| Complex multi-service system | Poor | No service mesh, no message queues |
| Heavy 3rd-party integrations | Poor | HTTP calls from reducers are possible but limited |
| Regulated data (PCI, HIPAA) | Poor | Young ecosystem, compliance tooling immature |
| High-write analytics pipeline | Poor | Not designed for append-only event streams |

## When NOT to Use

**Anti-pattern 1: REST API replacement.** If your app is request/response with no real-time
needs, SpacetimeDB adds complexity without benefit. Use a traditional API.

**Anti-pattern 2: Expecting ORM patterns.** There's no lazy loading, no relations, no
migrations CLI. Tables are flat structs. Design for denormalization.

**Anti-pattern 3: Ignoring the subscription model.** If you subscribe to everything and
filter client-side, you'll transfer unnecessary data. Subscribe to exactly what you need.

## v2.0 Breaking Changes (from v1)

| v1 | v2 | Notes |
|----|-----|-------|
| `ctx.sender` (field) | `ctx.sender()` (method) | Now a method call |
| Reducer callbacks | Event tables | Subscribe to events, not reducer results |
| `.unique().update()` | Manual find + delete + insert | `.unique()` no longer has `.update()` |
| Implicit table names | Explicit `#[table(name = ...)]` | Name canonicalization may change casing |

## References

- [Official Docs](https://spacetimedb.com/docs/)
- [Architecture Deep Dive](https://spacetimedb.com/docs/intro/key-architecture/)
- [The Zen of SpacetimeDB](https://spacetimedb.com/docs/intro/zen/)
- [Migration Guide v1 → v2](https://spacetimedb.com/docs/upgrade/)
- [GitHub](https://github.com/clockworklabs/SpacetimeDB)
