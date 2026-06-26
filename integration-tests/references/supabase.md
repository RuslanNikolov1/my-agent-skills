# Supabase Integration Tests

Read `supabase-work` and plugin `supabase-postgres-best-practices` skills first. Use Supabase MCP for schema context when tests must match real tables/RLS.

## Default: mock the client boundary

Integration tests should not write to production. Mock `@/lib/supabase/server` or `@/lib/supabase/client` unless the project uses a dedicated local/test Supabase instance.

```ts
import { vi } from "vitest";

const mockFrom = vi.fn();

vi.mock("@/lib/supabase/server", () => ({
  createClient: vi.fn(async () => ({
    from: mockFrom,
    auth: {
      getUser: vi.fn(async () => ({ data: { user: { id: "user-1" } }, error: null })),
    },
  })),
}));
```

Chain mocks to match query shape:

```ts
beforeEach(() => {
  mockFrom.mockReturnValue({
    select: vi.fn().mockReturnValue({
      eq: vi.fn().mockResolvedValue({
        data: [{ id: "1", title: "Post" }],
        error: null,
      }),
    }),
  });
});
```

Prefer a small **factory helper** in `tests/mocks/supabase.ts` when multiple tests share chains.

## Testing repository / service modules

Import the function under test; mock only `createClient`:

```ts
import { getPostsForUser } from "@/lib/posts";
import { createClient } from "@/lib/supabase/server";

vi.mock("@/lib/supabase/server");

it("returns posts for authenticated user", async () => {
  vi.mocked(createClient).mockResolvedValue(/* chained mock */ as never);
  const posts = await getPostsForUser("user-1");
  expect(posts).toHaveLength(1);
});
```

## Route handlers using Supabase

Combine [next-api-routes.md](next-api-routes.md) with client mocks above. Assert HTTP response, not raw Supabase chain internals.

## UI components using Supabase

Usually fetch via API route or server action — test at **API** or **UI+API** layer with `fetch`/MSW mocked. If a client component uses `@supabase/supabase-js` directly, mock the client module and assert rendered outcomes (RTL).

## Local Supabase (optional, project-specific)

When the repo documents `supabase start` + test database:

- Run against local instance only in `integration/data` or CI
- Reset state between tests (transactions or truncate helpers)
- Never commit service role keys; use env from `.env.test.local`

Report in capability check whether local Supabase is configured.

## Auth / RLS

- **Unit/integration with mocks:** stub `auth.getUser()` return value to simulate signed-in/out
- **RLS behavior:** prefer dedicated data tests with local Supabase or explicit policy documentation; do not assume mocks enforce RLS

## MCP usage

When schema fidelity matters: `plugin-supabase-supabase` — read tool schema, fetch table definitions, align fixtures with column types and constraints.
