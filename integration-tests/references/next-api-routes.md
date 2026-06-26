# Next.js Route Handler Integration Tests

Vitest (`node` environment). Read `next-best-practices` → `route-handlers.md` and `async-patterns.md` for handler conventions.

## Direct handler import

Import named exports from `route.ts` and invoke with Web `Request` / `Response` APIs:

```ts
import { describe, expect, it, vi } from "vitest";
import { GET, POST } from "@/app/api/users/route";

describe("GET /api/users", () => {
  it("returns 200 with users", async () => {
    const response = await GET();
    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body).toEqual(expect.arrayContaining([expect.objectContaining({ id: expect.any(String) })]));
  });
});

describe("POST /api/users", () => {
  it("creates a user", async () => {
    const request = new Request("http://localhost/api/users", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: "Ada" }),
    });

    const response = await POST(request);
    expect(response.status).toBe(201);
    expect(await response.json()).toMatchObject({ name: "Ada" });
  });
});
```

## Dynamic segments

App Router `params` is a **Promise**:

```ts
import { GET } from "@/app/api/users/[id]/route";

it("returns user by id", async () => {
  const request = new Request("http://localhost/api/users/u1");
  const response = await GET(request, { params: Promise.resolve({ id: "u1" }) });
  expect(response.status).toBe(200);
});
```

## Mocking Next.js server APIs

```ts
import { vi } from "vitest";

vi.mock("next/headers", () => ({
  cookies: vi.fn(async () => ({
    get: vi.fn((name: string) => (name === "session" ? { value: "token" } : undefined)),
    set: vi.fn(),
    delete: vi.fn(),
  })),
  headers: vi.fn(async () => new Headers({ "x-forwarded-for": "127.0.0.1" })),
}));
```

Place mocks at **module level** in the test file or a shared `tests/mocks/next-headers.ts` imported from `setupFiles`.

## Mocking data layer

Mock the module your handler imports — not the handler itself:

```ts
vi.mock("@/lib/db/users", () => ({
  getUsers: vi.fn(async () => [{ id: "1", name: "Test" }]),
  createUser: vi.fn(async (data) => ({ id: "2", ...data })),
}));
```

## What to assert

- HTTP status codes
- Response body shape (success and error)
- Validation failures (400) and auth failures (401/403)
- Side effects via mocked collaborators (`toHaveBeenCalledWith`)

## What to avoid

- Importing React or calling `render()` in route tests
- Hitting real Supabase/Sanity/production APIs from handler tests
- Testing Next.js framework internals

## Search params

```ts
const request = new Request("http://localhost/api/search?q=hello&page=2");
const response = await GET(request);
```

Parse `request.nextUrl` or `new URL(request.url)` inside the handler — test with realistic URLs.
