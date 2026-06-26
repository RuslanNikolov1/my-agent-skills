---
name: new-app
description: Bootstrap a greenfield Next.js App Router app with TypeScript, SCSS modules, Radix UI, TanStack Query, ESLint/Prettier, and Vercel deployment. Invoke with /new-app. Asks app name, SEO, i18n, CMS (Sanity), database (Supabase), Shopify, animations (GSAP), forms, and GitHub repo preferences; uses pnpm, skill-pinned package versions, and GitHub MCP when enabled.
disable-model-invocation: true
---

# New App

Orchestrator for bootstrapping a greenfield **Next.js + TypeScript + SCSS modules** app with Radix UI, TanStack Query, and a growable design system. **Hosting target: Vercel.** **Package manager: pnpm only.**

The user invokes `/new-app` and describes the app (name, purpose, or target folder). Follow this pipeline in order — **do not scaffold until Phase ① discovery is complete**.

## Pipeline overview

```
/new-app "…"
    → 0 preflight (directory + git)
    → ① discovery (required questions — one at a time)
    → ② package versions (from skills — not browser/npm latest)
    → ③ scaffold (create-next-app + pnpm)
    → ④ domain setup (stack skills in order)
    → ⑤ verification
    → ⑥ github (conditional — GitHub MCP)
    → ⑦ handoff (/new-feature)
```

**Escape hatch:** If setup fails, use `systematic-debugging` before retrying installs or config changes.

**Package manager rule:** Use **`pnpm` only** — `pnpm dlx`, `pnpm add`, `pnpm run`, `pnpm exec`. Never `npm` or `yarn`. Replace any create-next-app/npm examples in delegated skills with pnpm equivalents.

---

## Phase 0 — Preflight

1. Confirm **target directory** — empty folder, new repo root, or user-specified path. Stop if the directory has unrelated code unless the user explicitly wants to adopt/overwrite.
2. **Git:** init if missing (`git init`); do not commit secrets or `.env.local`.
3. Announce workspace path before Phase ①.

---

## Phase ① — Discovery (required)

Announce: "I'm gathering bootstrap preferences before scaffolding."

Ask **one question per message**. Wait for each answer before the next question.

**First question (always):** *"What do you want to name the app?"* — capture the human-readable name; derive the npm `package.json` name as kebab-case unless the user specifies otherwise.

### Question order

| # | Question | If yes / choice |
|---|----------|-----------------|
| 1 | **App name:** What do you want to call this app? | Used for display title, `package.json` `name` (normalize to kebab-case, e.g. `My App` → `my-app`), and docs. If the user already gave a name in the brief, confirm it rather than re-ask. |
| 2 | **Target directory:** Where should we scaffold the project? | Confirm folder path (empty dir, new repo root, or parent + app name). Skip if already clear from Phase 0 preflight or the brief. |
| 3 | **SEO:** Should this app be built for search indexing (public marketing/content site)? | Yes → Phase ④ runs `nextjs-seo` bootstrap. Also ask for **production site URL** (e.g. `https://example.com`) for `metadataBase`. No → skip SEO files. |
| 4 | **i18n:** Do you want locale-based routing? | Yes → ask **which locales** (e.g. `en`, `ja`, `zh-CN`). No → single-locale app. |
| 5 | **Responsive strategy:** **Mobile-first** or **desktop-first**? | Mobile-first (recommended) → min-width breakpoints. Desktop-first → document max-width pattern; still enforce 44×44px touch targets. |
| 6 | **CMS:** Do you want a headless CMS (**Sanity**)? | Yes → Phase ④ runs `sanity-work` bootstrap (embedded Studio, client, env vars). No → skip Sanity. |
| 7 | **Database:** Do you want **Supabase** (Postgres, auth, storage)? | Yes → Phase ④ runs `supabase-work` bootstrap **and** integration-test scaffolding via `integration-tests`. No → skip Supabase and test setup. |
| 8 | **Animations:** Do you want **GSAP** set up? | Yes → Phase ④ runs `gsap` / `gsap-react` (client provider pattern, `useGSAP`, reduced-motion note). No → skip. |
| 9 | **Forms:** Do you want form validation wired (**React Hook Form + Zod**)? | Yes → Phase ④ runs `react-hook-form-zod` with Radix-friendly patterns from `radix-ui-design-system`. No → skip form deps; defer to `/new-feature`. |
| 10 | **Shopify:** Do you want **Shopify** integration? | Yes → ask **App** (embedded admin app) or **Storefront** (headless commerce on this Next.js site). Phase ④ runs `shopify-work` bootstrap. No → skip Shopify. |
| 11 | **GitHub:** Create a repo on your GitHub account with the **same name as the app** (kebab-case package name)? | Yes → ask **private** (default) or **public**; optionally ask **organization** (omit for personal account). Phase ⑥ uses **GitHub MCP** (`create_repository`, `get_me`). No → skip GitHub; local git only. |

**Not asked — always included:** pnpm, TanStack Query (`tanstack-query-best-practices`), ESLint + Prettier (`eslint-prettier-config`), Vercel deployment notes.

### Discovery summary (emit before Phase ③)

After all answers, post a short summary and wait for confirmation:

```
Bootstrap config:
· App name: <display name> (package: <kebab-case>)
· Directory: <path>
· Package manager: pnpm (mandatory)
· SEO: yes (metadataBase: …) | no
· i18n: yes (locales: …) | no
· Responsive: mobile-first | desktop-first
· CMS (Sanity): yes | no
· Database (Supabase): yes | no
· Integration tests: yes (with Supabase) | no
· Animations (GSAP): yes | no
· Forms (RHF + Zod): yes | no
· Shopify: yes (app | storefront) | no
· GitHub: yes (private | public, org: … | personal) | no
· Data fetching: TanStack Query (mandatory)
· Lint/format: ESLint + Prettier (mandatory)
· Hosting: Vercel
· Stack: Next.js App Router, TypeScript (strict), SCSS modules, Radix UI, design-system template
```

**HARD GATE:** Do not run `create-next-app`, install packages, or write app code until the user confirms this summary.

Save choices to `docs/bootstrap-config.md` in Phase ④ (after scaffold).

### Cross-stack compatibility guardrails

Apply this lightweight guardrail pass after discovery confirmation and before Phase ③:

- **Data ownership map (required):** Record one canonical owner per domain in `docs/bootstrap-config.md` (e.g. content → Sanity, commerce → Shopify, auth/app data → Supabase when enabled). Avoid dual ownership unless explicit sync requirements are documented.
- **State ownership (required):** Default stack — no Redux, Zustand, or global Context skills. Prefer in order: **URL params** (`nuqs` when filters/view/pagination are shareable) → **TanStack Query** (server/async data + cache) → **local `useState`/`useReducer`** (isolated UI toggles, e.g. map vs list) → **React Hook Form** (form field state). Use **Context** only for provider wiring (Query provider, theme shell) — not for app/business data. Reach for **Zustand** only when many unrelated client components need the same client-only UI state and URL/Query is not a fit; document the reason in `docs/bootstrap-config.md` if added.
- **RSC boundary policy (required):** Keep App Router defaults server-first. Limit `"use client"` to interactive islands (Query provider, forms, animation wrappers, etc.).
- **Shopify + stack fit (conditional):** If Shopify is enabled, confirm **Storefront** vs **App** path and document repo strategy. For App mode, default to separate app surface (`apps/shopify/` or separate repo) unless user explicitly wants same-repo coupling.
- **i18n + SEO coupling (conditional):** If both are enabled, ship localized metadata, `alternates.languages`, and sitemap locale URLs together.
- **Supabase security baseline (conditional):** Apply only when Supabase is enabled. Never expose service role keys, use SSR-safe client setup, and document expected RLS/auth boundaries.
- **Verification matrix (required):** In Phase ⑤, verify only enabled stacks (e.g. Sanity+Shopify projects skip Supabase/integration-test checks; Supabase projects include integration tests).

---

## Phase ② — Package versions (from skills)

Announce: "I'm resolving package versions from delegated skills."

1. Read [references/package-versions.md](references/package-versions.md).
2. For each **enabled** conditional stack item, read that skill's `SKILL.md` (and `templates/package.json` if present) for pins.
3. Do **not** use browser/npm "latest" lookup — skill pins win.

Report once:

```
Versions (from skills):
· pnpm: <project manager>
· <package>: <version or "skill — no pin">
· …
```

---

## Phase ③ — Scaffold

**Skill:** `next-best-practices` — read `file-conventions.md` before choosing flags.

### create-next-app

From the target directory (or parent with project name):

```bash
pnpm dlx create-next-app@latest <project-dir> --typescript --eslint --app --src-dir --import-alias "@/*" --no-tailwind --turbopack --use-pnpm --yes
```

Adjust flags if the directory is `.` and already empty.

### Immediate post-scaffold

```bash
pnpm add sass
```

Do **not** add Tailwind unless the user explicitly requests it — this stack uses **SCSS modules**.

---

## Phase ④ — Domain setup

Apply skills **in this order**. Read each skill's `SKILL.md` before its step. Use **pnpm** and **Phase ②** versions for every install.

### 1. Architecture — `next-best-practices`

Path: `~/.agents/skills/next-best-practices/SKILL.md`

- Validate App Router structure under `src/app/`
- Root `layout.tsx`, `page.tsx`, colocated route files
- If **i18n:** plan move to `src/app/[locale]/…` before wiring pages (step 9)
- Read `async-patterns.md` if using Next.js 15+ param APIs in stubs

### 2. TypeScript — `typescript-pro`

Path: `~/.agents/skills/typescript-pro/SKILL.md`

- Enable **strict** compiler options in `tsconfig.json`
- Prefer interfaces, `as const` maps over enums, explicit public API types where stubs exist
- Run `pnpm exec tsc --noEmit` after config changes

### 3. ESLint + Prettier — `eslint-prettier-config` (mandatory)

Path: `~/.agents/skills/eslint-prettier-config/SKILL.md`

- Replace or extend create-next-app ESLint with flat config (`eslint.config.mjs`) per skill
- Add `.prettierrc`, `.prettierignore`
- Install devDeps at versions from [references/package-versions.md](references/package-versions.md)
- Add scripts: `lint`, `lint:fix`, `format`, `format:check`
- Optional: Husky + lint-staged only if user asks

### 4. SCSS — `scss-best-practices`

Path: `~/.agents/skills/scss-best-practices/SKILL.md`

- Rename/adapt `globals.css` → `globals.scss`; import from root layout
- Colocated `*.module.scss` pattern for components
- Use `@use` / `@forward`, not deprecated `@import`

### 5. Design system template — `design-system`

Path: `~/.agents/skills/design-system/SKILL.md`

Bootstrap a **minimal** system — populated later via `/new-feature`:

```
src/
├── styles/
│   └── tokens.css
├── app/
│   └── globals.scss
└── components/
    └── ui/
docs/
└── bootstrap-config.md
```

- Record discovery answers + responsive strategy in `docs/bootstrap-config.md`
- Do **not** auto-emit `design.md` — note *"Say `lock the system` (Hallmark) when ready"*

### 6. Responsive strategy — `responsive-design`

Path: `~/.agents/skills/responsive-design/SKILL.md`

- Mobile-first or desktop-first per discovery; breakpoint tokens in `tokens.css`
- Read `references/details.md` only if layout breakpoints need worked examples

### 7. Radix UI — `radix-ui-design-system` (mandatory)

Path: `~/.agents/skills/radix-ui-design-system/SKILL.md`

- Install starter primitives (`@radix-ui/react-slot`, etc.)
- One minimal shared component (e.g. `components/ui/button/`) as the pattern for `/new-feature`
- SCSS modules + CSS variables from `tokens.css` — no Tailwind

### 8. TanStack Query — `tanstack-query-best-practices` (mandatory)

Path: `~/.agents/skills/tanstack-query-best-practices/SKILL.md`

- `pnpm add @tanstack/react-query` (version from Phase ②)
- Client `QueryClientProvider` wrapper (e.g. `src/components/providers/query-provider.tsx`)
- Wire provider in root or locale layout
- Read `rules/ssr-dehydration.md` if using RSC + prefetch/hydration on Vercel
- Document query-key factory location for `/new-feature`

### 9. i18n — `next-intl-app-router` (conditional)

**When:** Discovery **i18n: yes**.

Path: `~/.agents/skills/next-intl-app-router/SKILL.md`

- `messages/<locale>.json`, `src/i18n/*`, `src/app/[locale]/…`
- Defer hreflang/localised SEO → step 10 when SEO also enabled

### 10. SEO — `nextjs-seo` (conditional)

**When:** Discovery **SEO: yes**.

Path: `~/.agents/skills/nextjs-seo/SKILL.md`

- `metadataBase`, `sitemap.ts`, `robots.ts`, starter `generateMetadata`
- With **i18n + SEO:** `references/next-intl-seo.md`

### 11. CMS — `sanity-work` (conditional)

**When:** Discovery **CMS: yes**.

Path: `~/.agents/skills/sanity-work/SKILL.md`

1. Run **Sanity capability check** (MCP + plugin skills).
2. Read plugin `sanity-best-practices` — `references/nextjs.md`, `get-started.md`.
3. **Embedded Studio** (recommended): `src/app/studio/[[...tool]]/page.tsx`, root `sanity.config.ts`, `src/sanity/lib/client.ts`, `live.ts` with `defineLive` (next-sanity v11+).
4. Env vars in `.env.local.example`: `NEXT_PUBLIC_SANITY_PROJECT_ID`, `NEXT_PUBLIC_SANITY_DATASET`, `SANITY_API_READ_TOKEN`.
5. Render `<SanityLive />` in root layout per plugin docs.
6. Do **not** proceed silently if Sanity MCP/skills missing — tell user what to install.

### 12. Database — `supabase-work` (conditional)

**When:** Discovery **Database: yes**.

Path: `~/.agents/skills/supabase-work/SKILL.md`

1. Run **Supabase capability check** (MCP + plugin `supabase`, `supabase-postgres-best-practices`).
2. Read plugin `supabase` skill for current Next.js App Router SSR pattern before install.
3. `pnpm add @supabase/supabase-js @supabase/ssr` (pins from Phase ② / plugin docs).
4. `src/lib/supabase/server.ts`, `client.ts`, middleware cookie refresh if auth expected.
5. `.env.local.example`: `NEXT_PUBLIC_SUPABASE_URL`, publishable/anon key — never commit secrets.
6. Enable RLS on new tables (plugin security checklist).

### 13. Integration tests — `integration-tests` (conditional)

**When:** Discovery **Database (Supabase): yes**.

Path: `~/.agents/skills/integration-tests/SKILL.md`

- Apply Phase ② **integration test** packages (Vitest 3.x, RTL 16.3.2, jsdom, jest-dom, user-event)
- Layout per skill: `tests/integration/`, `tests/setup/setupTests.ts`, `tests/mocks/supabase.ts`
- `vitest.config.ts` with projects (`integration-ui`, `integration-api`, `integration-data`) when mixed layers
- One smoke test proving Vitest runs (e.g. `tests/integration/api/health.test.ts`)
- Read `references/supabase.md` for client mocks — do not hit production DB in tests

**Skip** when Supabase: no.

### 14. Animations — `gsap` (conditional)

**When:** Discovery **Animations: yes**.

Path: `~/.agents/skills/gsap/SKILL.md` → plugin **`gsap-react`**

```bash
pnpm add gsap@3.15.0 @gsap/react@2.1.2
```

- `"use client"` animation shell component with `useGSAP` + cleanup
- Register plugins only when needed (`gsap-scrolltrigger` skill if scroll-driven)
- Respect `prefers-reduced-motion` (`gsap-performance`)

### 15. Forms — `react-hook-form-zod` (conditional)

**When:** Discovery **Forms: yes**.

Path: `~/.agents/skills/react-hook-form-zod/SKILL.md`

```bash
pnpm add react-hook-form@7.66.1 zod@4.1.12 @hookform/resolvers@5.2.2
```

- Starter schema + form component using `zodResolver`, `defaultValues`, accessible errors
- Radix primitives for custom controls via `Controller` — defer a11y to `radix-ui-design-system`
- Optional: `@radix-ui/react-label` for form shell

### 16. Shopify — `shopify-work` (conditional)

**When:** Discovery **Shopify: yes**.

Path: `~/.agents/skills/shopify-work/SKILL.md`

1. Run **Shopify capability check** (plugin skills + `shopify version`).
2. Read plugin **`shopify-onboarding-dev`** for CLI prerequisites (`pnpm add -g @shopify/cli@latest` or global install per skill — verify with `shopify version`).
3. Record **Shopify type** in `docs/bootstrap-config.md`: **app** or **storefront**.

**Storefront** (headless commerce on this Next.js app):

- Read plugin **`shopify-storefront-graphql`** for Storefront API patterns
- Add `src/lib/shopify/storefront-client.ts` (or equivalent) stub
- `.env.local.example`: `SHOPIFY_STORE_DOMAIN`, `SHOPIFY_STOREFRONT_ACCESS_TOKEN` (server-only unless using public token pattern documented by Shopify)
- Document cart/product fetching via **TanStack Query** in bootstrap notes for `/new-feature`
- Do **not** use Hydrogen scaffold — stay on Next.js App Router

**App** (embedded Shopify admin app):

- Read plugin **`shopify-polaris-app-home`** for embedded admin UI patterns
- Read **`shopify-use-shopify-cli`** for `shopify.app.toml` validation and CLI workflows
- Shopify CLI often scaffolds **Remix** — do **not** replace the Next.js app. Options:
  - Document app setup in `docs/shopify-app.md` and plan a future `apps/shopify/` or separate repo, **or**
  - Proceed only if user confirms merging Shopify app config into this repo after reading trade-offs
- `.env.local.example`: Shopify app credentials per CLI output (`SHOPIFY_API_KEY`, etc.) — never commit secrets

4. Do **not** proceed silently if plugin skills or CLI are missing — tell user what to install.

**Skip** when Shopify: no.

### 17. Vercel hosting (mandatory)

- Add `docs/vercel.md` or section in `bootstrap-config.md`: deployment target **Vercel**
- Document env vars required on Vercel (Sanity, Supabase, Shopify, SEO `metadataBase`, etc.)
- `.env.local.example` lists all bootstrap env vars; never commit `.env.local`
- Read `vercel-react-best-practices` for App Router + Vercel patterns when configuring build/output
- Note: when **GitHub** is enabled, import the new repo in the Vercel dashboard; otherwise link the local repo after first push. No secrets in git.

---

## Phase ⑤ — Verification

Run fresh commands and show output — no "done" without evidence:

```bash
pnpm run lint
pnpm exec tsc --noEmit
pnpm run build
```

If **Supabase yes** (integration tests):

```bash
pnpm exec vitest run
```

Checklist:

- [ ] pnpm only — no `package-lock.json` / `yarn.lock` unless user explicitly overrides
- [ ] App Router structure valid (`next-best-practices`)
- [ ] ESLint + Prettier configured and `pnpm run lint` passes
- [ ] Strict TypeScript passes
- [ ] SCSS compiles; globals + one module import works
- [ ] Radix starter component renders
- [ ] TanStack Query provider wraps app; dev build succeeds
- [ ] i18n (if yes): each locale route loads
- [ ] SEO (if yes): `metadataBase`, sitemap, robots present
- [ ] Sanity (if yes): capability check passed; client + env example present
- [ ] Supabase (if yes): capability check passed; SSR clients + env example present
- [ ] Integration tests (if Supabase): Vitest config + smoke test passes
- [ ] GSAP (if yes): client animation shell with cleanup
- [ ] Forms (if yes): pinned RHF/Zod deps; starter form compiles
- [ ] Shopify (if yes): capability check passed; storefront client or app docs + env example present
- [ ] Vercel env/deployment notes in docs
- [ ] `docs/bootstrap-config.md` records all discovery choices
- [ ] GitHub (if yes): repo created via MCP; remote configured; bootstrap pushed

Fix failures before Phase ⑥.

---

## Phase ⑥ — GitHub (conditional)

**When:** Discovery **GitHub: yes**.

**MCP server:** `user-github` — read tool schemas under `mcps/user-github/tools/` before calling.

### Capability check

1. Confirm **GitHub MCP** is available (`create_repository`, `get_me`).
2. Call **`get_me`** to resolve the authenticated user (and org if applicable).
3. If MCP is missing or auth fails, **stop and tell the user** what to configure — do not proceed silently.

### Create repository

Use **`create_repository`** with:

| Field | Value |
|-------|--------|
| `name` | Kebab-case package name from discovery (same as app name), e.g. `my-app` |
| `description` | Optional one-line from the user's brief |
| `private` | Per discovery (`true` default) |
| `organization` | Omit for personal account; set when user chose an org |
| `autoInit` | **`false`** — local scaffold is the source of truth; do not let GitHub seed a README |

If the repo name already exists, report the conflict and ask whether to use a different name or skip GitHub setup.

### Connect local repo and push

After Phase ⑤ passes:

1. Ensure `.env.local` is **not** staged (only `.env.local.example` and project files).
2. Create the **initial commit** (required when GitHub is enabled — exception to optional-commit handoff rule):

```bash
git add .
git commit -m "$(cat <<'EOF'
chore: bootstrap Next.js app

EOF
)"
```

3. Add remote from `create_repository` response URL (or `https://github.com/<owner>/<name>.git`):

```bash
git remote add origin <repo-url>
git branch -M main
git push -u origin main
```

4. Record repo URL in `docs/bootstrap-config.md` under **GitHub**.

**Do not** force-push. **Do not** commit secrets.

Skip this entire phase when GitHub: no.

---

## Phase ⑦ — Handoff

Tell the user:

> Bootstrap complete on **pnpm**, targeting **Vercel**. Use **`/new-feature`** to add UI — it detects **i18n**, **SEO profile**, **Sanity**, **Supabase**, and **Shopify** from project setup. Data fetching: **TanStack Query**. Integration tests: ready if Supabase was enabled.

If **GitHub** was enabled, include the repo URL and confirm the initial push succeeded.

If GitHub was skipped, optional initial commit only if the user asks.

---

## Domain checklist (copy for Phase ④)

```text
Bootstrap checklist:
- [ ] next-best-practices — App Router structure
- [ ] typescript-pro — strict tsconfig
- [ ] eslint-prettier-config — flat ESLint + Prettier (mandatory)
- [ ] scss-best-practices — globals.scss, @use modules
- [ ] design-system — tokens.css, components/ui/, bootstrap-config.md
- [ ] responsive-design — mobile-first | desktop-first
- [ ] radix-ui-design-system — starter primitive (mandatory)
- [ ] tanstack-query-best-practices — QueryClientProvider (mandatory)
- [ ] next-intl-app-router — if i18n yes
- [ ] nextjs-seo — if SEO yes
- [ ] sanity-work — if CMS yes
- [ ] supabase-work — if database yes
- [ ] integration-tests — if Supabase yes
- [ ] gsap — if animations yes
- [ ] react-hook-form-zod — if forms yes (+ radix-ui-design-system)
- [ ] shopify-work — if Shopify yes (app | storefront)
- [ ] Vercel — env docs + deployment notes (mandatory)
- [ ] GitHub — if yes: MCP create_repository + remote + initial push (Phase ⑥)
```

---

## Boundaries

| Topic | Defer to |
|-------|----------|
| Feature UI after bootstrap | `new-feature` |
| Visual voice, `design.md` lock | `hallmark` |
| Feature-level SEO on internal routes | `new-feature` |
| Copy translation quality | `translation-guidelines` |
| Performance tuning | `performance-optimizer` / `vercel-react-best-practices` |
| E2E browser verification | `browser-review` (optional) |
| Writing/fixing tests beyond bootstrap scaffold | `integration-tests` |

---

## Superpowers skills NOT in this pipeline

Use separately when needed:

- `brainstorming` — optional if app concept is ambiguous before discovery
- `writing-plans` — non-trivial custom bootstrap variants
- `verification-before-completion` — Phase ⑤ follows the same spirit
