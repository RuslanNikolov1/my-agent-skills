# UI Integration Tests

Vitest (`jsdom`) + React Testing Library. Read `react-testing-library` skill for queries, async, and user events — this file covers Next.js-specific wiring only.

## Custom render

Wrap providers once; reuse across tests:

```tsx
// tests/setup/test-utils.tsx
import { render, type RenderOptions } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

function AllProviders({ children }: { children: React.ReactNode }) {
  return <>{children}</>; // extend: ThemeProvider, QueryClientProvider, etc.
}

function customRender(ui: React.ReactElement, options?: RenderOptions) {
  return {
    user: userEvent.setup(),
    ...render(ui, { wrapper: AllProviders, ...options }),
  };
}

export * from "@testing-library/react";
export { customRender as render };
```

Import from test-utils in tests, not `@testing-library/react` directly, when providers are required.

## Next.js navigation mocks

```ts
// tests/mocks/next-navigation.ts
import { vi } from "vitest";

export const mockPush = vi.fn();
export const mockReplace = vi.fn();

vi.mock("next/navigation", () => ({
  useRouter: () => ({
    push: mockPush,
    replace: mockReplace,
    prefetch: vi.fn(),
    back: vi.fn(),
  }),
  usePathname: () => "/",
  useSearchParams: () => new URLSearchParams(),
}));
```

Import this file at the top of tests that touch navigation, or register in `setupFiles`.

## next/image stub

```ts
// tests/setup/setupTests.ts
import { vi } from "vitest";

vi.mock("next/image", () => ({
  default: (props: React.ImgHTMLAttributes<HTMLImageElement>) => {
    // eslint-disable-next-line @next/next/no-img-element, jsx-a11y/alt-text
    return <img {...props} />;
  },
}));
```

## Server Components

Do not render Server Components in jsdom. Options:

1. Test the **client child** that receives serialized props
2. Extract **pure logic** (formatters, selectors) into `node` unit tests
3. Test **data loading** in `integration/data` or `integration/api` layers

## UI + API (component calls backend)

Prefer asserting **user-visible outcome** after interaction:

```tsx
import { http, HttpResponse } from "msw";
import { setupServer } from "msw/node";

const server = setupServer(
  http.get("/api/items", () => HttpResponse.json([{ id: "1", name: "Widget" }])),
);

beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());

test("lists items from API", async () => {
  const { user } = render(<ItemList />);
  expect(await screen.findByText("Widget")).toBeInTheDocument();
});
```

Alternative: `vi.spyOn(global, "fetch")` with a resolved `Response` — lighter weight, less realistic.

## File naming

- `*.test.tsx` for components
- Co-locate only if the project already does; otherwise `tests/integration/ui/`
