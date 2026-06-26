# Sanity CMS Integration Tests

Read `sanity-work` and plugin `sanity-best-practices` skills first. Use Sanity MCP (`get_schema`, GROQ) when fixtures must match deployed schema.

## Default: mock the client or fetch layer

Do not query production datasets from tests unless the project documents a test dataset + token.

### Mock `@sanity/client` / project wrapper

```ts
import { vi } from "vitest";

export const mockFetch = vi.fn();

vi.mock("@/lib/sanity/client", () => ({
  client: {
    fetch: mockFetch,
  },
}));

beforeEach(() => {
  mockFetch.mockResolvedValue([{ _id: "post-1", title: "Hello" }]);
});
```

### Mock GROQ module functions

When the app exports `getPostBySlug(slug)` that wraps `client.fetch`:

```ts
vi.mock("@/lib/sanity/queries", () => ({
  getPostBySlug: vi.fn(async (slug: string) =>
    slug === "hello" ? { _id: "1", title: "Hello", slug } : null,
  ),
}));
```

Test the **consumer** (page data loader helper, route handler, component props mapper) against the mocked query module.

## Route handlers returning Sanity data

```ts
import { GET } from "@/app/api/posts/route";

vi.mock("@/lib/sanity/queries", () => ({
  getPosts: vi.fn(async () => [{ _id: "1", title: "Post" }]),
}));

it("returns posts as JSON", async () => {
  const response = await GET();
  expect(response.status).toBe(200);
  expect(await response.json()).toEqual([{ _id: "1", title: "Post" }]);
});
```

## UI components consuming Sanity content

Server-fetched content: pass **fixture props** into client components in RTL tests:

```tsx
render(<PostCard post={{ _id: "1", title: "Hello", slug: "hello" }} />);
expect(screen.getByRole("heading", { name: "Hello" })).toBeInTheDocument();
```

For client-side refetch, use MSW or mock `fetch` to the API route that wraps Sanity.

## Portable Text / rich content

Use minimal fixture blocks matching schema — avoid huge PT trees unless testing serializers:

```ts
const body = [
  { _type: "block", children: [{ _type: "span", text: "Paragraph" }] },
];
```

## Preview / draft mode

When testing preview-specific branches, mock `draftMode()` from `next/headers`:

```ts
vi.mock("next/headers", () => ({
  draftMode: vi.fn(async () => ({ isEnabled: true })),
}));
```

## MCP usage

Before writing fixtures: Sanity MCP `get_schema` for document types and field names. Align `_type`, references, and required fields with deployed schema.

## Dataset safety

Capability check must confirm: test mocks in use, or explicit non-production `dataset` + token in `.env.test.local`. Never read/write production datasets from Vitest runs.
