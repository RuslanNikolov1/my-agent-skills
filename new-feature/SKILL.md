---
name: new-feature
description: Use when building a new UI feature end-to-end. Invoke with /new-feature and describe the feature. Pipeline — feature branch, brainstorming, writing-plans, subagent-driven-development, verification, browser-review, code review, finish branch. Domain skills — next-best-practices, vercel-react-best-practices, hallmark, design-system, scss-best-practices, responsive-design, loading-skeletons, radix-ui-design-system; conditional — browser-review (UI features), react-hook-form-zod (forms), next-intl-app-router + translation-guidelines (i18n apps), nextjs-seo (indexable routes), tanstack-query-best-practices (client server state), zustand-state-management (client UI state when URL/Query/local/RHF insufficient), sanity-work (CMS-backed content), supabase-work (database/auth/storage), shopify-work (Shopify storefront/app APIs), gsap (animations), integration-tests (data-layer behavior), typescript-pro (non-trivial domain types).
disable-model-invocation: true
---

# New Feature

Orchestrator for building a new UI feature in a Next.js + TypeScript + SASS modules app.

The user invokes `/new-feature` and describes what to build. Follow this pipeline in order — do not skip phases or write code before design approval.

## Pipeline overview

```
/new-feature "…"
    → 0 feature branch (required)
    → 0b capability check (required when new tech is involved)
    → ① brainstorming (design + approval)
    → ② using-git-worktrees (optional)
    → ③ writing-plans
    → ④ subagent-driven-development (+ domain skills per task)
    → ⑤ verification-before-completion
    → ⑤b browser-review (conditional — UI features)
    → ⑥ requesting-code-review
```

**Escape hatch:** If a bug appears during implementation, pause and use `systematic-debugging` before proposing fixes.

---

## Phase 0 — Feature branch (required)

Create a dedicated feature branch **before** brainstorming or any file writes. All work for this feature — design docs, plans, and code — happens on that branch.

Announce: "Creating feature branch for this work."

### Branch naming

Derive from the feature brief: `feature/<kebab-case-slug>` (e.g. `feature/settings-filters`). Keep it short and unique. If the user supplies a branch name, use it.

### Preconditions

1. Confirm the workspace is a git repository (`git rev-parse --show-toplevel`).
2. Identify the default branch (`main` or `master` — detect from remote or `git symbolic-ref refs/remotes/origin/HEAD`).
3. **Never** implement on `main`/`master` without explicit user consent.

If not a git repo, stop and ask whether to init git or proceed without branching.

### Create and checkout

**Already on the correct feature branch?** Confirm with the user and skip creation.

**Otherwise:**

1. Stash or commit unrelated local changes, or stop and ask if the working tree is dirty with unrelated work.
2. Update the base branch: `git fetch origin` then checkout default and `git pull --ff-only` (when a remote exists).
3. Create the feature branch and check it out locally:

   **Preferred — GitHub remote + MCP available:** Use `user-github` MCP `create_branch` (read tool schema first):

   - Resolve `owner` / `repo` from `git remote get-url origin` or `gh repo view --json nameWithOwner`
   - `from_branch`: default branch
   - `branch`: `feature/<slug>`
   - Then locally: `git fetch origin && git checkout feature/<slug>`

   Use `list_branches` first if the branch may already exist on the remote.

   **Fallback — local git only:**

   ```bash
   git checkout -b feature/<slug>
   ```

   **Push tracking branch** (when remote exists, after first commit or immediately if team expects remote branch early):

   ```bash
   git push -u origin feature/<slug>
   ```

   Prefer MCP `create_branch` when the repo is on GitHub — it creates the remote branch explicitly; local `git push -u` is the fallback when MCP is unavailable.

### Report

Emit once before Phase ①:

```
Feature branch: feature/<slug>
Base: main @ <short-sha>
Workspace: on branch feature/<slug>
```

Phase ② (`using-git-worktrees`) remains optional — use it for an **isolated worktree** of this same feature branch when the main workspace is dirty or parallel work is in progress. Do not skip Phase 0 because a worktree might follow later.

---

## Phase 0b — Capability check (required for new technology)

Before brainstorming, detect whether the feature introduces a technology, platform, API, or workflow not already covered by the current stack conventions.

If yes, run a short capability discovery pass and report:

- Relevant skills to use for this feature
- Relevant MCP servers/tools
- Relevant plugins/skills packages
- What is already available vs missing

Read `docs/bootstrap-config.md` when present to see what **`/new-app`** enabled (Sanity, Supabase, Shopify, TanStack Query, etc.) — then narrow skills to what **this feature** actually needs (frontend-only features ignore unused profiles).

Announce: "I'm running a capability check for this feature's technology."

### What to output

Provide a concise capability report to the user:

```
Capability check:
- Technology: <name>
- Skills: <available list> | Missing: <missing list or none>
- MCP: <available servers/tools> | Missing/not configured: <missing list or none>
- Plugins: <available list> | Missing/not installed: <missing list or none>
- Recommendation: <what to add before implementation, if anything>
```

### Behavior rules

1. **Do not silently proceed** when important capability gaps exist. Tell the user exactly what is missing.
2. If nothing is missing, explicitly say so and continue to Phase ①.
3. If gaps exist, propose concrete additions first (skills, MCP, plugins), then wait for user confirmation when setup/auth/install is required.
4. Keep this phase lightweight — discovery and recommendation only, no feature implementation yet.

---

## Phase ① — Brainstorming

**Skill:** `brainstorming` (Superpowers)

Announce: "I'm using the brainstorming skill to explore this feature."

Follow the skill fully:

- Explore project context (files, patterns, recent work)
- Detect **conditional skills early**: forms in the brief? `next-intl` / `[locale]` routing in the repo? new indexable public route? non-trivial domain types, state machines, permissions, or typed server/client contracts? **CMS/database/animation/data-fetching** — only when the **feature** touches those layers (see bootstrap profiles below; frontend-only features skip backend skills)
- Ask clarifying questions **one at a time**
- Propose 2–3 approaches with trade-offs
- Present design sections; get user approval before proceeding
- Save design doc to `docs/superpowers/specs/YYYY-MM-DD-<feature-name>-design.md`

**HARD GATE:** Do NOT read implementation skills, write code, or scaffold until the user approves the design.

Hallmark applies during design — use `hallmark` for layout, structure, and anti-slop decisions in the spec (not generic hero → 3-cards → CTA unless the brief calls for it).

**Design system growth — `design-system`:** After Hallmark-informed layout decisions, run Step 0 (system inventory) and add a **System impact** section to the feature spec — reuse vs extend vs add shared tokens/components. Do not write feature-local colors or one-off primitives when the shared layer can grow instead.

**Project SEO profile:** Detect once during brainstorming (from bootstrap or existing setup). Strong profile when **two or more** exist:

- `metadataBase` in root layout
- `app/sitemap.ts` (or sitemap route)
- `app/robots.ts`
- `generateMetadata` / `alternates` on existing public routes
- `application/ld+json` or structured-data helpers

Initial app bootstrap with **`/new-app`** or `nextjs-seo` typically creates this profile — `/new-feature` treats it as durable project intent, not something to re-decide per feature.

**Index intent (inferred, documented in spec):** For each new URL, record **Index intent: yes / no / inherited** in the design doc. Do **not** ask the user separately unless ambiguous.

| Situation | Index intent | `nextjs-seo` |
|-----------|--------------|--------------|
| SEO profile + new public route (outside admin/auth/noindex groups) | **yes** (default) | Apply automatically |
| Route under layout with `robots: { index: false }`, admin, auth, dashboard | **no** | Skip |
| Component/modal on existing page, no new URL | **inherited** | Skip unless page metadata changes |
| No SEO profile yet + first public marketing/content route | **yes** | Apply (establish patterns) |
| Ambiguous (e.g. `/tools/foo` could be public or app-only) | — | Ask **one** clarifying question |

When index intent is **yes**, planning and implementation include `nextjs-seo` tasks without extra approval — same as i18n keys auto-apply when `next-intl` is present.

**Project bootstrap profile:** Detect once during brainstorming. Read `docs/bootstrap-config.md` when present (from **`/new-app`**). Confirm from the repo:

| Profile | Detect |
|---------|--------|
| **Sanity CMS** | `sanity.config.ts`, `src/sanity/`, `next-sanity` in `package.json`, bootstrap **CMS: yes** |
| **Supabase** | `@supabase/ssr` or `@supabase/supabase-js`, `src/lib/supabase/`, bootstrap **Database: yes** |
| **Shopify** | `src/lib/shopify/`, Shopify env vars, bootstrap **Shopify: yes (app \| storefront)** |
| **TanStack Query** | `@tanstack/react-query`, `QueryClientProvider` (or project provider wrapper), bootstrap notes |
| **GSAP** | `gsap`, `@gsap/react` in `package.json`, bootstrap **Animations: yes** |
| **Forms stack** | `react-hook-form` + `zod` in `package.json`, bootstrap **Forms: yes** |
| **Integration tests** | `vitest.config.*`, `tests/integration/`, bootstrap **Integration tests: yes** (usually with Supabase) |

A profile means the **project is set up** for that stack — not that every feature uses it.

**Data layer intent (inferred, documented in spec):** Record per feature which layers this work touches:

```
Data layer intent: none | sanity | supabase | shopify | sanity+supabase | …
Client server state: none | tanstack-query | rsc-only
Client UI state: none | url | local | zustand
Animations: none | gsap
```

Do **not** ask the user separately unless the brief is ambiguous (e.g. "settings page" could be static or DB-backed).

| Situation | Apply | Skip |
|-----------|-------|------|
| Profile present + feature loads/edits CMS content, schemas, or Studio | `sanity-work` | Static/marketing UI with hardcoded copy; layout-only; no GROQ |
| Profile present + feature reads/writes DB, auth, storage, RLS | `supabase-work` | Frontend-only UI; no persistence; mock data in component only |
| Profile present + feature uses Storefront/Admin Shopify APIs (products, cart, app UI) | `shopify-work` | Static UI; no commerce data; layout-only on existing templates |
| Profile present + feature uses client fetch/mutations/cache | `tanstack-query-best-practices` | Pure RSC + Server Actions with no client cache; static pages |
| Feature needs cross-route client UI state; URL (`nuqs`), TanStack Query, local state, and RHF are insufficient | `zustand-state-management` | Shareable filters/view/pagination (use `nuqs`); server data (use Query); page toggles (local state); forms (RHF); auth (Supabase when enabled) |
| Profile present + feature adds motion/scroll animation | `gsap` | No animation in scope |
| Supabase profile + feature changes queries/RLS/API contracts | `integration-tests` (add/fix tests) | Frontend-only; no data layer change |
| Basic UI (card, modal, nav, static section) on a bootstrapped app | Core domain skills only | All backend/animation skills above |

**Default for ambiguous briefs:** Assume **frontend-only** until the spec explicitly needs CMS, database, Shopify, or client server state — same spirit as skipping `nextjs-seo` for internal routes.

---

## Phase ② — Git worktree (optional)

**Skill:** `using-git-worktrees` (Superpowers)

Use when the feature is non-trivial or the current workspace is dirty. Skip for small, scoped changes in a clean repo. Assumes Phase 0 already created the feature branch — the worktree checks out **that** branch, not a new name.

Announce when used: "I'm using the using-git-worktrees skill to set up an isolated workspace."

---

## Phase ③ — Writing plans

**Skill:** `writing-plans` (Superpowers)

Announce: "I'm using the writing-plans skill to create the implementation plan."

- Turn the approved design into a bite-sized task plan
- Save to `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
- Each task: one action, 2–5 minutes, self-contained
- Map files to create/modify before decomposing tasks

**Domain skills inform the plan** — read each skill's `SKILL.md` and relevant topic files while planning.

During planning, detect **conditional** skills (see below) and add them to the checklist.

```
Domain checklist (apply during planning + every implementation task):
- [ ] Architecture — next-best-practices (+ vercel-react-best-practices CRITICAL/HIGH)
- [ ] Good UI — hallmark
- [ ] Design system — design-system (tokens, shared components, design.md compatibility)
- [ ] SASS — scss-best-practices
- [ ] Responsiveness — responsive-design
- [ ] Loading skeleton — loading-skeletons
- [ ] Accessibility — radix-ui-design-system
- [ ] Browser review — browser-review (if feature has UI surface)
- [ ] Forms — react-hook-form-zod (if feature includes forms)
- [ ] i18n routing — next-intl-app-router (if app uses next-intl)
- [ ] i18n copy — translation-guidelines (if app uses next-intl and new strings)
- [ ] SEO — nextjs-seo (if feature adds indexable route or page metadata)
- [ ] Client server state — tanstack-query-best-practices (if feature uses queries/mutations/cache)
- [ ] Client UI state — zustand-state-management (if URL/Query/local/RHF cannot own the state)
- [ ] CMS — sanity-work (if feature reads/writes Sanity content or schema)
- [ ] Database — supabase-work (if feature touches Supabase data/auth/storage)
- [ ] Shopify — shopify-work (if feature touches Storefront/Admin Shopify APIs)
- [ ] Animations — gsap (if feature adds GSAP motion)
- [ ] Integration tests — integration-tests (if feature changes Supabase/data contracts)
- [ ] TypeScript — typescript-pro (if feature has non-trivial domain types or typed contracts)
```

### Domain skill reference

**Architecture — `next-best-practices`** (`~/.agents/skills/next-best-practices/SKILL.md`)

Read relevant topic files: `data-patterns.md`, `rsc-boundaries.md`, `file-conventions.md`, `async-patterns.md`, `error-handling.md`, `suspense-boundaries.md`.

Then apply `vercel-react-best-practices` CRITICAL/HIGH rules (`async-`, `bundle-`, `server-` prefixes). Correctness wins on conflict.

**Good UI — `hallmark`** · **Design system — `design-system`** · **SASS — `scss-best-practices`** · **Responsiveness — `responsive-design`** · **Loading skeleton — `loading-skeletons`** · **Accessibility — `radix-ui-design-system`**

Paths: `~/.agents/skills/<skill-name>/SKILL.md`

**Design system — `design-system`**

Path: `~/.agents/skills/design-system/SKILL.md`

- Run Step 0 inventory during brainstorming; add **System impact** to the feature spec
- During planning: explicit tasks for token extensions and new shared components
- During implementation: tokens → shared primitives → feature UI (never fork one-off styles)
- Respects Hallmark's `design.md` / `tokens.css` model — defers visual voice to `hallmark`
- Amend `design.md` `## Components` on locked systems; never auto-emit or overwrite `design.md`

### Conditional — Forms (`react-hook-form-zod`)

**When:** The feature creates or significantly changes a form (contact, signup, booking, filters with submit, multi-step wizards, admin inputs).

**Skip when:** No user input beyond links/buttons, or read-only UI.

Path: `~/.agents/skills/react-hook-form-zod/SKILL.md`

- Zod schemas, `zodResolver`, field wiring, server validation
- Read `references/` for shadcn integration, nested fields, error handling as needed
- Forms built on Radix still defer component a11y to `radix-ui-design-system`; this skill owns schema + resolver + submit flow
- Triggers **conditional TDD** — always use TDD for form validation logic

### Conditional — i18n (app has next-intl)

**When:** The project uses i18n. Detect by checking for `next-intl` in `package.json`, `i18n/` or `messages/` dirs, `[locale]` route segments, or `next-intl` plugin in `next.config`.

If i18n is present, apply **both** skills:

**1. Routing & messages — `next-intl-app-router`**

Path: `~/.agents/skills/next-intl-app-router/SKILL.md`

- Locale routing, middleware/proxy, message files, `useTranslations`, dates/numbers/plurals, language switcher
- New routes go under `[locale]`; new copy keys in all locale message files
- Defer hreflang, localised metadata/sitemap → `nextjs-seo`

**2. Copy quality — `translation-guidelines`**

Path: `~/.agents/skills/translation-guidelines/SKILL.md`

- Use when adding or translating human-readable strings for each locale
- Natural, fluent target language — not word-for-word
- Translate only human-readable text inside JSX/JSON; never code, keys, URLs, or identifiers

**Skip both** when the app is single-locale with no `next-intl` setup.

### Conditional — SEO (`nextjs-seo`)

**When:** The feature adds or materially changes a **public, indexable route** or page-level metadata (title, description, OG, canonical, JSON-LD, sitemap/hreflang entries).

**Project SEO profile (bootstrap / existing setup):** Scan during brainstorming. A profile from initial `nextjs-seo` bootstrap means SEO is a project default — new public routes get metadata, sitemap, and related wiring **automatically** during `/new-feature`, following existing patterns.

**Detect feature need (primary gate — inference first):**

1. **Auto yes:** SEO profile present + new `page.tsx` in a public segment (not admin/auth/noindex groups)
2. **Auto yes:** Brief mentions landing page, blog, docs, marketing, product/content pages
3. **Auto yes:** New locale URLs on an i18n + SEO site (hreflang/sitemap updates)
4. **Auto no:** Internal/auth-only UI; no new route; inherits parent metadata
5. **Ask once:** Only when route placement or indexability is genuinely ambiguous

**Detect project conventions (how deep to go):** reuse patterns from the profile:

- `app/sitemap.ts`, `app/robots.ts`, `metadataBase`, sibling `generateMetadata`, JSON-LD helpers
- No sitemap/robots yet but index intent yes → add minimal metadata; extend sitemap/robots if the feature is the first public page

**Skip when:** Index intent **no** or **inherited** (see table in Phase ①).

Path: `~/.agents/skills/nextjs-seo/SKILL.md`

- `generateMetadata`, canonical, OG/Twitter, JSON-LD matching visible content
- Update `app/sitemap.ts` / `app/robots.ts` when the project uses them
- With i18n: localised metadata, `alternates.languages` (hreflang), locale URLs in sitemap — `next-intl-app-router` owns routing/messages only
- Read `references/` as needed (metadata-api, json-ld, sitemap-robots, next-intl-seo, checklist)
- **Allowed surface:** metadata, structured data, semantic HTML, internal links, alt text, sitemap/robots — not visual redesign or layout
- During planning: explicit tasks for metadata, sitemap/hreflang/JSON-LD for each URL with inferred **Index intent: yes**

### Conditional — TanStack Query (`tanstack-query-best-practices`)

**When:** The feature uses **client-side server state** — `useQuery`, `useMutation`, prefetch/hydration, cache invalidation, optimistic updates.

**Auto yes:**

- Client components fetch from API/Supabase/Sanity via hooks
- Mutations with cache updates or invalidation
- Infinite scroll / paginated client lists backed by server data

**Auto no:**

- Pure Server Components with `fetch` or server loaders only
- Static UI with no async client data
- Server Actions only, no client cache layer

**Project profile:** `@tanstack/react-query` from **`/new-app`** means the stack is available — apply this skill only when the **feature** needs client server state, not on every page.

Path: `~/.agents/skills/tanstack-query-best-practices/SKILL.md`

- Query keys (hierarchical factories), staleTime/gcTime, targeted invalidation after mutations
- Read `rules/ssr-dehydration.md` when prefetching on server for client islands
- Prefer RSC for initial data when sufficient; add Query only where interactivity/cache warrants it

**Skip when:** Data layer intent is **rsc-only** or **none** for client server state.

### Conditional — Client UI state (`zustand-state-management`)

**When:** Cross-route **client-only UI state** cannot be owned by the default stack — URL params (`nuqs`), TanStack Query, local `useState`/`useReducer`, or React Hook Form.

**Decision order (required before invoking):** Confirm each step is insufficient:

1. **URL / `nuqs`** — shareable filters, view mode, pagination, sort
2. **TanStack Query** — server/async data, cache, mutations (not client UI prefs)
3. **Local state** — single-page toggles (e.g. map vs list on one route)
4. **RHF** — form field state
5. **Context** — provider wiring only (Query provider, etc.) — not business/UI store data

**Auto yes:**

- Same client UI state must persist across many unrelated routes/components and prop drilling or lifted state becomes unwieldy
- Client-only preferences/shell state (e.g. panel layout, tool mode) that should not live in URL or server cache
- Spec documents **Client UI state: zustand** after the decision order above

**Auto no:**

- Shareable search/filter/view state → `nuqs`
- API/Supabase/Sanity/Shopify data → TanStack Query or RSC
- Map vs list, modals, tabs on one page → local state
- Form inputs → RHF + Zod
- Auth session → Supabase SSR/client helpers when enabled
- Default marketing/content/feature UI on bootstrapped apps

Path: `~/.agents/skills/zustand-state-management/SKILL.md`

- Client Components only; separate store per domain; selector subscriptions
- SSR hydration for persisted stores; never store server/auth secrets in Zustand when Supabase owns auth
- **Do not** duplicate server state — Query remains source of truth for remote data
- Install with **pnpm** (`pnpm add zustand`) — not bun/npm unless project overrides
- Record store ownership and why URL/Query/local were rejected in the feature spec

**Skip when:** Client UI state intent is **none**, **url**, or **local**.

### Conditional — CMS (`sanity-work`)

**When:** The feature loads or edits **Sanity content** — GROQ queries, Portable Text, page-builder blocks, schema types, draft/preview, or Studio config.

**Auto yes:**

- Brief mentions CMS-driven pages, blog, page builder, content types
- New `sanityFetch` / GROQ / schema / Studio route work

**Auto no:**

- Marketing section with hardcoded JSX copy
- UI shell, navigation, modals, settings layout with no CMS fetch
- Component styling or layout-only work on an existing CMS page template

**Project profile:** Sanity from **`/new-app`** means MCP, client, and Studio exist — use **`sanity-work`** only when this feature touches that layer.

Path: `~/.agents/skills/sanity-work/SKILL.md`

- Run Sanity capability check; read plugin `sanity-best-practices` for GROQ/schema
- `get_schema` before content queries when using Sanity MCP
- Defer SEO on CMS routes to `nextjs-seo`; defer copy translation to `translation-guidelines`

**Skip when:** Data layer intent excludes **sanity**.

### Conditional — Database (`supabase-work`)

**When:** The feature reads/writes **Supabase** — tables, RLS, auth session, storage uploads, realtime, edge functions.

**Auto yes:**

- Brief mentions login, user data, CRUD, dashboards backed by Postgres
- New Server Actions or route handlers calling Supabase client

**Auto no:**

- Static or client-only UI with no persistence
- Mock data in components for prototyping (unless spec says wire DB later — then plan Supabase task explicitly)

**Project profile:** Supabase from **`/new-app`** means SSR clients and env vars exist — use **`supabase-work`** only when this feature touches the database layer.

Path: `~/.agents/skills/supabase-work/SKILL.md`

- Run Supabase capability check; read plugin `supabase` for auth/SSR patterns
- Apply `supabase-postgres-best-practices` for queries and RLS
- Never expose service role in client code

**Skip when:** Data layer intent excludes **supabase**.

### Conditional — Shopify (`shopify-work`)

**When:** The feature touches **Shopify** — Storefront GraphQL (products, cart, checkout), Admin API, embedded app surfaces, metafields/metaobjects, or CLI config.

**Auto yes:**

- Brief mentions products, cart, collection, checkout, Shopify app, Polaris admin UI
- New Storefront or Admin GraphQL queries/mutations

**Auto no:**

- Generic marketing UI with no commerce data
- Navigation, modals, settings shell with no Shopify API calls
- Styling-only changes on pages that already fetch products unchanged

**Project profile:** Shopify from **`/new-app`** means CLI/docs and client stubs exist — use **`shopify-work`** only when this feature touches Shopify APIs.

Path: `~/.agents/skills/shopify-work/SKILL.md`

- Run Shopify capability check; route to plugin skill by task (`shopify-storefront-graphql`, `shopify-admin`, `shopify-polaris-app-home`, `shopify-use-shopify-cli`)
- Follow plugin search/validate workflows when generating GraphQL
- Defer client cache patterns to `tanstack-query-best-practices` when using hooks

**Skip when:** Data layer intent excludes **shopify**.

### Conditional — Integration tests (`integration-tests`)

**When:** The feature **changes Supabase or API data behavior** and the project has Vitest integration setup from bootstrap.

**Auto yes:**

- New/changed route handlers, repositories, RLS-sensitive queries, auth flows
- Regression-prone data mapping or server-side validation

**Auto no:**

- Frontend-only UI (most `/new-feature` work)
- Visual/layout changes on pages that already load data unchanged

Path: `~/.agents/skills/integration-tests/SKILL.md`

- Classify layer (ui / api / data); mock at boundaries per skill
- Use existing `tests/mocks/supabase.ts` when present

**Skip when:** No Supabase/data contract change, or frontend-only feature.

### Conditional — Animations (`gsap`)

**When:** The feature adds or changes **GSAP** motion — timelines, scroll triggers, enter/exit animations.

**Auto yes:** Brief mentions animate, scroll reveal, stagger, timeline, motion design.

**Auto no:** Static UI, CSS-only transitions sufficient, no motion in scope.

Path: `~/.agents/skills/gsap/SKILL.md` → plugin **`gsap-react`**

- `useGSAP`, cleanup, `prefers-reduced-motion`
- Add `gsap-scrolltrigger` skill only for scroll-driven behavior

**Skip when:** Animations intent is **none**.

**Conditional TDD — `test-driven-development` (Superpowers)**

Use TDD when the feature has non-trivial **behavior or logic**:

- Forms, validation, filters, search
- Server Actions, API routes, auth checks
- Client state machines, URL param sync
- Any regression-prone business rules

**Skip TDD** for purely visual/marketing UI (static sections, typography, layout-only changes) unless the project already tests components.

When TDD applies, embed red-green-refactor steps in the plan tasks.

### Conditional — TypeScript (`typescript-pro`)

**When:** The feature has non-trivial type modeling beyond basic props and Zod form schemas.

**Auto yes:**

- Branded domain IDs (user, order, tenant, resource slugs used as typed identifiers)
- Client or server state machines (wizard steps, upload/checkout flows, async request lifecycle)
- Permission or role matrices with exhaustive handling
- Server Actions, route handlers, or shared modules with typed inputs/outputs reused across routes
- Multi-step flows where step transitions must be type-safe
- Exported utilities or hooks consumed by other features (public API surface)

**Auto no:**

- Static marketing or layout-only UI with straightforward prop shapes
- Simple CRUD where Zod + inferred types from `react-hook-form-zod` cover all input typing
- Read-only pages with no shared domain model

**Ask once:** Only when the brief implies domain complexity but route placement or data shape is genuinely ambiguous.

Path: `~/.agents/skills/typescript-pro/SKILL.md`

- Design types first: branded types, discriminated unions, type guards, custom utility types
- Read `references/` as needed (`type-guards.md`, `advanced-types.md`, `utility-types.md`, `patterns.md`)
- Explicit return types on public APIs; use `satisfies` for config/objects; prefer const objects over enums
- Defer form field schemas to `react-hook-form-zod`; this skill owns domain modeling and cross-layer contracts
- Often pairs with **conditional TDD** — type guards and state transitions are good TDD candidates
- During planning: explicit tasks for shared `types/` modules, guards, and union exhaustiveness before UI wiring

**Skip when:** Visual-only feature or simple props — `next-best-practices` strict TypeScript defaults are sufficient.

### Conditional — Browser review (`browser-review`)

**When:** The feature adds or changes visible UI.

**Skip when:** Backend-only or config-only with no layout/interaction change.

Path: `~/.agents/skills/browser-review/SKILL.md`

- During planning: list target URLs and critical flows to exercise in Phase ⑤b
- Runs after lint/build/test pass; uses `cursor-ide-browser` MCP
- Snapshot + screenshot at 375px and 1280px; exercise forms, dialogs, filters from spec

### Stack guardrails (for `/new-app` profiles)

Apply these guardrails when the project was bootstrapped with `/new-app` (or has equivalent setup):

- **RSC/client boundary:** Keep `"use client"` islands minimal. Do not pass non-serializable props from Server Components, and do not place async logic directly in client components.
- **Single data owner per feature:** Choose one canonical owner for each domain surface (Sanity vs Supabase vs Shopify). Avoid duplicating the same business entity across systems unless the spec explicitly defines sync ownership.
- **State ownership:** No Redux/global Context/Zustand by default. Prefer: **URL params** (`nuqs` for shareable filters, view mode, pagination) → **TanStack Query** (server data/cache) → **local state** (page toggles like map vs list) → **RHF** (forms). Context only for provider wiring. If all four are insufficient, invoke **`zustand-state-management`** and document **Client UI state: zustand** in the spec with the rejection rationale.
- **TanStack Query discipline:** Use stable query key factories, define invalidation strategy for every mutation, and skip Query when pure RSC + Server Actions are sufficient.
- **i18n + SEO coupling:** For indexable localized routes, implement metadata + `alternates.languages` + sitemap entries together (not piecemeal).
- **Supabase safety:** Never expose service-role keys to client bundles. Use SSR/client helpers from `supabase-work`, and call out expected RLS behavior in the spec when auth-gated data is involved.
- **Design system growth path:** Extend tokens first, then shared primitives, then feature-level SCSS modules. Avoid one-off colors/spacing values when a token can represent the decision.
- **Form contracts:** When a form persists data, mirror client schema checks with server-side validation. Treat client validation as UX only, not trust boundary.
- **GSAP containment:** Keep GSAP in small client wrappers, ensure cleanup on unmount, and require `prefers-reduced-motion` fallback behavior.
- **Verification strictness:** For UI features, do not skip lint + typecheck + build + browser review; for data-contract changes, include targeted integration tests.

---

## Phase ④ — Subagent-driven development

**Skill:** `subagent-driven-development` (Superpowers)

Announce: "I'm using the subagent-driven-development skill to implement this plan."

- Execute the plan task-by-task (fresh subagent per task when Task tool is available)
- Two-stage review after each task: spec compliance, then code quality
- Apply domain skills on every task — **core skills always**; conditional skills (forms, i18n, SEO, TanStack Query, Zustand, Sanity, Supabase, Shopify, GSAP, integration-tests, typescript-pro) **only when this feature's data layer intent requires them**
- If TDD applies to a task, follow `test-driven-development` for that task
- Follow `subagent-driven-development` model selection and escalation rules

**Implementation order per task:**

1. Route structure (+ `[locale]` segment if i18n)
2. Domain types and typed contracts (`typescript-pro`, when applicable — before data layer and client state)
3. Server data layer — Sanity GROQ/fetchers (`sanity-work`), Supabase queries/actions (`supabase-work`), Shopify Storefront/Admin (`shopify-work`), or generic fetchers/Server Actions (when applicable)
4. Client server state — TanStack Query hooks, keys, mutations (`tanstack-query-best-practices`, when applicable — not for pure RSC features)
5. Client UI state — Zustand stores (`zustand-state-management`, when applicable — only after URL/Query/local/RHF ruled out)
6. Server components and client islands
7. UI structure and content (hallmark)
8. Design system layer — token extensions and shared components (`design-system`)
9. Forms if applicable (`react-hook-form-zod` + Radix a11y)
10. i18n message keys and translations (`next-intl-app-router`, then `translation-guidelines` for copy)
11. SEO — metadata, canonical, structured data, sitemap/hreflang updates (`nextjs-seo`, if indexable route)
12. Animations if applicable (`gsap` / `gsap-react`)
13. SASS modules (scss-best-practices)
14. Responsive behavior (responsive-design)
15. Loading skeletons (loading-skeletons)
16. Radix primitives and a11y polish (radix-ui-design-system)
17. Integration tests if data contracts changed (`integration-tests`, when applicable)

**Blockers:** Stop and ask the user if the plan has gaps, tests fail repeatedly, or requirements are unclear.

---

## Phase ⑤ — Verification before completion

**Skill:** `verification-before-completion` (Superpowers)

Announce before any "done" claim.

Run fresh verification commands (lint, build, test — whatever the project uses). Show evidence in output. No completion claims without command output.

### Linting and formatting gates (required when configured)

In this phase, explicitly check for and run the project's lint/format verification commands.

1. **ESLint/lint:** Run project lint command (`npm run lint`, `pnpm lint`, `yarn lint`, etc.) when configured.
2. **Prettier format check:** Run `format:check` or `prettier --check` when configured.
3. **If only auto-format exists:** If the repo has `prettier --write` (or `format`) but no check script, run it, then re-run lint and relevant tests.
4. **If not configured:** Explicitly report "lint not configured" and/or "prettier check not configured" in verification output.

Do not silently skip lint/format checks when scripts/configs exist.

### Type checking gate (required for TypeScript projects)

1. **`tsc --noEmit`:** Run when the project has TypeScript configured (`tsconfig.json` present). Use the project's script if one exists (`npm run typecheck`, `check-types`, etc.); otherwise run `npx tsc --noEmit`.
2. **`type-coverage`:** Run when the project configures it **and** `typescript-pro` applied during this feature — validate new public APIs have explicit return types.
3. **If not configured:** Report "tsc check: ran `tsc --noEmit`" or "TypeScript not configured" in verification output.

Do not claim Phase ⑤ complete while `tsc --noEmit` reports errors.

### Browser review (conditional — UI features)

**Skill:** `browser-review`

**When:** The feature adds or changes visible UI (routes, components, layouts, forms, modals, interactive states).

**Skip when:** Backend-only, config-only, or no runnable dev server and user declines to start one.

**Order:** Run **after** lint/build/test pass, **before** claiming Phase ⑤ complete or proceeding to Phase ⑥.

Announce: "I'm using the browser-review skill to verify UI in the browser."

Path: `~/.agents/skills/browser-review/SKILL.md`

- Start or confirm dev server; navigate to every feature route (`[locale]` prefix if i18n)
- Snapshot + screenshot at 375px and 1280px minimum
- Exercise critical flows from the approved spec (forms, dialogs, filters)
- Emit structured browser review report with evidence; fix failures and re-check

**Domain checklist:**

- [ ] RSC boundaries valid (no async client, serializable props)
- [ ] No avoidable waterfalls (`Promise.all`, Suspense where appropriate)
- [ ] SASS modules colocated, no inline style sprawl
- [ ] Works mobile-first; narrow and wide layouts considered
- [ ] Loading states present for async UI
- [ ] Keyboard navigable; focus visible; labels on inputs
- [ ] No generic AI-slop layout unless brief requested it
- [ ] Design system: new tokens in canonical source; shared components not feature-forked; design.md consistent (if locked)
- [ ] Forms: schema validation, server-side check, accessible labels/errors (if forms)
- [ ] i18n: keys in all locales, routing under `[locale]`, natural translations (if i18n app)
- [ ] SEO (if indexable route): unique title/description, canonical, correct index intent, sitemap/hreflang/JSON-LD when project uses them
- [ ] TanStack Query (if client server state): stable query keys, invalidation after mutations, no duplicate fetch waterfalls
- [ ] Zustand (if client UI state): invoked only after URL/Query/local/RHF ruled out; client islands only; no server/auth data duplication; hydration handled for persisted stores
- [ ] Sanity (if CMS feature): GROQ/types aligned with schema; no silent MCP/schema skips
- [ ] Supabase (if database feature): RLS respected; SSR client pattern; no secrets in client bundle
- [ ] Shopify (if commerce feature): correct API (Storefront vs Admin); validated GraphQL when plugin requires; tokens server-side
- [ ] GSAP (if animations): cleanup on unmount; reduced-motion respected
- [ ] Integration tests (if data layer changed): targeted Vitest run passes
- [ ] TypeScript (if `typescript-pro` applied): domain types centralized; discriminated unions exhaustive; public APIs typed; `tsc --noEmit` clean
- [ ] Browser review: snapshots/screenshots at mobile + desktop; critical flows exercised (if UI feature)

---

## Phase ⑥ — Requesting code review

**Skill:** `requesting-code-review` (Superpowers)

After verification passes, dispatch the `code-reviewer` subagent with plan + git SHAs.

Review early — catch issues before merge.

---

## Boundaries

| Topic | Defer to |
|-------|----------|
| Bootstrap new Next.js app (SEO/i18n/CMS/Supabase/Shopify/design-system template) | `new-app` |
| CMS content, GROQ, Sanity schema/Studio (when feature uses CMS) | `sanity-work` (conditional — see Phase ③) |
| Database, auth, storage, RLS (when feature uses Supabase) | `supabase-work` (conditional — see Phase ③) |
| Storefront/Admin Shopify APIs (when feature uses Shopify) | `shopify-work` (conditional — see Phase ③) |
| Client fetch/cache/mutations (when feature needs client server state) | `tanstack-query-best-practices` (conditional) |
| Cross-route client UI state when URL/Query/local/RHF insufficient | `zustand-state-management` (conditional — see Phase ③) |
| GSAP motion (when feature includes animation) | `gsap` (conditional) |
| Vitest integration tests for data/API changes | `integration-tests` (conditional) |
| SEO during new indexable routes (metadata, hreflang, sitemap) | `nextjs-seo` (conditional — see Phase ③) |
| Form validation logic gaps (post-build audit) | `edge-cases` |
| Empty/error edge states (post-build audit) | `edge-cases` |
| Slow page diagnosis | `performance-optimizer` |
| Bug during build | `systematic-debugging` |
| Feedback on review comments | `receiving-code-review` |
| Harden existing feature | `improve-feature` |
| Lock/portable design system (`design.md`, multi-format exports) | `hallmark` (`lock the system`) |
| Grow tokens/components during feature work | `design-system` |
| In-browser UI verification (layout, flows, viewports) | `browser-review` |
| Domain types, branded IDs, state machines, typed server/client contracts | `typescript-pro` (conditional — see Phase ③) |
| tsconfig, project references, monorepo type architecture | `typescript-pro` |
| Formal WCAG scan / cross-browser matrix | BrowserStack accessibility / web test skills |

## Superpowers skills NOT in this pipeline

Use separately when needed — not part of `/new-feature` happy path:

- `executing-plans` — use `subagent-driven-development` instead (Cursor has subagents)
- `dispatching-parallel-agents` — covered by subagent-driven-development
- `using-superpowers`, `writing-skills` — meta skills
