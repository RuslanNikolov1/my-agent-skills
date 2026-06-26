# Next.js loading patterns

App Router placement for skeletons in Ruslan's projects.

---

## `loading.tsx` (route segment)

**When:** the entire page blocks on a slow server fetch (Sanity module page, Supabase detail page).

**Where:** same route folder as `page.tsx`:

```
src/app/(site)/modules/[slug]/
├── page.tsx
└── loading.tsx      ← automatic Suspense boundary
```

```tsx
// loading.tsx
import { ModulePageSkeleton } from "@/components/module-page/ModulePageSkeleton";

export default function Loading() {
  return <ModulePageSkeleton />;
}
```

**Rules:**
- Default export required
- Inherits parent `layout.tsx` (nav/footer stay visible — good UX)
- Instant on client navigations; shows during server streaming
- Do not duplicate metadata fetching in `loading.tsx`

---

## `<Suspense>` (section streaming)

**When:** page shell is fast but one section is slow (home page modules grid from Sanity, sidebar widgets, related listings).

```tsx
// page.tsx — Server Component
import { Suspense } from "react";

export default async function HomePage() {
  return (
    <>
      <HomeHero /> {/* static / fast */}
      <Suspense fallback={<ModulesGridSkeleton />}>
        <ModulesSection /> {/* async fetch inside */}
      </Suspense>
      <HomeContact /> {/* static */}
    </>
  );
}
```

**Split async children** into separate Server Components so each can suspend independently:

```tsx
// Bad — one await blocks everything
export default async function Page() {
  const [modules, reviews] = await Promise.all([getModules(), getReviews()]);
  return <><Modules data={modules} /><Reviews data={reviews} /></>;
}

// Good — parallel streaming
export default function Page() {
  return (
    <>
      <Suspense fallback={<ModulesSkeleton />}><ModulesSection /></Suspense>
      <Suspense fallback={<ReviewsSkeleton />}><ReviewsSection /></Suspense>
    </>
  );
}
```

---

## Client-side fetch (Supabase / TanStack Query)

**When:** data loads in the browser after hydration.

```tsx
"use client";

export function FavoritesPage() {
  const { data, isLoading, isError } = useFavorites();

  if (isLoading) return <FavoritesPageSkeleton />;
  if (isError) return <FavoritesError />;
  if (!data?.length) return <FavoritesEmpty />;

  return <FavoritesList items={data} />;
}
```

Skeleton lives in the **feature folder** next to the page component (`real-estate-app` pattern).

---

## `useSearchParams` / `useParams` bailout

Hooks that require Suspense — wrap the client child, not the whole page.

```tsx
// page.tsx
import { Suspense } from "react";
import { FilteredList } from "./FilteredList";
import { FilteredListSkeleton } from "./FilteredListSkeleton";

export default function ListPage() {
  return (
    <Suspense fallback={<FilteredListSkeleton />}>
      <FilteredList />
    </Suspense>
  );
}
```

See `next-best-practices` → `suspense-boundaries.md` for the full hook table.

---

## What NOT to skeleton

| Case | Use instead |
|------|-------------|
| `notFound()` path | `not-found.tsx` |
| Error throw | `error.tsx` |
| CMS optional image missing | Static placeholder (`.modulePlaceholder`) |
| Empty query result | Empty-state component |
| Sub-100ms RSC fetch with `generateStaticParams` | Skip skeleton — content is prebuilt |

---

## i18n projects (next-intl)

- `aria-label` on skeleton wrapper: `useTranslations()` in client skeletons, or `getTranslations()` in server `loading.tsx`
- Server skeletons: read locale from `[locale]` segment params; pass translated `label` prop to shared skeleton components
- Do not hardcode Bulgarian/English unless the project is single-locale

---

## Dynamic routes checklist

For `[slug]` pages:

1. `loading.tsx` shows skeleton during slug resolution + fetch
2. Skeleton hero/title blocks use generic widths (slug unknown)
3. `notFound()` after fetch — skeleton never shown for invalid slugs on revisit (cache)

---

## File convention summary

| Need | File |
|------|------|
| Full route loading | `app/**/loading.tsx` |
| Section fallback | `*Skeleton.tsx` imported in `page.tsx` |
| Client query loading | Conditional render in `"use client"` component |
| Shared shimmer | `src/styles/_skeleton.scss` or globals |
