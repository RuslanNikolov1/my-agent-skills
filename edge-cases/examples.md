# Edge-cases review examples

Illustrative outputs for Ruslan's typical app shapes. Format matches SKILL.md template.

---

## Example 1 · Sanity gallery component

**Invocation:** `edge-cases review gallery`

```markdown
# Edge-cases review: gallery

**Happy path:** CMS returns 6+ images with alt text; user opens lightbox and navigates prev/next.
**Stack detected:** Next.js, Sanity, SASS modules, TypeScript

## Findings

### 🔴 Critical
- **[EC-001] urlFor called when image is null** — `src/components/Gallery.tsx:42`
  - **Case:** Optional Sanity image field empty → runtime throw, whole page errors
  - **Fix:** Skip item in map when `!image?.asset`; filter before render

### 🟡 Should fix
- **[EC-002] Prev/next shown with one image** — `Gallery.tsx:78`
  - **Case:** Single gallery item still shows disabled-looking arrows and extra padding
  - **Fix:** `const showNav = images.length > 1`; conditional class + hide buttons

- **[EC-003] No empty state** — `Gallery.tsx:30`
  - **Case:** `images = []` renders empty section with heading only
  - **Fix:** Early return `<GalleryEmpty />` or null when `!images?.length`

### 🟢 Optional
- **[EC-004] Alt fallback** — `Gallery.tsx:55`
  - **Case:** CMS alt empty string → decorative image should be `alt=""`
  - **Fix:** `alt={image.alt || ''}` + `role="presentation"` only if purely decorative

## Fixed
- EC-001: filtered null assets before map
- EC-002: hid nav when `length < 2`
- EC-003: added empty state component

## Deferred
- EC-004: needs content decision from client
```

---

## Example 2 · Contact form (RHF + Zod)

**Invocation:** `edge-cases review contact form`

```markdown
# Edge-cases review: contact form

**Happy path:** User fills name, email, message; server sends email; success toast shown.
**Stack detected:** Next.js, react-hook-form, Zod, Route Handler

## Findings

### 🔴 Critical
- **[EC-001] Double submit sends duplicate emails** — `ContactForm.tsx:88`
  - **Case:** User double-clicks Submit before `isSubmitting` disables button
  - **Fix:** `disabled={isSubmitting}` on button + ignore submit if `formState.isSubmitting`

### 🟡 Should fix
- **[EC-002] Server 500 shows generic alert** — `ContactForm.tsx:102`
  - **Case:** Mailtrap/API down; user sees "Something went wrong" with no retry
  - **Fix:** Error banner with Retry button calling same `onSubmit`

- **[EC-003] Phone optional but empty string fails refine** — `schema.ts:12`
  - **Case:** User leaves phone blank → `z.string().regex(...)` runs on `""`
  - **Fix:** `z.union([z.literal(''), z.string().regex(...)])` or `.optional().or(z.literal(''))`

## Fixed
- EC-001: disabled submit + guard in handler
- EC-002: retry UI on server error
- EC-003: schema allows empty phone
```

---

## Example 3 · Supabase listings with i18n

**Invocation:** `edge-cases review listings page`

```markdown
# Edge-cases review: listings page

**Happy path:** `/bg/listings?page=1` shows paginated properties from Supabase with filters.
**Stack detected:** Next.js, Supabase SSR, next-intl, TanStack Query

## Findings

### 🔴 Critical
- **[EC-001] `.single()` when slug not found** — `src/app/listings/[id]/page.tsx:18`
  - **Case:** Invalid UUID or deleted listing → unhandled Supabase error → 500
  - **Fix:** `maybeSingle()` + `notFound()`

### 🟡 Should fix
- **[EC-002] `?page=abc` becomes NaN** — `ListingsPage.tsx:24`
  - **Case:** Invalid page param → `range(NaN, NaN)` odd behaviour
  - **Fix:** `const page = Math.max(1, Number(searchParams.page) || 1)`

- **[EC-003] Filter active + zero results** — `ListingsGrid.tsx:40`
  - **Case:** User applies price filter; empty grid with no explanation
  - **Fix:** Empty state + "Clear filters" link resetting search params

- **[EC-004] Count plural in Bulgarian** — `ListingsHeader.tsx:12`
  - **Case:** `t('listingCount', { count: 0 })` may use wrong ICU plural branch
  - **Fix:** Verify `listingCount` message uses `{count, plural, =0 {…} one {…} other {…}}` in `messages/bg.json`

## Fixed
- EC-001, EC-002, EC-003

## Deferred
- EC-004: translation files updated in separate pass — flagged for user
```

---

## Example 4 · GSAP scroll section

**Invocation:** `edge-cases review hero animation`

```markdown
# Edge-cases review: hero animation

**Happy path:** User scrolls; pinned hero text animates through three beats.
**Stack detected:** Next.js client component, GSAP, ScrollTrigger

## Findings

### 🔴 Critical
- **[EC-001] ScrollTrigger survives route change** — `HeroScroll.tsx:67`
  - **Case:** Navigate away mid-pin → next page scroll broken
  - **Fix:** `gsap.context()` + `return () => ctx.revert()` in `useLayoutEffect`

### 🟡 Should fix
- **[EC-002] No reduced-motion path** — `HeroScroll.tsx:22`
  - **Case:** `prefers-reduced-motion: reduce` still pins and animates
  - **Fix:** Early exit sets final visual state, skip ScrollTrigger.create

- **[EC-003] Trigger positions wrong after image load** — `HeroScroll.tsx:45`
  - **Case:** Hero image lazy-loads → section height changes → pin end wrong
  - **Fix:** `imagesLoaded` callback or `onLoad` → `ScrollTrigger.refresh()`

## Fixed
- EC-001, EC-002, EC-003
```

---

## Example 5 · Middleware studio gate

**Invocation:** `edge-cases review studio route`

```markdown
# Edge-cases review: /studio route

**Happy path:** Authorized editor opens `/studio` in dev with env configured.
**Stack detected:** Next.js middleware, Sanity Studio

## Findings

### 🟡 Should fix
- **[EC-001] Studio renders partial UI when gate disabled** — `page.tsx:12`
  - **Case:** `SANITY_STUDIO_ENABLED` unset → client bundle loads before redirect
  - **Fix:** Server-side `notFound()` in page when `!isStudioEnabled()` (mirror middleware)

- **[EC-002] Redirect loop if matcher includes studio API** — `middleware.ts:8`
  - **Case:** Studio auth callback hits middleware → infinite redirect
  - **Fix:** Exclude `/api/draft` and studio auth paths from matcher

## Fixed
- EC-001: early `notFound()` in page component
- EC-002: narrowed middleware matcher
```

---

## Audit-only example

**Invocation:** `edge-cases review booking webhook audit only`

When user says **audit only**, emit findings with no ## Fixed section and do not edit files. End with:

```markdown
## Next steps
Run `edge-cases review booking webhook fix critical` to apply 🔴 fixes only.
```
