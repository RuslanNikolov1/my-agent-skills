# Security categories

Use every applicable row during `security-audit review`. Skip rows with no relevant code in scope.

---

## A · Authentication & authorization

| ID | Case | Probe | Typical fix |
|----|------|-------|-------------|
| A-01 | Missing auth on mutating route | POST/PUT/DELETE handler has no session check | `getUser()` / webhook secret / API key |
| A-02 | Hardcoded admin identity | `user.email === 'x@gmail.com'` | Supabase custom claim, `admin` table, or env allowlist |
| A-03 | Static session cookie | Cookie value `'authenticated'` with no signature | Signed JWT or iron-session; rotate on login |
| A-04 | Timing-unsafe compare | `password === ADMIN_PASS` | `safeEqual` (see hairdresser-app `gate.ts`) |
| A-05 | Studio exposed in prod | `/studio` loads without basic auth | Middleware + `STUDIO_BASIC_AUTH_*`; 404 when unset |
| A-06 | Client-side auth gate only | `useEffect` redirect, no server check | Middleware or Server Component `getUser()` |
| A-07 | IDOR | `[id]` from URL used in query without ownership check | Verify `user.id` owns resource or admin role |
| A-08 | Privilege escalation | User can set `role` field in POST body | Strip privileged fields; server assigns roles |
| A-09 | Session not invalidated on logout | Cookie remains valid | `clearCookie` with matching path/domain |
| A-10 | Basic auth over HTTP | `secure: false` in production cookies | `secure: process.env.NODE_ENV === 'production'` |

---

## E · Environment variables & secrets

| ID | Case | Probe | Typical fix |
|----|------|-------|-------------|
| E-01 | Server secret in `NEXT_PUBLIC_*` | Write token, service role, API secret public | Rename; server-only `process.env` |
| E-02 | Secret in client bundle | `process.env.SECRET` in `"use client"` file | Move to Route Handler / Server Action |
| E-03 | `.env` committed | Real tokens in git history | Remove, rotate, add to `.gitignore` |
| E-04 | Missing env fails open | `if (!secret) return next()` on protected path | Fail closed: 500 or deny access |
| E-05 | Secret in error message | `"Missing SANITY_REVALIDATE_SECRET"` to client | Generic message; log server-side |
| E-06 | `.env.example` drift | New secret used but not documented | Update example with placeholder + comment |
| E-07 | Preview deploy missing vars | Feature works locally, auth disabled on PR | Document required Vercel env per environment |
| E-08 | Token in URL | `?token=` for webhooks or draft mode | Header-only secrets; short-lived tokens |

---

## I · Input validation & injection

| ID | Case | Probe | Typical fix |
|----|------|-------|-------------|
| I-01 | No server validation | Client Zod only; API trusts body | Shared Zod schema on Route Handler |
| I-02 | `unknown` body cast | `body as FormData` without parse | `safeParse`; 400 on failure |
| I-03 | Missing length limits | `name` unbounded → DoS / email header abuse | `z.string().max(200)` etc. |
| I-04 | Email header injection | User input in Mailtrap `from` / `subject` | Sanitize newlines; fixed `from` address |
| I-05 | Slug/path injection | `moduleSlug` passed to GROQ unescaped | Parametrize GROQ; allowlist slug format |
| I-06 | SQL injection | Raw string concat in query | Parameterized / Supabase client methods |
| I-07 | NoSQL / GROQ injection | User input in filter string | Never interpolate; use `$param` |
| I-08 | Mass assignment | Spread `...body` into DB insert | Explicit field pick list |
| I-09 | File upload abuse | No MIME/size check | Zod + server verify magic bytes |
| I-10 | JSON bomb | Huge `request.json()` | `Content-Length` check or body size limit |

---

## W · Webhooks, signatures & CSRF

| ID | Case | Probe | Typical fix |
|----|------|-------|-------------|
| W-01 | Unsigned webhook | `/api/revalidate` accepts any POST | `isValidSignature` + secret (hairdresser pattern) |
| W-02 | Secret in query string | `?secret=` on webhook URL | Header-only (`SIGNATURE_HEADER_NAME`) |
| W-03 | CSRF on cookie auth | State-changing POST from cookie session | SameSite strict + CSRF token for forms |
| W-04 | Missing method guard | GET handler mutates state | POST-only; 405 otherwise |
| W-05 | Replay attacks | Same webhook processed twice | Idempotency key or event ID dedup |
| W-06 | Open redirect | `redirect(request.nextUrl.searchParams.get('next'))` | Allowlist internal paths only |

---

## S · Supabase & database

| ID | Case | Probe | Typical fix |
|----|------|-------|-------------|
| S-01 | Service role client-side | `SUPABASE_SERVICE_ROLE_KEY` in client import | `getSupabaseAdminClient()` server-only module |
| S-02 | RLS disabled assumption | Admin client used when user client + RLS suffices | Prefer user-scoped client |
| S-03 | `getSession()` trust | JWT not verified server-side | `getUser()` on server |
| S-04 | Anon key for admin ops | Approve/delete via anon client | Auth check + admin client or RLS policy |
| S-05 | Error reveals schema | Raw PostgREST error to client | Generic message; log `error.code` server-side |
| S-06 | Storage public bucket | PII uploads world-readable | Private bucket + signed URLs |
| S-07 | Missing auth on Storage upload | Client uploads directly without policy | RLS on `storage.objects` |

---

## C · Sanity CMS

| ID | Case | Probe | Typical fix |
|----|------|-------|-------------|
| C-01 | Write token in browser | `SANITY_API_WRITE_TOKEN` imported client-side | `getWriteClient()` server-only; null if missing |
| C-02 | Draft mode open | `/api/draft-mode/enable` unauthenticated | `defineEnableDraftMode` + secret; preview URL only |
| C-03 | Studio in production | No basic auth env set | `studioDisabledResponse()` 404 (hairdresser pattern) |
| C-04 | Portable Text XSS | Custom components render raw HTML | Sanitize; use `@portabletext/react` defaults |
| C-05 | Webhook over-broad filter | Revalidates on any doc type | Type check in handler (`payload._type`) |
| C-06 | CORS on Sanity API | Custom proxy exposes token | Use server fetch; never proxy with write token |

---

## X · XSS, output encoding & content

| ID | Case | Probe | Typical fix |
|----|------|-------|-------------|
| X-01 | `dangerouslySetInnerHTML` | CMS or user HTML without sanitize | DOMPurify server-side or avoid |
| X-02 | Reflected XSS | `searchParams.q` rendered unescaped | React text nodes auto-escape; audit raw HTML |
| X-03 | Stored XSS | Signup `name` displayed in Studio/email | Encode in email templates; Sanity is admin-only |
| X-04 | `javascript:` URLs | User-provided `href` from CMS | Allowlist `https:` / `mailto:` |
| X-05 | SVG upload XSS | Inline script in uploaded SVG | Serve as attachment or sanitize |
| X-06 | Open graph injection | User title in `<meta>` without escape | Use Next.js `metadata` API |

---

## H · HTTP, cookies & headers

| ID | Case | Probe | Typical fix |
|----|------|-------|-------------|
| H-01 | Cookie missing `httpOnly` | Session readable by JS | `httpOnly: true` |
| H-02 | Cookie missing `secure` | Sent over HTTP in prod | `secure: true` in production |
| H-03 | `sameSite: none` without need | CSRF surface | `lax` or `strict` |
| H-04 | Auth response cached | `Cache-Control` missing on auth routes | `no-store` (burgas pattern) |
| H-05 | CORS wildcard | `Access-Control-Allow-Origin: *` with credentials | Explicit origin allowlist |
| H-06 | Missing `X-Content-Type-Options` | MIME sniffing | `nosniff` via `next.config` headers |
| H-07 | Clickjacking | Sensitive actions embeddable | `X-Frame-Options` / CSP `frame-ancestors` |

---

## R · Rate limiting & abuse

| ID | Case | Probe | Typical fix |
|----|------|-------|-------------|
| R-01 | Public signup spam | `/api/signup` unlimited POST | Vercel WAF, Upstash rate limit, honeypot |
| R-02 | Email bomb | Contact form sends mail per request | Rate limit per IP; captcha if abused |
| R-03 | Enumeration | Login reveals "user not found" vs "wrong password" | Generic "invalid credentials" |
| R-04 | Revalidation flood | Webhook endpoint DoS | Signature required + optional IP allowlist |
| R-05 | Cloudinary sign abuse | Open sign endpoint drains quota | Require auth before signing |
| R-06 | Brute force basic auth | No lockout on `/studio` | Strong password; optional fail2ban at edge |

---

## L · Logging, errors & observability

| ID | Case | Probe | Typical fix |
|----|------|-------|-------------|
| L-01 | Secret in logs | `console.log({ signature, apiSecret })` | Remove; log boolean success only |
| L-02 | Stack trace to client | `error.message` from caught exception in JSON | Generic 500 message |
| L-03 | Debug endpoints in prod | `/api/email/test` reachable | Guard with `NODE_ENV` or auth |
| L-04 | Source maps public | Full paths in production | Default Next.js hidden maps |
| L-05 | Sensitive data in Sentry | PII in breadcrumb | Scrub before `captureException` |

---

## P · Third-party integrations

| ID | Case | Probe | Typical fix |
|----|------|-------|-------------|
| P-01 | Cloudinary unsigned upload | Client uploads without server sign auth | Auth-gated sign route; signed params only |
| P-02 | Mailtrap token leak | Token in client fetch | Server-side send only |
| P-03 | Google Maps key unrestricted | `NEXT_PUBLIC_` key no referrer limit | Restrict in Google Cloud console |
| P-04 | Webhook URL public | Sanity webhook URL guessable | Strong `SANITY_REVALIDATE_SECRET` |
| P-05 | OAuth state missing | Supabase OAuth no `state` param | Use provider's built-in CSRF protection |
