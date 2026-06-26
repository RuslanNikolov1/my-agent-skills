---
name: edge-cases
description: >-
  Audits and fixes logic edge cases in Next.js marketing/CMS/Supabase apps —
  null/empty states, async races, form validation gaps, CMS field guards, i18n
  fallbacks, URL/state desync, and animation lifecycle issues. Use when the user
  invokes edge-cases or asks to review/fix missed edge cases. Defers form
  implementation to react-hook-form-zod, security to security-audit, accessibility
  to radix-ui-design-system, and responsiveness to responsive-design.
disable-model-invocation: true
---

# Edge Cases

Systematic review skill for **logic gaps** in the apps Ruslan builds: marketing sites, CMS-driven sites, and Supabase-backed Next.js apps.

**Default behaviour: audit and fix.** Find missed edge cases, then implement fixes unless the user says audit-only.

---

## Boundaries — what this skill owns

| This skill | Defer to |
|------------|----------|
| Null/empty/single-item data, stale CMS content, missing refs | — |
| Loading/error/retry/race, double-submit, optimistic rollback | `systematic-debugging` for root-cause investigation |
| Form validation gaps, schema mismatch, partial submit, empty submit allowed | `react-hook-form-zod` for Zod schemas, resolvers, and field wiring |
| Auth/input hardening on forms (injection, missing server validation) | `security-audit` |
| URL/search-param desync, back/forward, deep links | `react-nextjs-rules` for RSC/hydration patterns |
| i18n missing keys, locale fallbacks, RTL overflow | `translation-guidelines` for copy quality |
| GSAP/ScrollTrigger cleanup, reduced-motion | `gsap-*` skills for API usage |
| Breakpoints, touch targets, horizontal scroll | `responsive-design` |
| ARIA, keyboard, screen readers, component a11y | `radix-ui-design-system` (accessibility sections) |
| SQL injection, XSS, env leaks | `security-audit` |

---

## Invocation

One verb:

```
edge-cases review <target>
```

**Target** can be a file, directory, component name, route, feature label, or user flow (e.g. `gallery`, `/contact`, `booking form`, `src/components/Gallery.tsx`).

**Modifiers** (user may append):
- `audit only` — findings, no edits
- `fix critical` — fix 🔴 only
- `fix all` — fix 🔴 and 🟡 (default when user says "review and fix")

---

## Review workflow

Copy this checklist and track progress:

```
Edge-cases review:
- [ ] 1. Scope target — read files, trace happy path
- [ ] 2. Map inputs — props, params, searchParams, CMS fields, API responses
- [ ] 3. Run category pass — see categories.md
- [ ] 4. Run stack pass — see stack-patterns.md for detected stack
- [ ] 5. Emit findings — severity + location + fix
- [ ] 6. Fix (unless audit-only) — smallest correct diff
- [ ] 7. Verify — typecheck/lint affected files; sanity-check empty/single/error paths
```

### Step 1 · Scope

1. Read the target and its direct dependencies (data fetchers, hooks, parent layout).
2. Write one sentence: **happy path** — what succeeds when all data is present and the user acts once, slowly, online.
3. Detect stack signals from imports and `package.json`:
   - Sanity (`@sanity/client`, `next-sanity`, `groq`)
   - Supabase (`@supabase/ssr`, `@supabase/supabase-js`)
   - Forms (`react-hook-form`, `zod`, `@hookform/resolvers`)
   - i18n (`next-intl`)
   - Motion (`gsap`, `framer-motion`)
   - Maps (`@react-google-maps/api`)

### Step 2 · Enumerate failure modes

For each **input boundary** and **user action**, ask:

1. What if it's **missing** (null, undefined, `[]`, `{}`)?
2. What if there's **exactly one** item (grids, carousels, pagination)?
3. What if the **request fails** or **times out**?
4. What if the user acts **twice quickly** (double click, back button, tab switch)?
5. What if **locale / draft / preview** mode differs from production?
6. What if **viewport or motion** preference changes mid-session?

Use [categories.md](categories.md) as the checklist. Apply stack-specific probes from [stack-patterns.md](stack-patterns.md).

### Step 3 · Emit findings

Use this template:

```markdown
# Edge-cases review: <target>

**Happy path:** <one sentence>
**Stack detected:** <list>

## Findings

### 🔴 Critical — incorrect behaviour or data loss
- **[EC-001] <title>** — `path:line`
  - **Case:** <what breaks>
  - **Fix:** <concrete change>

### 🟡 Should fix — degraded UX or fragile under load
- **[EC-002] …**

### 🟢 Optional — polish, defensive hardening
- **[EC-003] …**

## Fixed
- EC-001: <what changed>
- EC-002: …

## Deferred
- EC-003: <why skipped, if any>
```

**Severity rules:**
- 🔴 Wrong output shown, crash, silent data loss, unblockable broken flow
- 🟡 Empty confuses user, stale data, race flicker, missing retry/feedback
- 🟢 Edge polish, logging, copy tweaks for empty states

### Step 4 · Fix discipline

1. **Smallest correct diff** — guard, early return, fallback UI, abort controller, `disabled` on submit. No drive-by refactors.
2. **Match project style** — existing null-check patterns, error components, SASS module structure.
3. **Don't invent content** — use existing empty-state copy patterns or a labelled placeholder (`—`, skeleton).
4. **One finding → one fix** when possible; group only when tightly coupled.
5. After fixes, re-read changed paths for **new** edge cases introduced by the fix.

### Step 5 · Verify

Minimum before handing back:
- `tsc --noEmit` or project `typecheck` if types touched
- Mentally trace: **0 items**, **1 item**, **error response** for the reviewed feature
- If GSAP/ScrollTrigger touched: confirm `kill()` / `revert()` on unmount and `prefers-reduced-motion` path

---

## Category quick reference

Full taxonomy: [categories.md](categories.md)

| Code | Domain | Top probes |
|------|--------|------------|
| D | Data | null field, empty array, broken CMS ref, stale after mutation |
| A | Async | loading forever, error not shown, race on fast navigation, no retry |
| F | Forms | submit while invalid, double submit, server error mapping, dirty reset |
| R | Routing | missing param, invalid slug → 404, searchParam type coercion |
| C | CMS | optional image, draft vs published, portable text empty block |
| S | Supabase | session expired mid-action, RLS empty result vs error, realtime gap |
| I | i18n | missing key shows raw id, locale switch loses form state |
| M | Motion | animation on empty DOM, ScrollTrigger after resize, reduced motion |
| U | UI lists | pagination at page 0, filter → empty, sort stable on ties |

---

## Stack quick reference

Per-stack probes: [stack-patterns.md](stack-patterns.md)

| Stack | Highest-risk edge cases in Ruslan's repos |
|-------|-------------------------------------------|
| Sanity CMS | optional `image`, `slug` null, reference dereference, webhook lag |
| Supabase | auth cookie refresh, `maybeSingle()` vs `single()`, upload partial fail |
| RHF + Zod | `defaultValues` vs async load, `mode: onSubmit` late errors, resolver mismatch |
| next-intl | locale segment vs middleware mismatch, ICU plural/select syntax, hardcoded string beside `t()` |
| GSAP | `useLayoutEffect` + RSC boundary, ScrollTrigger on dynamic height |
| REST | non-JSON error body, 204/no content, pagination off-by-one |

---

## Project context (from GitHub portfolio)

Repos under **RuslanNikolov1** inform default assumptions:

| Repo | Pattern |
|------|---------|
| `hairdresser-app`, `lawyer-app` | Next.js + Sanity marketing/CMS |
| `real-estate-app` | Next.js + Supabase + i18n + RHF + maps + Cloudinary |
| `burgas-massage-app`, `construction-app` | Marketing sites, motion-heavy |
| `portfolio-website` | Contact forms (RHF + Zod) |
| `knyazhevo-building-app` | Private TypeScript marketing (building sector) |
| `association-app` | Legacy Vite + react-router — check router state, no RSC |

When reviewing inside one of these repos, bias probes toward its known stack.

---

## Examples

Sample audit outputs: [examples.md](examples.md)

---

## Anti-patterns (this skill must not do)

- Duplicate a full security audit — note "see security-audit" and move on
- Duplicate component a11y audits — note "see radix-ui-design-system" and move on
- Reimplement form schemas/resolvers — note "see react-hook-form-zod" and move on
- Add tests unless the user asks
- Rewrite unrelated files while fixing one edge case
- Add heavy error boundaries everywhere — prefer local guards
- Invent CMS content, metrics, or translations
