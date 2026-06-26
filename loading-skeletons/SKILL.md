---
name: loading-skeletons
description: >-
  Creates loading skeleton UIs for Next.js App Router apps using SASS modules —
  route loading.tsx, Suspense fallbacks, shimmer primitives, and page-specific
  layout mirrors. Use when adding loading states, skeleton screens, shimmer
  placeholders, or Suspense/loading.tsx fallbacks. Defers component a11y to
  radix-ui-design-system; defers empty/error states to edge-cases.
disable-model-invocation: true
---

# Loading Skeletons

Build loading skeletons for Ruslan's Next.js + TypeScript + SASS module apps (marketing sites, Sanity CMS, Supabase dashboards).

**Default:** pure CSS shimmer in SASS modules — no Framer Motion, no client JS unless the skeleton must be interactive.

---

## Boundaries

| This skill | Defer to |
|------------|----------|
| Skeleton layout, shimmer animation, `loading.tsx`, Suspense fallbacks | `next-best-practices` for RSC/async patterns |
| `aria-busy`, reduced motion, screen reader labels | `radix-ui-design-system` for component a11y patterns |
| Empty arrays, error UI, retry flows | `edge-cases` |
| Breakpoint tuning, container queries | `responsive-design` |

---

## Decision tree

```
Need loading UI?
├─ Entire route waits on server fetch → loading.tsx (same segment as page.tsx)
├─ One slow section on an otherwise fast page → <Suspense fallback={...}>
├─ Client fetch (TanStack Query, useEffect) → co-located *Skeleton component
└─ Missing CMS image (not loading) → static placeholder (.modulePlaceholder pattern), NOT skeleton
```

**Prefer Server Components** for skeletons. Skeletons are static markup + CSS — no `"use client"` unless wrapping a client-only boundary.

---

## Workflow

Copy and track:

```
Skeleton task:
- [ ] 1. Read the real component — note grid, aspect-ratio, gaps, typography scale
- [ ] 2. Choose placement — loading.tsx vs Suspense vs client fallback
- [ ] 3. Add primitive or page skeleton — match dimensions exactly (CLS)
- [ ] 4. Wire tokens — project CSS variables, not hardcoded hex
- [ ] 5. Add a11y — role="status", aria-busy, reduced-motion
- [ ] 6. Responsive pass — same breakpoints as the real component
- [ ] 7. Verify — layout doesn't shift when content replaces skeleton
```

### Step 1 · Mirror the real layout

Skeleton must occupy the **same box model** as loaded content:

- Same `grid-template-columns`, `gap`, `aspect-ratio`, `min-height`
- Same `clamp()` font-size blocks → approximate with fixed-height bars
- Same container width (`min(100%, 48rem)` etc.)
- Card count: show 3–6 placeholders (enough to imply structure, not exact CMS count)

### Step 2 · File placement

| Pattern | Files |
|---------|-------|
| Route-level | `src/app/(site)/modules/[slug]/loading.tsx` |
| Section-level | `src/components/module-page/ModulePageSkeleton.tsx` + `.module.scss` |
| Shared primitive | `src/components/skeleton/Skeleton.tsx` + `Skeleton.module.scss` |
| Feature-scoped | `src/features/favorites/components/FavoritesPageSkeleton.tsx` (real-estate pattern) |

**Naming:** `{Feature}Skeleton.tsx` + `{Feature}Skeleton.module.scss`. Use **named exports** (`export function ModulePageSkeleton`).

### Step 3 · Choose implementation style

**Style A — Page skeleton** (preferred for marketing/CMS pages; used in `real-estate-app`):

- One component per page/section
- Shimmer on individual blocks via shared mixin
- No animation library

**Style B — Primitive + composition** (used in `portfolio-website`):

- Base `<Skeleton />` with `width`, `height`, `borderRadius`, `animation`
- Feature skeletons compose primitives
- Acceptable when many sections share the same bars — still prefer CSS-only over Framer Motion in Next apps

### Step 4 · SASS module rules

1. Co-locate `ComponentSkeleton.module.scss` beside the TSX file.
2. Import project variables when they exist (`@use "../styles/variables" as *` or page-level custom properties).
3. Use **page/component CSS variables** when the real component defines them inline:

```scss
// Inherit tokens from parent .page scope when skeleton renders inside it
.skeletonCard {
  border-top: var(--rule-hair) solid var(--color-rule);
  border-radius: var(--radius-panel);
  background: var(--color-paper-3);
}
```

4. Put shared shimmer in a partial only when **3+ skeletons** exist in the project:

```scss
// src/styles/_skeleton.scss
@mixin skeleton-shimmer($base: var(--color-paper-3), $highlight: var(--color-paper-2)) {
  background: linear-gradient(90deg, $base 25%, $highlight 50%, $base 75%);
  background-size: 200% 100%;
  animation: skeleton-shimmer 1.5s ease-in-out infinite;

  @media (prefers-reduced-motion: reduce) {
    animation: none;
    background: $base;
  }
}
```

5. Mobile-first breakpoints — copy from the real component's `_responsive.scss` or `@media (min-width: …)`.

Primitives reference: [primitives.md](primitives.md)

### Step 5 · Accessibility (minimum)

```tsx
export function ModulePageSkeleton() {
  return (
    <div
      className={styles.page}
      role="status"
      aria-busy="true"
      aria-label="Зареждане на страницата"
    >
      {/* decorative blocks */}
      <div className={styles.heroImage} aria-hidden="true" />
      <div className={styles.heroTitle} aria-hidden="true" />
    </div>
  );
}
```

- `aria-hidden="true"` on every decorative shimmer block
- One `role="status"` container with human `aria-label` (translate if project uses i18n)
- `prefers-reduced-motion: reduce` → static background, no shimmer keyframes
- Do not trap focus — skeletons are not interactive

### Step 6 · Next.js wiring

**Route `loading.tsx`:**

```tsx
import { ModulePageSkeleton } from "@/components/module-page/ModulePageSkeleton";

export default function Loading() {
  return <ModulePageSkeleton />;
}
```

**Suspense boundary** (streaming section):

```tsx
import { Suspense } from "react";
import { ModulesGridSkeleton } from "./ModulesGridSkeleton";
import { ModulesGrid } from "./ModulesGrid";

export function HomeModulesSection() {
  return (
    <Suspense fallback={<ModulesGridSkeleton />}>
      <ModulesGrid />
    </Suspense>
  );
}
```

**Client fetch** (Supabase / TanStack Query):

```tsx
if (isLoading) return <FavoritesPageSkeleton />;
if (isError) return <FavoritesError />; // edge-cases, not skeleton
```

Next.js patterns: [next-patterns.md](next-patterns.md)

---

## Token mapping (Ruslan's editorial sites)

When the real page uses oklch tokens (e.g. `hairdresser-app`, `lawyer-app`):

| Element | Token |
|---------|-------|
| Skeleton base | `--color-paper-3` |
| Shimmer highlight | `--color-paper-2` |
| Panel/card surface | `--color-panel` or `--color-panel-surface` |
| Borders | `--color-rule` |
| Rounded corners | `--radius-panel` |
| Hairline borders | `--rule-hair` |

When the project uses `globals.scss` tokens (`--color-surface`, `--color-outline`):

| Element | Token |
|---------|-------|
| Skeleton base | `--color-surface-container` |
| Shimmer highlight | `--color-surface-low` |
| Card | `--color-surface-card` |

Never use `#f0f0f0` when project tokens exist.

---

## Anti-patterns

- Generic `<div>Loading...</div>` when the page has a known layout
- Skeleton dimensions that differ from loaded content → CLS
- `"use client"` + Framer Motion for static bars (bundle cost, no benefit)
- Animating the entire page wrapper (pulse on root) — animate individual blocks
- Skeleton for **empty CMS results** — use empty-state UI instead
- Hardcoded English `aria-label` in i18n projects
- `loading.tsx` in a different layout group than its `page.tsx`

---

## Checklist before handing back

- [ ] Skeleton mirrors real layout at mobile + desktop
- [ ] No layout shift when content loads (check hero image aspect-ratio)
- [ ] `prefers-reduced-motion` respected
- [ ] `role="status"` + `aria-busy` on wrapper
- [ ] SASS uses project tokens
- [ ] Named export, co-located `.module.scss`
- [ ] `loading.tsx` or Suspense wired to the skeleton

---

## Examples

Concrete skeletons for card grids, heroes, module pages, favorites: [examples.md](examples.md)
