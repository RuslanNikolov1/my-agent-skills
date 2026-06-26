---
name: integration-tests
description: Orchestrates Vitest integration testing across UI (React Testing Library), Next.js route handlers, Supabase, and Sanity CMS. Invoke with /integration-tests when adding, fixing, or reviewing integration tests, test setup, or backend-connected component behavior. Delegates to vitest, react-testing-library, next-best-practices, supabase-work, and sanity-work skills — does not duplicate them.
disable-model-invocation: true
---

# Integration Tests

Orchestrator for writing and reviewing **integration tests** in Next.js apps. Reconciles the test runner (`vitest`), UI testing (`react-testing-library`), and backend surfaces (Next.js API routes, Supabase, Sanity).

The user invokes `/integration-tests` and describes what to test. Follow this pipeline in order.

## Pipeline overview

```
/integration-tests "…"
    → 0 scope & classify (required)
    → 0b capability check (required)
    → ① read delegated skills (required)
    → ② setup & conventions (if missing)
    → ③ write or fix tests
    → ④ verification-before-completion
```

**Escape hatch:** Failing or flaky tests → `systematic-debugging` before changing assertions or adding retries.

---

## Phase 0 — Scope & classify (required)

Announce: "Classifying integration test scope."

Answer before writing code:

1. **What behavior** is under test? (user flow, API contract, data layer, or combined)
2. **What is the SUT** (system under test)? List files/modules.
3. **What is real vs mocked?** Prefer mocking **boundaries** (network, DB, CMS), not internals.

### Test layer decision

| Layer | When | Environment | Primary skills |
|-------|------|-------------|----------------|
| **Unit** | Pure functions, validators, mappers | `node` | `vitest` |
| **UI integration** | Component behavior, forms, client interactions | `jsdom` | `vitest` + `react-testing-library` |
| **API integration** | Route handlers, webhooks, REST contracts | `node` | `vitest` + `next-best-practices` |
| **Data integration** | Queries, RLS, GROQ, repository layer | `node` | `vitest` + `supabase-work` or `sanity-work` |
| **UI + API** | Component calls your API; assert end-to-end in test env | `jsdom` + mocked `fetch`/handler | All UI refs + backend ref |

**Not integration tests (use other tools):**

- Full browser E2E (Playwright/Cypress) — real navigation, layout, multi-page flows
- Server Component render tests without user interaction — usually unit tests with mocked data loaders

Emit classification before Phase ①:

```
Integration test plan:
- Layer: <unit | ui | api | data | ui+api>
- SUT: <files>
- Real: <e.g. route handler logic>
- Mocked: <e.g. Supabase client, Sanity fetch>
- Delegated skills: <list>
- Reference: <link to references/*.md>
```

---

## Phase 0b — Capability check (required)

Announce: "Running integration test capability check."

Report:

```
Integration test capability check:
- vitest skill: available/missing
- react-testing-library skill: available/missing (needed for ui / ui+api)
- next-best-practices: available/missing (needed for route handlers, RSC boundaries)
- supabase-work skill + Supabase MCP: available/missing (if Supabase in SUT)
- sanity-work skill + Sanity MCP: available/missing (if Sanity in SUT)
- Project test setup: vitest.config / setupFiles / test-utils — present/missing
- Packages: @testing-library/react, jsdom, @testing-library/jest-dom — installed/missing
- Recommendation: <what to add before writing tests>
```

Do not silently proceed when required packages or config are missing. Propose concrete install/setup steps.

---

## Phase ① — Read delegated skills (required)

Read **only what the classification requires**. Do not load every skill on every run.

### Always (all layers)

| Skill | Path | Read |
|-------|------|------|
| `vitest` | `~/.agents/skills/vitest/SKILL.md` | Always; then topic refs below |

**Vitest topic refs by layer:**

| Layer | Topic files |
|-------|-------------|
| All | `core-test-api.md`, `core-expect.md`, `features-mocking.md` |
| UI / UI+API | `advanced-environments.md`, `advanced-projects.md` |
| API / Data | `advanced-environments.md` (use `node`) |

### UI integration (`ui`, `ui+api`)

| Skill | Path | Read |
|-------|------|------|
| `react-testing-library` | `~/.agents/skills/react-testing-library/SKILL.md` | Always for UI |
| RTL config | `references/config.md` | Vitest + jsdom setup |
| RTL queries / async | `references/queries.md`, `references/async.md` | When selecting elements or waiting |
| RTL user events | `references/user-events.md` | When simulating interaction |

Also read: [references/ui-integration.md](references/ui-integration.md)

### API integration (`api`, `ui+api`)

| Skill | Path | Read |
|-------|------|------|
| `next-best-practices` | `~/.agents/skills/next-best-practices/SKILL.md` | Route handler context |
| Route handlers | `route-handlers.md` | Handler shape, `params` as Promise |
| Async patterns | `async-patterns.md` | `cookies()`, `headers()`, `params` |

Also read: [references/next-api-routes.md](references/next-api-routes.md)

### Supabase (`data` or Supabase in SUT)

| Skill | Path | Read |
|-------|------|------|
| `supabase-work` | `~/.agents/skills/supabase-work/SKILL.md` | Local workflow + MCP |
| Postgres | `supabase-postgres-best-practices` (plugin) | Query/RLS-heavy tests |

Also read: [references/supabase.md](references/supabase.md)

### Sanity (`data` or Sanity in SUT)

| Skill | Path | Read |
|-------|------|------|
| `sanity-work` | `~/.agents/skills/sanity-work/SKILL.md` | Local workflow + MCP |
| GROQ / schema | `sanity-best-practices` (plugin) | When queries or types matter |

Also read: [references/sanity.md](references/sanity.md)

---

## Phase ② — Setup & conventions (if missing)

Skip if the project already has working Vitest + (when needed) RTL setup.

### Recommended project layout

```
tests/
├── unit/              # node env — optional, not this skill's focus
├── integration/
│   ├── ui/            # jsdom + RTL
│   ├── api/           # node — route handlers
│   └── data/          # node — repos, GROQ, Supabase clients
├── setup/
│   ├── setupTests.ts  # jest-dom, RTL configure, global mocks
│   └── test-utils.tsx # custom render + providers
└── mocks/
    ├── next-navigation.ts
    ├── supabase.ts
    └── sanity.ts
```

### Vitest projects (preferred for mixed layers)

```ts
// vitest.config.ts — see vitest advanced-projects.md
projects: [
  { test: { name: 'unit', include: ['tests/unit/**/*.test.ts'], environment: 'node' } },
  { test: { name: 'integration-ui', include: ['tests/integration/ui/**/*.test.tsx'], environment: 'jsdom', setupFiles: ['./tests/setup/setupTests.ts'] } },
  { test: { name: 'integration-api', include: ['tests/integration/api/**/*.test.ts'], environment: 'node' } },
  { test: { name: 'integration-data', include: ['tests/integration/data/**/*.test.ts'], environment: 'node' } },
]
```

Match **existing project conventions** when present — do not invent a second test folder structure.

### Global setup essentials

- `setupTests.ts`: `@testing-library/jest-dom`, RTL `configure()` if needed
- `afterEach(cleanup)` when Vitest `globals: false`
- Path aliases aligned with `tsconfig` / Vite `resolve.alias`

---

## Phase ③ — Write or fix tests

### Rules (all layers)

1. **One behavior per test** — clear Arrange / Act / Assert
2. **Mock at boundaries** — `vi.mock()` module level; use `vi.hoisted()` when mocks need shared state (see `vitest` `features-mocking.md`)
3. **No implementation-detail assertions** — for UI, follow RTL philosophy (roles, labels, visible outcomes)
4. **Stable async** — `findBy*` over `waitFor` + `getBy`; await `userEvent` (see RTL `async.md`)
5. **Next.js async APIs** — `params`, `searchParams`, `cookies()`, `headers()` are async in App Router; await them in tests and in code under test

### Layer-specific entry points

| Layer | Start here |
|-------|------------|
| UI | [references/ui-integration.md](references/ui-integration.md) |
| API | [references/next-api-routes.md](references/next-api-routes.md) |
| Supabase | [references/supabase.md](references/supabase.md) |
| Sanity | [references/sanity.md](references/sanity.md) |
| UI + API | UI ref + mock `fetch` to handler **or** MSW; assert UI outcome, not fetch call shape |

### Next.js boundaries in UI tests

- **`"use client"` components** — primary RTL targets
- **Server Components** — do not `render()` directly; test via client children, extracted pure helpers, or API/data layer
- **`next/navigation`** — mock `useRouter`, `usePathname`, `useSearchParams` in `tests/mocks/next-navigation.ts`
- **`next/image`** — stub to `<img>` in setup when needed

### Review checklist (fixing existing tests)

- [ ] Correct test layer and environment
- [ ] Mocks at module boundary, reset in `beforeEach` (`vi.clearAllMocks()`)
- [ ] RTL: `getByRole` / `getByLabelText` over `getByTestId`
- [ ] No flaky `waitFor` (side effects, multiple assertions)
- [ ] Route tests: `Request`/`Response` assertions, status codes, error paths
- [ ] Supabase/Sanity: not hitting production datasets

---

## Phase ④ — Verification

**Skill:** `verification-before-completion` (Superpowers)

Run targeted tests:

```bash
# Single file
npx vitest run path/to/test.test.tsx

# Project
npx vitest run --project integration-ui

# Watch while iterating
npx vitest --project integration-ui path/to/test.test.tsx
```

Report: command run, pass/fail, and what was not covered.

---

## Quick reference — skill delegation

```
/integration-tests
├── vitest              → runner, vi.mock, env, projects, coverage
├── react-testing-library → queries, userEvent, async, jsdom setup (UI only)
├── next-best-practices → route handlers, async server APIs (API / UI+API)
├── supabase-work       → client mocks, RLS, MCP for schema (Supabase SUT)
└── sanity-work          → client mocks, GROQ fixtures (Sanity SUT)
```

## Backend & UI reference files

| File | Use when |
|------|----------|
| [references/ui-integration.md](references/ui-integration.md) | Component integration, providers, Next.js client mocks |
| [references/next-api-routes.md](references/next-api-routes.md) | `route.ts` handlers, Request/Response |
| [references/supabase.md](references/supabase.md) | Supabase client, auth, RLS, server helpers |
| [references/sanity.md](references/sanity.md) | Sanity client, GROQ, preview/draft |
