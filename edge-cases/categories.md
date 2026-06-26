# Edge-case categories

Use every applicable row during `edge-cases review`. Skip rows with no relevant code in scope.

---

## D · Data shape & presence

| ID | Case | Probe | Typical fix |
|----|------|-------|-------------|
| D-01 | `null` / `undefined` field | Optional CMS/API field used without guard | Optional chaining + fallback UI |
| D-02 | Empty array | `.map` on `[]` → blank section with no message | Empty state component |
| D-03 | Single item | Grid/carousel assumes 2+; arrows/pagination nonsense | Hide controls when `length < 2` |
| D-04 | Max length | Truncation, list caps, "show more" at boundary | Slice + expand or pagination |
| D-05 | Stale data | Mutation/revalidate not awaited; old list after create/delete | `revalidatePath` / `router.refresh()` / query invalidation |
| D-06 | Type lie | `as` cast hides missing field; runtime undefined | Narrow with Zod or type guard |
| D-07 | Sort/filter ties | Unstable order on equal keys | Secondary sort key |
| D-08 | Duplicate keys | React list key collision on duplicate slugs/ids | Composite key or dedupe |

---

## A · Async, loading, concurrency

| ID | Case | Probe | Typical fix |
|----|------|-------|-------------|
| A-01 | Loading forever | No terminal state if promise never resolves | Timeout + error UI |
| A-02 | Error swallowed | `catch` empty or only `console.log` | User-visible error + retry |
| A-03 | Race condition | Fast route change; slow response overwrites new page | `AbortController` or ignore stale id |
| A-04 | Double fetch | Strict Mode / parent+child both fetch same resource | Lift fetch or dedupe cache |
| A-05 | Double submit | Button clickable during in-flight POST | `disabled` + `isSubmitting` |
| A-06 | Optimistic rollback | UI updates before server; server fails | Revert local state on error |
| A-07 | Parallel mutations | Two updates to same record | Disable or queue; last-write-wins awareness |
| A-08 | Offline / slow | No feedback when `navigator.onLine === false` | Disable submit or queue message |

---

## F · Forms (react-hook-form + Zod)

| ID | Case | Probe | Typical fix |
|----|------|-------|-------------|
| F-01 | Async defaultValues | Form mounts before user/profile loads | `reset()` when data arrives |
| F-02 | Server validation gap | Client schema ≠ server rules | Align Zod schema with API |
| F-03 | Server error mapping | 400/422 field errors not wired to `setError` | Map `errors` to field names |
| F-04 | Submit while invalid | `type="submit"` bypasses validation | `handleSubmit` only path |
| F-05 | Dirty on success | Form stays dirty after successful save | `reset(values)` on success |
| F-06 | File upload edge | 0 files, wrong MIME, size 0, oversize | Zod refinements + clear messages |
| F-07 | Dependent fields | Field B rules depend on Field A; A changes, B stale | `watch` + revalidate B |
| F-08 | Autofill / browser | Browser fills hidden fields; validation order wrong | `shouldUnregister` review |

---

## R · Routing & URL state

| ID | Case | Probe | Typical fix |
|----|------|-------|-------------|
| R-01 | Missing dynamic param | `[slug]` undefined → bad GROQ/query | `notFound()` early |
| R-02 | Invalid slug | Exists in URL but not in DB | 404, not 500 |
| R-03 | Search param type | `?page=abc` → `NaN` | Zod coerce + default |
| R-04 | Back/forward | Filter state in URL vs React state diverges | Single source of truth (prefer URL) |
| R-05 | Deep link empty | Shared filtered URL returns empty set | Show "no results" + clear filters CTA |
| R-06 | Middleware redirect | Auth gate loops or drops query string | Preserve `search` on redirect |
| R-07 | Trailing slash | Duplicate routes / canonical split | Consistent `trailingSlash` config |
| R-08 | Hash / scroll | Anchor link after client nav doesn't scroll | `scroll: false` handling |

---

## C · Sanity CMS

| ID | Case | Probe | Typical fix |
|----|------|-------|-------------|
| C-01 | Optional image | `image` null; `urlFor` throws | Guard before `Image` / `urlFor` |
| C-02 | Broken reference | Dereferenced doc deleted | Filter nulls; fallback block |
| C-03 | Empty portable text | `body` is `[]` | Don't render empty wrapper |
| C-04 | Draft / preview | `draftMode` shows unpublished on prod link | Correct fetch token + banner |
| C-05 | Slug collision | Two docs same slug | Query `slug.current` uniqueness in Studio |
| C-06 | Webhook lag | Publish doesn't appear until hard refresh | On-demand revalidation + tag |
| C-07 | Localized field | Field empty in one locale only | Per-locale fallback chain |
| C-08 | GROQ overfetch | Projection assumes fields always set | Safe projections + defaults |

---

## S · Supabase

| ID | Case | Probe | Typical fix |
|----|------|-------|-------------|
| S-01 | Session expired | Action after idle → opaque failure | Refresh session; redirect to login |
| S-02 | `single()` vs empty | `.single()` throws on 0 rows | `maybeSingle()` + branch |
| S-03 | RLS silent empty | Policy blocks read → looks like no data | Distinguish error vs empty where possible |
| S-04 | Storage partial | Upload succeeds, DB insert fails | Compensating delete or transaction pattern |
| S-05 | Realtime gap | Subscription misses initial state | Seed query + subscribe |
| S-06 | SSR cookie | Server client missing session on first paint | `@supabase/ssr` cookie pattern |
| S-07 | Pagination | `range` off-by-one at last page | Total count or `hasMore` flag |
| S-08 | Concurrent edit | Two tabs update same row | Updated_at check or optimistic lock |

---

## I · i18n (next-intl)

| ID | Case | Probe | Typical fix |
|----|------|-------|-------------|
| I-01 | Missing message | Dev error or empty string in UI | Add key to all locale JSON files; enable strict mode in dev |
| I-02 | Locale mismatch | Server `getTranslations` locale ≠ client provider | Align `[locale]` segment, middleware, and `NextIntlClientProvider` |
| I-03 | Plural / count | `count={0}` wrong ICU branch | Test 0, 1, 2, many; use `{count, plural, …}` syntax |
| I-04 | Interpolation | Variable undefined → broken sentence | Default values in message or guard before `t()` |
| I-05 | Locale switch mid-form | Labels change, values preserved | Acceptable or warn user |
| I-06 | RTL layout | Mirrored icons, padding wrong | Logical properties (`margin-inline`) |
| I-07 | Date/number format | `toLocaleString` without locale arg | Use `useFormatter()` / `format.number()` with active locale |
| I-08 | Partial messages | Client missing namespace passed from server | Include all namespaces in `getRequestConfig` / provider `messages` |

---

## M · Motion (GSAP / Framer)

| ID | Case | Probe | Typical fix |
|----|------|-------|-------------|
| M-01 | Empty target | `querySelector` null; tween on missing node | Guard before animate |
| M-02 | Unmount leak | ScrollTrigger / timeline survives route change | `ctx.revert()` / `kill()` in cleanup |
| M-03 | Resize / font load | Trigger positions wrong after layout shift | `ScrollTrigger.refresh()` debounced |
| M-04 | Reduced motion | Animation runs despite `prefers-reduced-motion` | CSS/JS respect + instant state |
| M-05 | RSC boundary | GSAP in Server Component | Move to client child |
| M-06 | List reorder | Animated list keys change → jump | Stable keys + `layoutId` discipline |
| M-07 | Tab hidden | `requestAnimationFrame` backlog | `visibilitychange` pause |
| M-08 | Initial flash | Content visible before `autoAlpha: 0` | FOUC class or inline hide |

---

## U · UI lists, filters, pagination

| ID | Case | Probe | Typical fix |
|----|------|-------|-------------|
| U-01 | Page 0 / negative | `?page=0` or `-1` | Clamp to `>= 1` |
| U-02 | Page past end | `?page=999` on 3-page set | Clamp or redirect to last |
| U-03 | Filter → empty | Active filters, zero results | Empty state + reset filters |
| U-04 | All selected | Bulk action with 0 selection | Disable action bar |
| U-05 | Image aspect | Mixed portrait/landscape breaks grid | `object-fit` + fixed ratio box |
| U-06 | Long text | Title overflows card | `line-clamp` + accessible full text |
| U-07 | Modal stack | Second modal closes first's scroll lock | Single lock owner |
| U-08 | Toast flood | Many errors → stacked toasts | Dedupe or replace |

---

## E · External APIs & integrations

| ID | Case | Probe | Typical fix |
|----|------|-------|-------------|
| E-01 | Non-JSON error | HTML 502 body parsed as JSON | Content-type check |
| E-02 | 204 No Content | `response.json()` throws | Branch on status |
| E-03 | Rate limit | 429 with retry-after | Backoff + user message |
| E-04 | Maps no API key | Dev works, prod blank | Env guard + fallback map link |
| E-05 | Cloudinary transform | Missing public_id | Guard asset before transform |
| E-06 | Email send fail | Form saved but email not sent | Surface partial success honestly |
| E-07 | Webhook retry | Duplicate webhook delivery | Idempotency key |
| E-08 | CORS preflight | Client calls wrong origin | Server route proxy |
