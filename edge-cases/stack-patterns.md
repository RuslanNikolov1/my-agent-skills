# Stack-specific edge-case patterns

Run the sections that match detected imports. These reflect Ruslan's typical stacks across **RuslanNikolov1** GitHub repos.

---

## Next.js App Router (all TypeScript repos)

### Rendering & data fetching

- **Server Component throws** → entire segment errors; prefer `notFound()` for expected misses, local try/catch for optional blocks.
- **`searchParams` is a Promise** (Next 15+) → await before use; missing await = silent bugs.
- **Parallel routes / intercepting** → hard refresh vs client nav may differ; test both.
- **`generateStaticParams` incomplete** → new CMS slug 404 until rebuild; document ISR/`dynamicParams` choice.
- **Cached fetch + mutation** → user doesn't see update; verify `revalidatePath` / `cache: 'no-store'` at boundary.

### Middleware

- Matcher too broad → static assets hit auth logic.
- Redirect drops `?query` → broken deep links after login.
- Studio route (`/studio`) gated in prod but open in dev → confirm env-based `isStudioEnabled` pattern.

### Images

- `remotePatterns` missing Sanity/Cloudinary host → build warning or broken image.
- Missing `width`/`height` → CLS; missing `alt` when CMS alt empty → use `alt=""` decorative or fallback label.

---

## Sanity CMS

*Repos: `hairdresser-app`, `lawyer-app`, similar marketing/CMS sites.*

### GROQ queries

```groq
// Risk: assumes image always present
*[_type == "post"]{ title, "imageUrl": image.asset->url }

// Safer: null-safe projection
*[_type == "post"]{
  title,
  "imageUrl": image.asset->url,
  "hasImage": defined(image.asset)
}
```

### High-frequency misses

| Pattern | Edge case | Fix |
|---------|-----------|-----|
| `slug.current` in link | slug null on draft | Don't render link; `notFound()` on page |
| Reference `->` | deleted reference | `coalesce` or filter `[defined(ref)]` |
| Portable Text | empty array | `body?.length > 0` before `<PortableText>` |
| `urlFor(image)` | image undefined | Guard; placeholder or omit |
| Ordering | `order(name asc)` with null names | Nulls first/last surprise; explicit `order` |
| Preview | draft perspective on public URL | Separate preview route + `draftMode` |

### Webhooks & revalidation

- Webhook fires before CDN purge → user sees stale page once; acceptable if revalidate is wired.
- Missing secret validation → accidental revalidation storms; not edge-case UX but check idempotency.
- **Studio gate** (`/studio` disabled when env unset) → direct URL should 404, not half-render.

---

## Supabase

*Repo: `real-estate-app` and similar.*

### Auth & SSR

- Server Component creates client without cookies → always logged out on first paint.
- `getUser()` vs `getSession()` — prefer `getUser()` for trusted server checks.
- Session refresh during Server Action → mid-flight action fails; return "session expired" + client redirect.

### Queries

```typescript
// Risk: throws on 0 rows
const { data } = await supabase.from('listings').select('*').eq('id', id).single();

// Safer
const { data, error } = await supabase.from('listings').select('*').eq('id', id).maybeSingle();
if (!data) notFound();
```

### Storage + DB two-step

1. Upload file → success
2. Insert row → fails → orphan file

Compensate: delete storage object on DB failure, or insert first with pending status.

### RLS

- Empty array may mean "no access" or "no rows" — UX should not leak which.
- Realtime `DELETE` event → remove from local list or full refresh.

---

## react-hook-form + Zod

*Repos: `real-estate-app`, `portfolio-website`.*

### Resolver alignment

- Zod `optional()` vs HTML `required` attribute mismatch.
- `z.coerce.number()` on empty string → `0`, not "required" error — use `z.union` or preprocess.
- Phone/email regex too strict for international sites (BG, EU).

### Async data into form

```typescript
// Risk: form mounts with empty defaults, never updates
const form = useForm({ defaultValues: { name: '' } });
// User profile arrives later — fields stay empty unless reset()

useEffect(() => {
  if (profile) form.reset(profile);
}, [profile, form]);
```

### Server Actions / API errors

Map server field errors:

```typescript
if (result.fieldErrors) {
  Object.entries(result.fieldErrors).forEach(([field, message]) => {
    form.setError(field as keyof FormValues, { message });
  });
}
```

---

## next-intl

*Repo: `real-estate-app`.*

### Routing & locale resolution

- Locale from `[locale]` segment + `middleware.ts` — keep middleware matcher, default locale, and `routing.locales` in sync.
- Server Components: `getTranslations({ locale, namespace })`; Client Components: `useTranslations(namespace)` inside `NextIntlClientProvider`.
- Mismatch between middleware redirect and page `params.locale` → wrong messages or 404.

### Messages & fallbacks

- Missing key in `messages/bg.json` but present in `messages/en.json` → add to all locale files; rely on `defaultLocale` only for routing fallback, not per-key fallback.
- Hardcoded JSX string beside `t()` → incomplete translation surface.

### Formatting

- `t('items', { count: n })` with ICU plural syntax — test `n = 0, 1, 2, 5`.
- Currency/dates in property listings → `useFormatter()` / `format.dateTime()` with active locale.

---

## GSAP & ScrollTrigger

*Used across marketing sites; check `gsap-*` skills for API details.*

### Client-only boundary

- Never import GSAP in Server Components.
- Prefer `useLayoutEffect` + `gsap.context()` scoped to container ref.

### Lifecycle

```typescript
useLayoutEffect(() => {
  const ctx = gsap.context(() => {
    // tweens
  }, containerRef);
  return () => ctx.revert(); // kills ScrollTriggers in scope
}, [deps]); // deps: items that change trigger positions
```

### Reduced motion

```typescript
const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
if (prefersReduced) {
  gsap.set(targets, { opacity: 1, y: 0 });
  return;
}
```

### Dynamic content

- CMS gallery loads images async → height changes → refresh triggers after images `onLoad`.
- Route change without cleanup → triggers fire on wrong pages.

---

## SASS modules

- Empty modifier class when item count 0/1 — e.g. carousel with one slide still shows arrow padding.
- `overflow: hidden` on animated parent clips focus rings — edge case for keyboard users (note for a11y skill).
- RTL: physical `margin-left` breaks in Arabic/Hebrew if ever added.

---

## REST APIs (generic)

- Treat `response.ok` false separately from network throw.
- Parse JSON only when `content-type` includes `application/json`.
- Pagination: confirm whether API is 0- or 1-indexed.
- Timeout: `fetch` has no default timeout — long hang = A-01.

---

## Vercel deployment

- Env var missing on Preview but set on Production → feature works locally, fails on PR deploy.
- `NEXT_PUBLIC_*` only for client-safe values.
- Serverless function duration — large image processing may timeout; surface error to user.
- Edge vs Node runtime — Supabase SSR and some GSAP APIs need Node client components.

---

## Legacy: Vite + react-router

*Repo: `association-app` — different from Next patterns.*

- No Server Components — all data client-side; empty/error on first paint more visible.
- React Router loader errors need `errorElement`.
- Direct URL refresh on deep route → server must serve `index.html` (SPA fallback).
