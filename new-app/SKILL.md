---
name: new-app
description: Bootstrap a greenfield Next.js App Router app with TypeScript, SCSS modules, Radix UI, TanStack Query, ESLint/Prettier, and Vercel deployment. Invoke with /new-app. Asks app name, SEO, i18n, CMS (Sanity), database (Supabase), Shopify, animations (GSAP), and forms; always creates a public GitHub repo, switches to initial-work branch via GitHub MCP, and links a Vercel project via CLI; uses pnpm and skill-pinned package versions.
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
    → ⑥ github (GitHub MCP — repo + push main + branch initial-work)
    → ⑦ vercel (CLI — create project, link, connect Git, Next.js preset)
    → ⑧ handoff (/new-feature)
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

**Not asked — always included:** pnpm, TanStack Query (`tanstack-query-best-practices`), ESLint + Prettier (`eslint-prettier-config`), **Vercel project** (Phase ⑦ — CLI create + link + Git connect; same kebab-case name as the app), **public GitHub repo** (Phase ⑥ — same kebab-case name as the app, personal account unless the brief specifies an org), **`initial-work` branch** (Phase ⑥ — created from `main` after bootstrap push; workspace ends on `initial-work`).

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
· GitHub: public repo (mandatory — `<kebab-case>` on personal account)
· Active branch: initial-work (mandatory — created from main after bootstrap push)
· Data fetching: TanStack Query (mandatory)
· Lint/format: ESLint + Prettier (mandatory)
· Hosting: Vercel (Phase ⑦ — CLI project + GitHub link; production branch: `main`)
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

### 17. Vercel hosting prep (mandatory)

- Add `docs/vercel.md` or section in `bootstrap-config.md`: deployment target **Vercel**
- Document env vars required on Vercel (Sanity, Supabase, Shopify, SEO `metadataBase`, etc.) — list keys in `.env.local.example`; never commit `.env.local`
- Read `vercel-react-best-practices` for App Router + Vercel patterns when configuring build/output
- **Project creation and Git linking** run in **Phase ⑦** (after GitHub push) — do not tell the user to import the repo manually in the dashboard

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
- [ ] Vercel env/deployment notes in docs (Phase ④ step 17)
- [ ] `docs/bootstrap-config.md` records all discovery choices
- [ ] GitHub: public repo created via MCP; bootstrap pushed to `main`; `initial-work` on remote and checked out locally
- [ ] Active branch is `initial-work` (`git branch --show-current`)
- [ ] Vercel (Phase ⑦): project created/linked; GitHub connected; framework Next.js; production branch `main`

Fix failures before Phase ⑥. Vercel linking is verified in Phase ⑦.

---

## Phase ⑥ — GitHub (mandatory)

**MCP server:** `user-github` — read tool schemas under `mcps/user-github/tools/` before calling.

Always create a **public** GitHub repo named after the app's kebab-case package name. Do **not** ask the user whether they want a repo.

### Capability check

1. Confirm **GitHub MCP** is available (`create_repository`, `create_branch`, `get_me`; optionally `list_branches`).
2. Call **`get_me`** to resolve the authenticated user (and org only if specified in the brief).
3. If MCP is missing or auth fails, **stop and tell the user** what to configure — do not proceed silently.

### Create repository

Use **`create_repository`** with:

| Field | Value |
|-------|--------|
| `name` | Kebab-case package name from discovery (same as app name), e.g. `my-app` |
| `description` | Optional one-line from the user's brief |
| `private` | **`false`** — always public |
| `organization` | Omit for personal account; set only when the brief specifies an org |
| `autoInit` | **`false`** — local scaffold is the source of truth; do not let GitHub seed a README |

If the repo name already exists, report the conflict and ask whether to use a different name — do not skip GitHub setup unless creation is impossible.

### Connect local repo and push

After Phase ⑤ passes:

1. Ensure `.env.local` is **not** staged (only `.env.local.example` and project files).
2. Create the **initial commit** (required — exception to optional-commit handoff rule):

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

### Create and switch to `initial-work`

After `main` is pushed, create the working branch and switch the workspace to it. Do **not** ask the user — always use branch name **`initial-work`**.

**Preferred — GitHub MCP:**

1. Call **`create_branch`** with:
   - `owner` / `repo` from `create_repository` response or `git remote get-url origin`
   - `branch`: `initial-work`
   - `from_branch`: `main`
2. Check out locally (updates Cursor's branch indicator — there is no separate Cursor branch API):

```bash
git fetch origin
git checkout initial-work
git branch -u origin/initial-work
```

Use **`list_branches`** first if `initial-work` may already exist on the remote.

**Fallback — MCP unavailable:**

```bash
git checkout -b initial-work
git push -u origin initial-work
```

**Verify checkout** before Phase ⑦:

```bash
git branch --show-current   # must print: initial-work
```

If checkout fails (dirty tree, name conflict), stop and report — do **not** proceed to Vercel setup or handoff on `main`.

4. Record in `docs/bootstrap-config.md` under **GitHub**:
   - Repo URL
   - Default branch: `main` (bootstrap baseline)
   - Active branch: `initial-work`

**Do not** force-push. **Do not** commit secrets.

---

## Phase ⑦ — Vercel (mandatory)

**Skills:** `vercel-cli`, `env-vars` — read before running commands.

**Tooling note:** The Vercel MCP server does **not** expose project creation, Git linking, or env-var management. Use the **Vercel CLI** (and REST API for framework preset only). Run from the **project root** after Phase ⑥ has pushed to GitHub.

### Capability check

1. Confirm CLI auth: `vercel whoami`. If it fails, **stop** and tell the user to run `vercel login` (device flow — cannot complete unattended).
2. Resolve **team scope**: `vercel teams ls`. Use the team from the brief; if only one team exists, use it; if none, omit `--scope` (personal account).
3. If `.vercel/project.json` already exists and points at the correct project, skip create/link — verify Git connection and framework instead.

### Create and link project

Use the **kebab-case package name** from discovery (same as GitHub repo name).

```bash
# 1) Create empty Vercel project (skip if it already exists — use vercel projects ls)
vercel project add <kebab-case-name> --scope <team-slug>

# 2) Link local directory (creates .vercel/project.json; may pull dev env vars to .env.local)
vercel link --yes --project <kebab-case-name> --scope <team-slug>

# 3) Connect GitHub (use origin URL from git remote)
vercel git connect https://github.com/<owner>/<kebab-case-name>.git --scope <team-slug>
```

**Expected local side effects:** `.vercel/` (gitignored), `.env.local` (gitignored), `.gitignore` entries for `.vercel` and `.env*.local`. Do **not** commit `.env.local`.

### Project settings

| Setting | Value |
|---------|--------|
| **Project name** | Kebab-case app name (same as GitHub repo) |
| **Framework preset** | **Next.js** (`nextjs`) |
| **Root directory** | `./` (default — `null` in API) |
| **Production branch** | **`main`** (matches Phase ⑥ `git branch -M main`) |

**Framework preset:** The CLI has no `vercel project add --framework` flag. After link, set Next.js via REST API:

```bash
# Read teamId from .vercel/project.json (orgId) — do not echo tokens in output
curl -sS -X PATCH "https://api.vercel.com/v9/projects/<kebab-case-name>?teamId=<orgId>" \
  -H "Authorization: Bearer <token-from-vercel-auth>" \
  -H "Content-Type: application/json" \
  -d '{"framework":"nextjs","rootDirectory":null}'
```

Obtain the bearer token from the local Vercel CLI auth file (e.g. `%APPDATA%/com.vercel.cli/Data/auth.json` on Windows, `~/.local/share/com.vercel.cli/auth.json` on Linux). **Never** print or commit the token.

**Production branch:** `vercel git connect` sets `productionBranch` from the GitHub repo’s default branch. Because Phase ⑥ renames to **`main`** before push, production should be **`main`**. Verify:

```bash
vercel project inspect <kebab-case-name> --scope <team-slug>
```

If the remote default branch differs (e.g. still `master`), either fix GitHub’s default branch to `main` or update production branch in the Vercel dashboard (no officially documented CLI for this).

### Environment variables (optional at bootstrap)

Push vars from `.env.local.example` when the user supplies values:

```bash
echo "<value>" | vercel env add <KEY> production preview development --scope <team-slug>
vercel env update <KEY> production   # to change an existing value
vercel env pull .env.local --yes     # sync cloud → local after dashboard/CLI changes
```

See `env-vars` skill for scoping rules. Never echo secret values in logs.

### Verify

```bash
vercel project inspect <kebab-case-name> --scope <team-slug>
```

Confirm: **Framework Preset: Next.js**, **Root Directory: .**, Git repo connected, production branch **`main`**.

### Record in docs

Add to `docs/bootstrap-config.md` and/or `docs/vercel.md` under **Vercel**:

- Team name and slug
- Project name and ID (`prj_…` from `.vercel/project.json`)
- Dashboard URL: `https://vercel.com/<team-slug>/<kebab-case-name>`
- Production branch: `main`
- Framework: Next.js
- Env vars still needed on Vercel (from `.env.local.example`)

**Do not** force-push. **Do not** commit secrets or `.env.local`.

---

## Phase ⑧ — Handoff

Tell the user:

> Bootstrap complete on **pnpm**, deployed to **Vercel**. Use **`/new-feature`** to add UI — it detects **i18n**, **SEO profile**, **Sanity**, **Supabase**, and **Shopify** from project setup. Data fetching: **TanStack Query**. Integration tests: ready if Supabase was enabled.

Include:

- **GitHub repo URL**
- **Vercel project URL** (dashboard)
- Bootstrap pushed to **`main`**; Vercel production deploys from **`main`**
- **You are now on `initial-work`** — continue with `/new-feature` from this branch

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
- [ ] Vercel — env docs + deployment notes (Phase ④ step 17, mandatory)
- [ ] GitHub — MCP create_repository + push main + create_branch initial-work + checkout (Phase ⑥, mandatory)
- [ ] Vercel — CLI project add + link + git connect + Next.js preset (Phase ⑦, mandatory)
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
