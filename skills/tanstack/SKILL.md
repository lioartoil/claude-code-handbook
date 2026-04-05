---
name: tanstack
description: >
  Use when building React apps with TanStack Query, Router, Table, or Form —
  especially with SpacetimeDB as the backend. Triggers on: "TanStack Query",
  "useQuery", "useMutation", "TanStack Router", "TanStack Table", "TanStack Form",
  "React data fetching", or building frontends with SpacetimeDB.
context: fork
---

# TanStack

> Target versions: Query v5, Router v1, Table v8, Form v1 | Last updated: April 2026
>
> For SpacetimeDB client SDK, see `spacetimedb-typescript`.

TanStack is a collection of framework-agnostic libraries for building web applications.
This skill focuses on **React** usage with **SpacetimeDB** as the data layer. Each library
is independent — use what you need.

| Library | Purpose | Maturity |
|---------|---------|----------|
| **Query** | Async state management, caching, data fetching | Stable (v5) |
| **Router** | Type-safe file-based routing with data loading | Stable (v1) |
| **Table** | Headless table/datagrid with sorting, filtering, pagination | Stable (v8) |
| **Form** | Form state management with validation | Stable (v1) |
| **Start** | Full-stack meta-framework (SSR, server functions) | Stable (v1), no RSC |
| **DB** | Reactive client store with differential dataflow | Alpha (v0.6) — not production-ready |

## TanStack Query

The core library. Manages async state with caching, background refetching, and stale management.

### Setup

```typescript
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000,    // 5 minutes
      gcTime: 10 * 60 * 1000,      // 10 minutes garbage collection
      retry: 2,
      refetchOnWindowFocus: false,  // Disable for SpacetimeDB (subscriptions handle freshness)
    },
  },
});

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <Router />
    </QueryClientProvider>
  );
}
```

### useQuery

```typescript
import { useQuery, queryOptions } from "@tanstack/react-query";

// Define query options (reusable, composable)
const usersQueryOptions = queryOptions({
  queryKey: ["users"],
  queryFn: () => fetchUsers(),
  staleTime: 60_000,
});

function UserList() {
  const { data, isLoading, error } = useQuery(usersQueryOptions);

  if (isLoading) return <Spinner />;
  if (error) return <Error message={error.message} />;

  return <ul>{data.map(user => <li key={user.id}>{user.name}</li>)}</ul>;
}
```

### useMutation

```typescript
import { useMutation, useQueryClient } from "@tanstack/react-query";

function CreateUserForm() {
  const queryClient = useQueryClient();

  const mutation = useMutation({
    mutationFn: (data: { name: string; email: string }) => createUser(data),
    onSuccess: () => {
      // Invalidate the users query to refetch
      queryClient.invalidateQueries({ queryKey: ["users"] });
    },
    // Or: optimistic update
    onMutate: async (newUser) => {
      await queryClient.cancelQueries({ queryKey: ["users"] });
      const previous = queryClient.getQueryData(["users"]);
      queryClient.setQueryData(["users"], (old: User[]) => [...old, newUser]);
      return { previous };
    },
    onError: (err, newUser, context) => {
      queryClient.setQueryData(["users"], context?.previous);
    },
  });

  return <form onSubmit={(e) => mutation.mutate(formData)}>...</form>;
}
```

### Dependent Queries

```typescript
const { data: user } = useQuery({
  queryKey: ["user", userId],
  queryFn: () => fetchUser(userId),
});

const { data: orders } = useQuery({
  queryKey: ["orders", user?.id],
  queryFn: () => fetchOrders(user!.id),
  enabled: !!user, // Only runs when user is available
});
```

### Invalidation vs Direct Cache Updates

| Approach | When to use |
|----------|------------|
| `invalidateQueries` | Simple; triggers refetch. Good for REST APIs. |
| `setQueryData` | Direct cache update. Good for real-time/subscription data. |

**With SpacetimeDB, prefer `setQueryData`** — the subscription already has the data,
no need to refetch.

## TanStack Router

Type-safe routing with built-in data loading.

### File-Based Routes

```
src/routes/
├── __root.tsx          # Root layout
├── index.tsx           # /
├── about.tsx           # /about
├── users/
│   ├── index.tsx       # /users
│   └── $userId.tsx     # /users/:userId
└── settings.tsx        # /settings
```

### Route Definition

```typescript
// src/routes/users/$userId.tsx
import { createFileRoute } from "@tanstack/react-router";

export const Route = createFileRoute("/users/$userId")({
  // Type-safe params
  loader: async ({ params }) => {
    return fetchUser(params.userId); // params.userId is typed as string
  },
  component: UserDetail,
});

function UserDetail() {
  const user = Route.useLoaderData();
  return <h1>{user.name}</h1>;
}
```

### Search Params (Type-Safe)

```typescript
import { createFileRoute } from "@tanstack/react-router";
import { z } from "zod";

const searchSchema = z.object({
  page: z.number().default(1),
  sort: z.enum(["name", "date"]).default("name"),
  filter: z.string().optional(),
});

export const Route = createFileRoute("/users")({
  validateSearch: searchSchema,
  component: UserList,
});

function UserList() {
  const { page, sort, filter } = Route.useSearch(); // Fully typed
  const navigate = Route.useNavigate();

  return (
    <button onClick={() => navigate({ search: { page: page + 1 } })}>
      Next Page
    </button>
  );
}
```

### Integration with TanStack Query

```typescript
export const Route = createFileRoute("/users/$userId")({
  loader: async ({ context: { queryClient }, params }) => {
    // Ensure data is loaded before rendering
    return queryClient.ensureQueryData(userQueryOptions(params.userId));
  },
});
```

Set `defaultPreloadStaleTime: 0` in the router to delegate caching to TanStack Query.

## TanStack Table

Headless — no UI, just logic. You control all rendering.

### Basic Setup

```typescript
import { useReactTable, getCoreRowModel, createColumnHelper } from "@tanstack/react-table";

type User = { id: number; name: string; email: string; role: string };

const columnHelper = createColumnHelper<User>();

const columns = [
  columnHelper.accessor("name", {
    header: "Name",
    cell: (info) => info.getValue(),
  }),
  columnHelper.accessor("email", {
    header: "Email",
  }),
  columnHelper.accessor("role", {
    header: "Role",
    cell: (info) => <Badge>{info.getValue()}</Badge>,
  }),
  columnHelper.display({
    id: "actions",
    header: "Actions",
    cell: ({ row }) => <button onClick={() => editUser(row.original)}>Edit</button>,
  }),
];
```

### Table Instance

```typescript
function UserTable({ data }: { data: User[] }) {
  const [sorting, setSorting] = useState<SortingState>([]);
  const [filtering, setFiltering] = useState("");

  const table = useReactTable({
    data,
    columns,
    state: { sorting, globalFilter: filtering },
    onSortingChange: setSorting,
    onGlobalFilterChange: setFiltering,
    getCoreRowModel: getCoreRowModel(),
    getSortedRowModel: getSortedRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    getPaginationRowModel: getPaginationRowModel(),
  });

  return (
    <table>
      <thead>
        {table.getHeaderGroups().map(headerGroup => (
          <tr key={headerGroup.id}>
            {headerGroup.headers.map(header => (
              <th key={header.id} onClick={header.column.getToggleSortingHandler()}>
                {flexRender(header.column.columnDef.header, header.getContext())}
              </th>
            ))}
          </tr>
        ))}
      </thead>
      <tbody>
        {table.getRowModel().rows.map(row => (
          <tr key={row.id}>
            {row.getVisibleCells().map(cell => (
              <td key={cell.id}>
                {flexRender(cell.column.columnDef.cell, cell.getContext())}
              </td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  );
}
```

**Anti-pattern:** Don't put complex rendering logic inside column definitions. Table is
headless — keep column defs focused on data access, handle complex UI in the component.

## TanStack Form

Type-safe form state with validation tiers.

### Basic Form

```typescript
import { useForm } from "@tanstack/react-form";
import { z } from "zod";

function CreateUserForm() {
  const form = useForm({
    defaultValues: {
      name: "",
      email: "",
      role: "member" as const,
    },
    onSubmit: async ({ value }) => {
      await createUser(value);
    },
  });

  return (
    <form onSubmit={(e) => { e.preventDefault(); form.handleSubmit(); }}>
      <form.Field
        name="name"
        validators={{
          onChange: z.string().min(2, "Name must be at least 2 characters"),
        }}
      >
        {(field) => (
          <div>
            <input
              value={field.state.value}
              onChange={(e) => field.handleChange(e.target.value)}
              onBlur={field.handleBlur}
            />
            {field.state.meta.errors.map(err => <span key={err}>{err}</span>)}
          </div>
        )}
      </form.Field>

      <form.Subscribe selector={(s) => s.isSubmitting}>
        {(isSubmitting) => (
          <button type="submit" disabled={isSubmitting}>
            {isSubmitting ? "Creating..." : "Create User"}
          </button>
        )}
      </form.Subscribe>
    </form>
  );
}
```

### Validation Tiers

| Tier | When it runs | Use for |
|------|-------------|---------|
| `onChange` | Every keystroke | Format validation, character limits |
| `onBlur` | When field loses focus | Email format, required fields |
| `onSubmit` | On form submit | Final validation, server-side checks |
| `onChangeAsync` | Debounced on change | Username availability, API validation |

### Field Arrays

```typescript
<form.Field name="tags" mode="array">
  {(field) => (
    <div>
      {field.state.value.map((_, i) => (
        <form.Field key={i} name={`tags[${i}]`}>
          {(subField) => <input value={subField.state.value} onChange={...} />}
        </form.Field>
      ))}
      <button onClick={() => field.pushValue("")}>Add Tag</button>
    </div>
  )}
</form.Field>
```

## SpacetimeDB Integration

Three approaches, from simplest to most flexible:

### Option A: SpacetimeDB React Hooks (Simplest)

```typescript
import { SpacetimeDBProvider, useTable, useReducer } from "spacetimedb/react";

function App() {
  return (
    <SpacetimeDBProvider conn={conn}>
      <UserList />
    </SpacetimeDBProvider>
  );
}

function UserList() {
  const users = useTable(User);       // Reactive, auto-updates
  const createUser = useReducer(conn.reducers.createUser);

  return (
    <ul>
      {users.map(u => <li key={u.id}>{u.name}</li>)}
      <button onClick={() => createUser("New User", "new@test.com")}>Add</button>
    </ul>
  );
}
```

**Pros:** Zero boilerplate, no double-caching.
**Cons:** No TanStack Query features (devtools, suspense, error boundaries).

### Option B: SpacetimeDB TanStack Bridge (Official)

```typescript
import { useSpacetimeDBQuery } from "spacetimedb/tanstack";

function UserList() {
  const [users, loading, query] = useSpacetimeDBQuery(User);

  if (loading) return <Spinner />;

  return <ul>{users.map(u => <li key={u.id}>{u.name}</li>)}</ul>;
}
```

**Pros:** Gets TanStack Query integration (devtools, suspense), official support.
**Cons:** Double-caching (SpacetimeDB cache + TanStack Query cache).

### Option C: Custom Bridge (Full Control)

```typescript
import { useQuery, useQueryClient } from "@tanstack/react-query";

function useSpacetimeTable<T>(table: { all: () => T[]; onInsert: any; onDelete: any; onUpdate: any }, queryKey: string[]) {
  const queryClient = useQueryClient();

  useEffect(() => {
    const unsubs = [
      table.onInsert(() => {
        queryClient.setQueryData(queryKey, () => [...table.all()]);
      }),
      table.onDelete(() => {
        queryClient.setQueryData(queryKey, () => [...table.all()]);
      }),
      table.onUpdate(() => {
        queryClient.setQueryData(queryKey, () => [...table.all()]);
      }),
    ];
    return () => unsubs.forEach(fn => fn());
  }, [table, queryKey, queryClient]);

  return useQuery({
    queryKey,
    queryFn: () => [...table.all()],
    staleTime: Infinity,  // SpacetimeDB pushes updates — never refetch
  });
}

// Usage
function UserList() {
  const { data: users, isLoading } = useSpacetimeTable(User, ["users"]);
  // Full TanStack Query API available: suspense, error boundaries, devtools
}
```

**Pros:** Full control, TanStack Query features, custom cache strategy.
**Cons:** More code, you own the bridge.

### Which Option?

| Scenario | Use | Why |
|----------|-----|-----|
| Simple app, few tables | **Option A** | No overhead, no double cache |
| Need devtools, suspense, error boundaries | **Option B** | Official bridge, minimal setup |
| Complex app, custom cache invalidation | **Option C** | Full control over caching strategy |
| Already using TanStack Query for other data | **Option B or C** | Consistent data layer |

### Double-Caching Warning

SpacetimeDB maintains its own client-side cache of all subscribed rows. TanStack Query
adds a second cache layer on top. This means:

- Data exists in two places (memory overhead)
- Cache invalidation must consider both layers
- `refetchOnWindowFocus` will fight SpacetimeDB's push model

**Mitigation:** Set `staleTime: Infinity` and disable `refetchOnWindowFocus` when using
SpacetimeDB subscriptions. Let SpacetimeDB handle freshness.

### Bad: Fighting the Subscription Model

```typescript
// SpacetimeDB already pushes updates — don't also poll
const { data } = useQuery({
  queryKey: ["users"],
  queryFn: () => [...User.all()],
  staleTime: 0,                    // Causes unnecessary re-reads
  refetchOnWindowFocus: true,      // Causes unnecessary re-reads
  refetchInterval: 5000,           // Polling on top of subscriptions
});
```

### Good: Trusting Subscriptions

```typescript
const { data } = useQuery({
  queryKey: ["users"],
  queryFn: () => [...User.all()],
  staleTime: Infinity,             // SpacetimeDB handles freshness
  refetchOnWindowFocus: false,     // No polling needed
});

// Updates flow through onInsert/onDelete/onUpdate → setQueryData
```

## Best Practices

| Practice | Why |
|----------|-----|
| Use `queryOptions()` helper | Reusable, composable, type-safe query definitions |
| Colocate queries with routes | Router loaders + Query = data ready before render |
| Keep column defs simple | Table is headless — render complexity belongs in components |
| Use `form.Subscribe` | Prevents entire form re-renders on every keystroke |
| Set `staleTime` globally | Avoid per-query boilerplate; override where needed |
| Disable `refetchOnWindowFocus` with SpacetimeDB | Subscriptions handle freshness |

## Common Pitfalls

| Pitfall | Fix |
|---------|-----|
| `refetchOnWindowFocus` fires unexpectedly in dev | Set to `false` globally or per-query |
| `invalidateQueries` removes data from cache | It doesn't — it marks data as stale, triggering refetch |
| Query keys don't include dynamic params | Include all variables: `["users", { page, filter }]` |
| TanStack DB used in production | It's alpha (v0.6) — use Query + Router + Table instead |
| Double-caching with SpacetimeDB | Set `staleTime: Infinity`, disable refetch, use `setQueryData` |
| Form re-renders on every keystroke | Use `form.Subscribe` with selectors for dependent UI |

## References

- [TanStack Query Docs](https://tanstack.com/query/latest)
- [TanStack Router Docs](https://tanstack.com/router/latest)
- [TanStack Table Docs](https://tanstack.com/table/latest)
- [TanStack Form Docs](https://tanstack.com/form/latest)
- [TanStack Start Docs](https://tanstack.com/start/latest)
- [SpacetimeDB TanStack Integration](https://spacetimedb.com/docs/clients/typescript/)
