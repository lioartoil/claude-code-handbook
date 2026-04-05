---
name: spacetimedb-rust
description: >
  Use when writing SpacetimeDB server modules in Rust — table definitions,
  reducers, lifecycle hooks, scheduling, views, procedures, and migrations.
  Triggers on: "create a SpacetimeDB module", "add a table", "write a reducer",
  "SpacetimeDB Rust", server-side SpacetimeDB work, or Rust module code generation.
context: fork
---

# SpacetimeDB Rust Modules

> Target version: SpacetimeDB 2.0 | Last updated: April 2026
>
> For architecture and concepts, see `spacetimedb-concepts`.
> For CLI workflow, see `spacetimedb-cli`.

Write your server logic as a Rust module that compiles to WASM and runs inside SpacetimeDB.
Tables are structs. Reducers are functions. Everything runs in transactions.

## Project Setup

```toml
# Cargo.toml
[dependencies]
spacetimedb = "2.0"

[lib]
crate-type = ["cdylib"]
```

```rust
// src/lib.rs
use spacetimedb::*;
```

## Tables

Define tables as structs with the `#[table]` attribute:

```rust
#[table(name = users, public)]
pub struct User {
    #[primary_key]
    #[auto_inc]
    pub id: u64,
    #[unique]
    pub email: String,
    pub name: String,
    pub created_at: Timestamp,
}
```

### Constraints

| Attribute | Effect | Notes |
|-----------|--------|-------|
| `#[primary_key]` | Unique row identifier | Required on at least one field |
| `#[auto_inc]` | Auto-increment on insert | Only on integer types, pass `0` to trigger |
| `#[unique]` | Enforce uniqueness | Creates an accessor: `ctx.db.users().email().find(&val)` |
| `#[index(btree)]` | B-tree index for range queries | Use for fields you filter/sort on |

### Visibility

| Visibility | Meaning |
|------------|---------|
| `#[table(name = x, public)]` | Clients can subscribe to this table |
| `#[table(name = x)]` (default) | Private — only accessible inside reducers |

**Rule:** Make tables `public` only if clients need to subscribe. Keep internal state private.

### Multi-Column Indexes

```rust
#[table(name = messages, public)]
#[index(btree, name = idx_channel_time, channel_id, sent_at)]
pub struct Message {
    #[primary_key]
    #[auto_inc]
    pub id: u64,
    pub channel_id: u64,
    pub sender: Identity,
    pub text: String,
    pub sent_at: Timestamp,
}
```

### Accessor Naming

SpacetimeDB generates typed accessors from your constraints:

```rust
// Primary key → .id()
ctx.db.users().id().find(42);

// Unique field → .email()
ctx.db.users().email().find(&"alice@example.com".to_string());

// BTree index → .idx_channel_time()
ctx.db.messages().idx_channel_time().filter(|row| row.channel_id == &1);
```

## Type System

### Supported Types

| Rust Type | SpacetimeDB Type | Notes |
|-----------|-----------------|-------|
| `bool` | Bool | |
| `u8, u16, u32, u64, u128` | Unsigned integers | |
| `i8, i16, i32, i64, i128` | Signed integers | |
| `f32, f64` | Floats | |
| `String` | String | |
| `Vec<T>` | Array | T must be a supported type |
| `Option<T>` | Optional | |
| `Identity` | Identity | Built-in, 256-bit |
| `ConnectionId` | ConnectionId | Built-in, ephemeral |
| `Timestamp` | Timestamp | Microsecond precision |

### Custom Types

```rust
#[derive(SpacetimeType)]
pub struct Position {
    pub x: f64,
    pub y: f64,
    pub z: f64,
}

#[derive(SpacetimeType)]
pub enum Status {
    Active,
    Inactive,
    Banned,
}
```

Use `#[sats(rename = "camelCaseName")]` to control cross-language naming.

## Reducers

Reducers are transactional functions that mutate tables:

```rust
#[reducer]
pub fn create_user(ctx: &ReducerContext, name: String, email: String) -> Result<(), String> {
    // Check for duplicates
    if ctx.db.users().email().find(&email).is_some() {
        return Err("Email already exists".to_string());
    }

    ctx.db.users().insert(User {
        id: 0, // auto_inc fills this
        email,
        name,
        created_at: ctx.timestamp,
    })?;

    Ok(())
}
```

### CRUD Operations

| Operation | Code | Notes |
|-----------|------|-------|
| **Insert** | `ctx.db.users().insert(user)?` | Returns the inserted row (with auto_inc filled) |
| **Find by PK** | `ctx.db.users().id().find(42)` | Returns `Option<User>` |
| **Find by unique** | `ctx.db.users().email().find(&val)` | Returns `Option<User>` |
| **Filter** | `ctx.db.users().iter().filter(\|u\| u.active)` | Full table scan if no index |
| **Update** | `ctx.db.users().id().update(User { .. })` | Replace entire row by PK |
| **Delete by PK** | `ctx.db.users().id().delete(42)` | Returns `bool` |
| **Delete row** | `ctx.db.users().delete(user)` | Delete by value |
| **Count** | `ctx.db.users().count()` | |

### ReducerContext

| Property | Type | What it is |
|----------|------|-----------|
| `ctx.sender` | `Identity` | Caller's identity |
| `ctx.connection_id` | `Option<ConnectionId>` | Caller's connection (None if scheduled) |
| `ctx.timestamp` | `Timestamp` | Transaction timestamp |
| `ctx.db` | `DbContext` | Table accessors |

### Error Handling

```rust
#[reducer]
pub fn transfer(ctx: &ReducerContext, from: u64, to: u64, amount: f64) -> Result<(), String> {
    let mut sender = ctx.db.accounts().id().find(from)
        .ok_or("Sender not found")?;
    let mut receiver = ctx.db.accounts().id().find(to)
        .ok_or("Receiver not found")?;

    if sender.balance < amount {
        return Err("Insufficient funds".to_string());
    }

    sender.balance -= amount;
    receiver.balance += amount;

    ctx.db.accounts().id().update(sender);
    ctx.db.accounts().id().update(receiver);

    Ok(())
}
```

**Returning `Err` rolls back the entire transaction.** No partial writes.

### Good: Proper Error Handling

```rust
#[reducer]
pub fn do_something(ctx: &ReducerContext, id: u64) -> Result<(), String> {
    let item = ctx.db.items().id().find(id)
        .ok_or("Item not found")?;
    // ... safe operations
    Ok(())
}
```

### Bad: Panicking in Reducers

```rust
#[reducer]
pub fn do_something(ctx: &ReducerContext, id: u64) {
    let item = ctx.db.items().id().find(id).unwrap(); // PANICS the WASM module
    // If the item doesn't exist, the entire module crashes
}
```

**Never use `unwrap()` or `expect()` in reducers.** Return `Result<(), String>` and use `?`.

## Lifecycle Hooks

```rust
// Runs once when the module is first published
#[reducer(init)]
pub fn init(ctx: &ReducerContext) -> Result<(), String> {
    // Seed initial data, set up config
    ctx.db.config().insert(Config { key: "version".into(), value: "1.0".into() })?;
    Ok(())
}

// Runs when a client connects
#[reducer(client_connected)]
pub fn on_connect(ctx: &ReducerContext) -> Result<(), String> {
    log::info!("Client connected: {:?}", ctx.sender);
    Ok(())
}

// Runs when a client disconnects
#[reducer(client_disconnected)]
pub fn on_disconnect(ctx: &ReducerContext) -> Result<(), String> {
    // Clean up presence, mark offline
    if let Some(mut user) = ctx.db.users().identity().find(ctx.sender) {
        user.online = false;
        ctx.db.users().identity().update(user);
    }
    Ok(())
}
```

## Scheduling

Use `ScheduleAt` to run reducers on a timer:

```rust
// Define a schedule table
#[table(name = cleanup_schedule, scheduled(cleanup))]
pub struct CleanupSchedule {
    #[primary_key]
    #[auto_inc]
    pub id: u64,
    pub scheduled_at: ScheduleAt,
}

// The reducer that runs on schedule
#[reducer]
pub fn cleanup(ctx: &ReducerContext, _args: CleanupSchedule) -> Result<(), String> {
    let cutoff = ctx.timestamp - Duration::from_secs(86400);
    for msg in ctx.db.messages().iter().filter(|m| m.sent_at < cutoff) {
        ctx.db.messages().delete(msg);
    }
    Ok(())
}

// Schedule it in init
#[reducer(init)]
pub fn init(ctx: &ReducerContext) -> Result<(), String> {
    ctx.db.cleanup_schedule().insert(CleanupSchedule {
        id: 0,
        scheduled_at: ScheduleAt::Interval(Duration::from_secs(3600)), // Every hour
    })?;
    Ok(())
}
```

`ScheduleAt` variants:
- `ScheduleAt::Time(timestamp)` — Run once at a specific time
- `ScheduleAt::Interval(duration)` — Run repeatedly at an interval

## Views

Read-only computed queries (new in 2.0):

```rust
#[table(name = active_users, public)]
#[view(query = "SELECT * FROM users WHERE online = true")]
pub struct ActiveUser {
    pub id: u64,
    pub name: String,
    pub online: bool,
}
```

Clients subscribe to views like regular tables. The view auto-updates when underlying data changes.

**Performance warning:** Views track a "read set" and re-evaluate when ANY table in the
read set changes. For high-frequency updates, this can be expensive. Prefer direct
subscriptions with filtered queries over views when write volume is high.

### When to Use Views vs Subscriptions vs Procedures

| Need | Use | Why |
|------|-----|-----|
| Real-time filtered data | Subscription query | Most efficient, server pushes diffs |
| Computed/joined data for clients | View | Auto-updates, but re-evaluates on any source change |
| One-shot query or HTTP response | Procedure | No subscription overhead, manual transaction |
| Internal logic, no client access | Reducer with private table | Keep it out of the subscription engine |

## Procedures

HTTP-callable functions with manual transaction control (new in 2.0):

```rust
#[reducer(procedure)]
pub fn get_stats(ctx: &ReducerContext) -> Result<String, String> {
    let user_count = ctx.db.users().count();
    let msg_count = ctx.db.messages().count();
    Ok(format!(r#"{{"users":{},"messages":{}}}"#, user_count, msg_count))
}
```

Use procedures for:
- HTTP API endpoints (GET-style queries)
- Operations that don't need real-time subscriptions
- Integration with external services

## Event Tables

Transient tables for signaling — rows exist only during the transaction:

```rust
#[table(name = notification_events, public)]
#[event]
pub struct NotificationEvent {
    #[primary_key]
    #[auto_inc]
    pub id: u64,
    pub user_id: u64,
    pub message: String,
}
```

Clients can only register `onInsert` callbacks for event tables (no `onDelete`/`onUpdate`).
Use for notifications, toasts, ephemeral signals.

## Row-Level Security

> Experimental (unstable). API may change.

Restrict which rows a client can see based on their identity:

```rust
#[table(name = private_messages, public)]
#[rls(filter = "sender = :sender OR recipient = :sender")]
pub struct PrivateMessage {
    #[primary_key]
    #[auto_inc]
    pub id: u64,
    pub sender: Identity,
    pub recipient: Identity,
    pub text: String,
}
```

`:sender` is the subscribing client's identity. Multiple `#[rls]` attributes are OR'd.

**Known limitation:** RLS + subscription + complex joins can produce unexpected results
(issue #2810). Test thoroughly.

## Testing

There is no `spacetime test` command (issue #2788). Use these workarounds:

1. **Unit test pure logic** — Extract business logic into plain Rust functions, test with `#[cfg(test)]`
2. **Integration test against local instance** — `spacetime dev`, then run client-side tests that call reducers
3. **Separate test database** — `spacetime publish test-my-app` for isolated testing
4. **RLS testing** — Use `--anonymous` flag to test as different identities

```rust
// Extract testable logic
fn validate_transfer(balance: f64, amount: f64) -> Result<(), String> {
    if amount <= 0.0 { return Err("Amount must be positive".into()); }
    if balance < amount { return Err("Insufficient funds".into()); }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_validate_transfer() {
        assert!(validate_transfer(100.0, 50.0).is_ok());
        assert!(validate_transfer(100.0, 150.0).is_err());
        assert!(validate_transfer(100.0, -10.0).is_err());
    }
}
```

## Migration Strategy

See `spacetimedb-concepts` for the full migration philosophy.

### Safe Changes (auto-migrated)

- Add a new table
- Add a column with a default value
- Add an index

### Breaking Changes (require `--delete-data`)

- Remove a column
- Change a column type
- Remove a table with data

### Incremental Migration Pattern

```rust
// Step 1: Create new table alongside old
#[table(name = users_v2, public)]
pub struct UserV2 {
    #[primary_key]
    pub id: u64,
    pub email: String,
    pub display_name: String, // renamed from 'name'
    pub role: UserRole,       // new field
}

// Step 2: Lazy migration reducer
#[reducer]
pub fn migrate_user(ctx: &ReducerContext, user_id: u64) -> Result<(), String> {
    if let Some(old) = ctx.db.users().id().find(user_id) {
        if ctx.db.users_v2().id().find(user_id).is_none() {
            ctx.db.users_v2().insert(UserV2 {
                id: old.id,
                email: old.email,
                display_name: old.name,
                role: UserRole::Member,
            })?;
        }
    }
    Ok(())
}
```

## Performance

### Index Strategy

```rust
// Good: indexed query
ctx.db.messages().idx_channel_time().filter(|m| m.channel_id == &channel_id);

// Bad: full table scan
ctx.db.messages().iter().filter(|m| m.channel_id == channel_id);
```

**Rule:** If you filter on a field, add `#[index(btree)]` to it.

### Table Decomposition

Split hot and cold data:

```rust
// Good: separate hot (frequently read) from cold (rarely read) data
#[table(name = user_profiles, public)]
pub struct UserProfile {
    #[primary_key]
    pub user_id: u64,
    pub name: String,
    pub avatar_url: String,
}

#[table(name = user_settings)]
pub struct UserSettings {
    #[primary_key]
    pub user_id: u64,
    pub theme: String,
    pub notifications_enabled: bool,
}
```

### Batching

When inserting many rows, do it in a single reducer call:

```rust
#[reducer]
pub fn bulk_insert(ctx: &ReducerContext, items: Vec<ItemData>) -> Result<(), String> {
    for item in items {
        ctx.db.items().insert(Item::from(item))?;
    }
    Ok(()) // Single transaction for all inserts
}
```

## Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| `unwrap()` in reducers | Return `Result<(), String>`, use `?` |
| Filtering without indexes | Add `#[index(btree)]` on filter fields |
| Large `public` tables | Minimize public surface; use private tables for internal state |
| View on high-write tables | Prefer direct subscriptions with SQL filters |
| Forgetting `spacetime generate` | Run after every table/reducer change |
| Storing blobs in tables | Use S3/external storage; store URLs in tables |
| Not seeding data in `init` | Use `#[reducer(init)]` for initial config/data |

## References

- [Tables Reference](https://spacetimedb.com/docs/tables/)
- [Reducers Reference](https://spacetimedb.com/docs/functions/reducers/)
- [Cheat Sheet](https://spacetimedb.com/docs/databases/cheat-sheet/)
- [Performance Best Practices](https://spacetimedb.com/docs/tables/performance/)
- [Automatic Migrations](https://spacetimedb.com/docs/databases/automatic-migrations/)
