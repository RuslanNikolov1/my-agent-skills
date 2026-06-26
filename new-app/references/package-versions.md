# Package versions (skill-pinned)

**Policy:** Before any `pnpm add`, read this file and the **enabled** delegated skill's `SKILL.md`, `metadata`, and `templates/package.json`. Use explicit pins when listed. Do **not** browse npm for latest unless no skill source defines a version.

Report resolved versions in Phase ② before scaffold.

## Core stack

| Package | Version | Source skill |
|---------|---------|--------------|
| `sass` | *(create-next-app default)* | `scss-best-practices` — no pin; add without `@` unless project already pins |
| `next-intl` | *(read skill)* | `next-intl-app-router` — no pin in skill; grep skill before install |

## Mandatory add-ons

| Package | Version | Source skill |
|---------|---------|--------------|
| `@tanstack/react-query` | *(read skill)* | `tanstack-query-best-practices` — no pin; install once, document in `bootstrap-config.md` |
| `@eslint/js` | `^9.0.0` | `eslint-prettier-config` |
| `@typescript-eslint/eslint-plugin` | `^7.0.0` | `eslint-prettier-config` |
| `@typescript-eslint/parser` | `^7.0.0` | `eslint-prettier-config` |
| `eslint` | `^9.0.0` | `eslint-prettier-config` |
| `eslint-config-prettier` | `^9.1.0` | `eslint-prettier-config` |
| `eslint-plugin-import` | `^2.29.0` | `eslint-prettier-config` |
| `eslint-plugin-react` | `^7.33.0` | `eslint-prettier-config` |
| `eslint-plugin-react-hooks` | `^4.6.0` | `eslint-prettier-config` |
| `eslint-plugin-react-refresh` | `^0.4.0` | `eslint-prettier-config` |
| `prettier` | `^3.2.0` | `eslint-prettier-config` |

## Conditional — forms

| Package | Version | Source skill |
|---------|---------|--------------|
| `react-hook-form` | `7.66.1` | `react-hook-form-zod` (Latest Versions header) |
| `zod` | `4.1.12` | `react-hook-form-zod` |
| `@hookform/resolvers` | `5.2.2` | `react-hook-form-zod` |

## Conditional — animations

| Package | Version | Source skill |
|---------|---------|--------------|
| `gsap` | `3.15.0` | `gsap-react` example (`gsap-skills` plugin) |
| `@gsap/react` | `2.1.2` | `gsap-react` example |

## Conditional — CMS (Sanity)

| Package | Version | Source skill |
|---------|---------|--------------|
| `sanity` | *(read plugin)* | `sanity-best-practices` — use `npm create sanity@latest` / `pnpm dlx`; grep `get-started.md` |
| `next-sanity` | `11+` | `sanity-best-practices` `nextjs.md` — requires v11+ for `defineLive` |
| `@sanity/client` | *(read plugin)* | `sanity-best-practices` `get-started.md` |
| `@sanity/image-url` | *(read plugin)* | same |
| `@portabletext/react` | *(read plugin)* | same |

## Conditional — database (Supabase)

| Package | Version | Source skill |
|---------|---------|--------------|
| `@supabase/supabase-js` | *(read plugin)* | plugin `supabase` — verify via `search_docs` before pin |
| `@supabase/ssr` | *(read plugin)* | plugin `supabase` — Next.js App Router SSR |

## Conditional — integration tests (when Supabase yes)

| Package | Version | Source skill |
|---------|---------|--------------|
| `vitest` | `3.x` | `vitest` skill (based on Vitest 3.x) |
| `@testing-library/react` | `16.3.2` | `react-testing-library` metadata |
| `@testing-library/dom` | *(with RTL)* | `react-testing-library` |
| `@testing-library/user-event` | *(read skill)* | `react-testing-library` — recommended |
| `@testing-library/jest-dom` | *(read skill)* | `react-testing-library` — recommended |
| `jsdom` | *(dev)* | `integration-tests` + `vitest` `advanced-environments.md` |

## Conditional — Shopify

| Package / tool | Version | Source skill |
|----------------|---------|--------------|
| `@shopify/cli` | `@latest` (global) | plugin `shopify-onboarding-dev` — verify with `shopify version` |
| Storefront API client | *(read plugin)* | `shopify-storefront-graphql` — no npm pin in skill |

## Radix (starter shell)

Install only primitives needed for the starter (and form shell if forms enabled). No global pin in `radix-ui-design-system` — document installed packages in `bootstrap-config.md`.
