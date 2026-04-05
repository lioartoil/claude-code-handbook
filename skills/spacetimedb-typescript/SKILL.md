---
name: spacetimedb-typescript
description: >
  Use when building TypeScript or React clients for SpacetimeDB — connection setup,
  subscriptions, calling reducers, authentication, and React hooks. Triggers on:
  "connect to SpacetimeDB", "SpacetimeDB client", "useTable", "subscribe to
  SpacetimeDB", "SpacetimeDB React", "SpacetimeDB TypeScript", or client-side
  SpacetimeDB work.
context: fork
---

# SpacetimeDB TypeScript Client

> Target version: SpacetimeDB 2.0 SDK | Last updated: April 2026
>
> For architecture and concepts, see `spacetimedb-concepts`.
> For TanStack integration, see `tanstack`.

The TypeScript client SDK connects to SpacetimeDB via WebSocket, subscribes to data,
calls reducers, and maintains a local cache of subscribed rows. Types are auto-generated
from your server module — no manual type definitions needed.

## Installation

```bash
# Install the SDK
npm install @clockworklabs/spacetimedb-sdk

# Generate client types from your module (see spacetimedb-cli)
spacetime generate --lang typescript --out-dir src/generated
```

The generated code contains typed table classes, reducer functions, and type definitions
that match your server module exactly.

## Connection Setup

```typescript
import { DbConnection } from "./generated";

const conn = DbConnection.builder()
  .withUri("ws://localhost:3000")
  .withModuleName("my-app")
  .onConnect((conn, identity, token) => {
    console.log("Connected as", identity.toHexString());
    // Save token for reconnection
    localStorage.setItem("stdb_token", token);
  })
  .onDisconnect((conn, error) => {
    console.log("Disconnected", error);
  })
  .onError((error) => {
    console.error("Connection error:", error);
  })
  .build();
```

### With Saved Token (Reconnection)

```typescript
const savedToken = localStorage.getItem("stdb_token");

const builder = DbConnection.builder()
  .withUri("ws://localhost:3000")
  .withModuleName("my-app")
  .onConnect((conn, identity, token) => {
    localStorage.setItem("stdb_token", token);
    setupSubscriptions(conn);
  });

if (savedToken) {
  builder.withToken(savedToken);
}

const conn = builder.build();
```

**Always save and reuse the token.** Without it, each reconnection creates a new identity.

## Subscriptions

Subscribe to data with SQL queries. The server pushes matching rows and subsequent changes:

```typescript
function setupSubscriptions(conn: DbConnection) {
  // Subscribe to all messages in a channel
  conn.subscriptionBuilder()
    .onApplied(() => {
      console.log("Initial data loaded");
      setLoaded(true);
    })
    .onError((error) => {
      console.error("Subscription error:", error);
    })
    .subscribe("SELECT * FROM messages WHERE channel_id = 1");

  // Subscribe to online users
  conn.subscriptionBuilder()
    .onApplied(() => setUsersLoaded(true))
    .subscribe("SELECT * FROM users WHERE online = true");
}
```

### Subscription Lifecycle

```
subscribe() ──► Server processes query
                        │
                        ▼
              onApplied() fires ──► Initial matching rows available
                        │
                        ▼
              Row callbacks fire on each change (insert/delete/update)
```

**Critical:** Do not read table data before `onApplied` fires. The local cache is empty
until the initial subscription result arrives.

### Good: Wait for onApplied

```typescript
conn.subscriptionBuilder()
  .onApplied(() => {
    // NOW it's safe to read data
    const users = Array.from(User.filterByOnline(true));
    setUsers(users);
  })
  .subscribe("SELECT * FROM users WHERE online = true");
```

### Bad: Reading Before Subscription Applied

```typescript
conn.subscriptionBuilder()
  .subscribe("SELECT * FROM users WHERE online = true");

// DON'T DO THIS — local cache is still empty
const users = Array.from(User.filterByOnline(true)); // Returns []
```

## Row Callbacks

Register handlers for row changes on any table:

```typescript
// New row inserted (or matches subscription for the first time)
conn.db.messages.onInsert((message, reducerEvent) => {
  setMessages(prev => [...prev, message]);
});

// Row deleted (or no longer matches subscription)
conn.db.messages.onDelete((message, reducerEvent) => {
  setMessages(prev => prev.filter(m => m.id !== message.id));
});

// Row updated (field values changed)
conn.db.messages.onUpdate((oldMessage, newMessage, reducerEvent) => {
  setMessages(prev => prev.map(m => m.id === oldMessage.id ? newMessage : m));
});
```

### Cleanup

Always clean up callbacks when your component unmounts:

```typescript
useEffect(() => {
  const unsubInsert = conn.db.messages.onInsert(handleInsert);
  const unsubDelete = conn.db.messages.onDelete(handleDelete);

  return () => {
    unsubInsert();
    unsubDelete();
  };
}, [conn]);
```

## Calling Reducers

Reducers are type-safe functions generated from your server module:

```typescript
// Call a reducer
conn.reducers.createUser("Alice", "alice@example.com");

// Call with callback for the result
conn.reducers.onCreateUser((ctx, name, email) => {
  if (ctx.status === "committed") {
    console.log("User created successfully");
  } else if (ctx.status === "failed") {
    console.error("Failed:", ctx.message);
  }
});
```

### Optimistic Updates

Show changes immediately, then reconcile with server:

```typescript
function sendMessage(text: string) {
  // 1. Optimistically add to UI
  const optimistic = { id: -1, text, sender: myIdentity, sent_at: Date.now() };
  setMessages(prev => [...prev, optimistic]);

  // 2. Call reducer
  conn.reducers.sendMessage(text);

  // 3. When server confirms, the real row arrives via onInsert
  //    Remove the optimistic row when the real one appears
}
```

## React Integration

SpacetimeDB provides first-party React hooks:

```typescript
import { SpacetimeDBProvider, useTable, useReducer } from "spacetimedb/react";

// Wrap your app
function App() {
  return (
    <SpacetimeDBProvider conn={conn}>
      <ChatRoom />
    </SpacetimeDBProvider>
  );
}

// Use hooks in components
function ChatRoom() {
  const messages = useTable(Message);          // Reactive — re-renders on changes
  const users = useTable(User);
  const sendMessage = useReducer(conn.reducers.sendMessage);

  return (
    <div>
      <ul>
        {messages.map(msg => (
          <li key={msg.id}>{msg.text}</li>
        ))}
      </ul>
      <button onClick={() => sendMessage("Hello!")}>Send</button>
    </div>
  );
}
```

`useTable` returns all rows currently in the local cache for that table. It automatically
re-renders the component when rows are inserted, deleted, or updated.

**For TanStack Query/Router/Table integration, see the `tanstack` skill.**

## Authentication

### Built-in Identity (Simplest)

```typescript
// First connection — new identity is auto-created
const conn = DbConnection.builder()
  .withUri("ws://localhost:3000")
  .withModuleName("my-app")
  .onConnect((conn, identity, token) => {
    // Save token to persist identity across sessions
    localStorage.setItem("stdb_token", token);
    localStorage.setItem("stdb_identity", identity.toHexString());
  })
  .build();
```

### External OIDC (Auth0, Firebase, Keycloak)

```typescript
import { AuthProvider, useAuth } from "react-oidc-context";

const oidcConfig = {
  authority: "https://your-auth0-domain.auth0.com",
  client_id: "your-client-id",
  redirect_uri: window.location.origin,
};

function SpacetimeDBWithAuth() {
  const auth = useAuth();

  useEffect(() => {
    if (auth.isAuthenticated && auth.user?.id_token) {
      const conn = DbConnection.builder()
        .withUri("wss://your-spacetimedb.com")
        .withModuleName("my-app")
        .withToken(auth.user.id_token)  // Pass OIDC token
        .onConnect((conn, identity, token) => {
          setupSubscriptions(conn);
        })
        .build();
    }
  }, [auth.isAuthenticated]);

  if (!auth.isAuthenticated) {
    return <button onClick={() => auth.signinRedirect()}>Login</button>;
  }

  return <App />;
}
```

### Token Persistence

| Approach | Pros | Cons |
|----------|------|------|
| `localStorage` | Simple, persists across tabs | XSS vulnerable |
| `sessionStorage` | Tab-scoped, cleared on close | New identity per tab |
| HTTP-only cookie | XSS-safe | Needs server-side setup |
| In-memory only | Most secure | New identity on every page load |

**Recommendation:** Use `localStorage` for development, HTTP-only cookies for production.

### Good: Persist and Reuse Token

```typescript
const token = localStorage.getItem("stdb_token");
const builder = DbConnection.builder().withUri(uri).withModuleName(module);
if (token) builder.withToken(token);
builder.onConnect((_, identity, newToken) => {
  localStorage.setItem("stdb_token", newToken);
});
```

### Bad: Ignoring Token Persistence

```typescript
// Every page load creates a NEW identity
const conn = DbConnection.builder()
  .withUri(uri)
  .withModuleName(module)
  .build();
// User's data is now orphaned under the old identity
```

## Reconnection

Handle disconnects gracefully:

```typescript
function createConnection() {
  const token = localStorage.getItem("stdb_token");

  const conn = DbConnection.builder()
    .withUri("ws://localhost:3000")
    .withModuleName("my-app")
    .withToken(token ?? undefined)
    .onConnect((conn, identity, newToken) => {
      localStorage.setItem("stdb_token", newToken);
      setupSubscriptions(conn);
      setConnected(true);
    })
    .onDisconnect((conn, error) => {
      setConnected(false);
      // Reconnect after delay
      setTimeout(() => createConnection(), 3000);
    })
    .onError((error) => {
      console.error("Connection error:", error);
    })
    .build();

  return conn;
}
```

**Tip:** Use exponential backoff for production reconnection (1s, 2s, 4s, 8s, max 30s).

## Error Handling

| Error Type | Where | How to Handle |
|------------|-------|---------------|
| Connection error | `onError` callback | Show "connecting..." UI, attempt reconnect |
| Subscription error | `onError` in subscriptionBuilder | Log, retry with simpler query |
| Reducer failure | `onReducerName` callback, check `status` | Show error to user, don't retry blindly |
| WebSocket close | `onDisconnect` callback | Auto-reconnect with saved token |

## Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| Reading data before `onApplied` | Always wait for the callback before accessing table data |
| Subscribing before `onConnect` | Set up subscriptions inside the `onConnect` callback |
| Not saving/reusing the token | Persist to `localStorage`; pass to `withToken()` on reconnect |
| Stale closures in callbacks | Use `useRef` for mutable state accessed in callbacks |
| Forgetting `spacetime generate` | Run after every module table/reducer change |
| `===` on Identity objects | Use `identity.isEqual(other)` — object equality won't work |
| Not cleaning up callbacks | Return unsubscribe functions in `useEffect` cleanup |

## References

- [TypeScript Client SDK](https://spacetimedb.com/docs/clients/typescript/)
- [Authentication Guide](https://spacetimedb.com/docs/core-concepts/authentication/)
- [React Quickstart](https://spacetimedb.com/docs/tutorials/chat-app/)
- [npm: @clockworklabs/spacetimedb-sdk](https://www.npmjs.com/package/@clockworklabs/spacetimedb-sdk)
