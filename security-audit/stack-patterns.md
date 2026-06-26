# Stack-specific security patterns

Probes for Ruslan's typical stacks. Run sections matching detected imports.

---

## Next.js App Router

> Env exposure, Server Actions, middleware matchers, security headers, grep commands: [nextjs-patterns.md](nextjs-patterns.md)

### Route Handlers (`app/api/**/route.ts`)

**Checklist per handler:**

```
[ ] Auth required for this action?
[ ] Method restricted (POST only)?
[ ] Body validated with Zod safeParse?
[ ] Errors generic to client?
[ ] No server env in response JSON?
[ ] Rate limit needed (public POST)?
```

**Good pattern (hairdresser-app signup):**

```typescript
export async function POST(request: Request) {
  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return Response.json({ error: "Невалидни данни." }, { status: 400 });
  }

  const parsed = parseSignupPayload(body); // or Zod safeParse
  if ("error" in parsed) {
    return Response.json({ error: parsed.error }, { status: 400 });
  }
  // ...
}
```

**Upgrade path:** replace manual `parseSignupPayload` with shared Zod schema used by form + API.

### Middleware

**hairdresser-app pattern (reference implementation):**

| Control | Implementation |
|---------|----------------|
| Studio gate | Matcher scoped to `/studio` only |
| Prod without creds | `404` not `403` (no existence leak) |
| Dev without creds | Allow (optional) |
| Timing-safe auth | `safeEqual` on user + password |
| Parse failures | `catch` on `atob` |

```typescript
export const config = {
  matcher: ["/studio", "/studio/:path*"], // narrow — not `/api/*`
};
```

**Probe:** middleware matcher doesn't intercept Sanity webhook paths or draft-mode callbacks.

### Server vs Client boundary

| Secret | Allowed location |
|--------|------------------|
| `SANITY_API_WRITE_TOKEN` | `getWriteClient()`, Route Handlers, Server Actions |
| `SANITY_API_READ_TOKEN` | draft-mode route, server preview only |
| `SANITY_REVALIDATE_SECRET` | `/api/revalidate` only |
| `SUPABASE_SERVICE_ROLE_KEY` | `getSupabaseAdminClient()` server module |
| `MAILTRAP_API_TOKEN` | email send lib, never client |
| `CLOUDINARY_API_SECRET` | sign route server-only |
| `STUDIO_BASIC_AUTH_*` | middleware / gate.ts |

**Never** import server-only modules into `"use client"` files — even unused imports can bundle-check.

---

## Sanity CMS

*Repos: `hairdresser-app`, `lawyer-app`.*

### Webhook revalidation (good pattern)

```typescript
const signature = request.headers.get(SIGNATURE_HEADER_NAME);
const body = await request.text();

if (!signature || !(await isValidSignature(body, signature, secret))) {
  return NextResponse.json({ message: "Invalid signature" }, { status: 401 });
}
```

**Probes:**
- Secret missing → 500 (fail closed), not skip validation
- Payload type filtered (`_type !== "module"` → ignore)
- Raw body used for signature (not re-serialized JSON)

### Draft mode

```typescript
export const { GET } = defineEnableDraftMode({
  client: client.withConfig({ token: process.env.SANITY_API_READ_TOKEN }),
});
```

**Probes:**
- `SANITY_API_READ_TOKEN` is viewer/read-only, not write
- Draft enable route requires Sanity presentation secret (next-sanity default)
- Preview URLs not indexed (`robots` / no sitemap)

### Studio gate

Env vars from `.env.example`:

```
STUDIO_BASIC_AUTH_USER=
STUDIO_BASIC_AUTH_PASSWORD=
```

**Prod rule:** no creds → studio returns 404 at middleware AND page level (defence in depth).

### Signup → Sanity write

- `getWriteClient()` returns `null` without token — form fails safely
- User input fields: `name`, `phone`, `email`, `moduleSlug` — validate length + email format
- **Missing today:** rate limiting, honeypot, Zod max lengths

---

## Supabase

*Repo: `real-estate-app`.*

### Server auth check (approve route pattern)

```typescript
const { data: { user }, error } = await supabase.auth.getUser();
if (authError || !user) {
  return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
}
```

**Weak pattern seen:**

```typescript
if (user.email !== 'ruslannikolov1@gmail.com') { // hardcoded admin
```

**Fix options:**
1. `app_metadata.role === 'admin'` set only via service role
2. `admin_users` table + RLS
3. Env allowlist `ADMIN_EMAILS` (comma-separated) for small sites

### Admin client

```typescript
// src/lib/supabase-admin.ts — server only
export function getSupabaseAdminClient() {
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY; // never NEXT_PUBLIC_
  // ...
}
```

**Probes:**
- File has no `"use client"`
- Never imported from client components or shared hooks
- Admin ops always preceded by `getUser()` auth check

### RLS

- Public read policies: confirm no PII columns exposed
- Insert policies: user can only insert own `user_id`
- Storage: bucket policies match application auth model

---

## Forms (react-hook-form + Zod)

*Repos: `portfolio-website`, `real-estate-app`.*

### Client + server parity

```typescript
// shared schema
export const contactSchema = z.object({
  name: z.string().trim().min(1).max(100),
  email: z.string().email().max(254),
  message: z.string().trim().min(10).max(5000),
});

// Route Handler
const result = contactSchema.safeParse(body);
if (!result.success) {
  return Response.json({ error: "Invalid input" }, { status: 400 });
}
```

**Probes:**
- Resolver on client matches server schema (import same file)
- Phone fields: international format; max length
- Honeypot field: server rejects if filled

### Manual validation (hairdresser signup)

Current `parseSignupPayload` — acceptable but audit for:
- Max string lengths
- Phone format abuse
- `moduleSlug` injection into notifications
- Upgrade to Zod when touching the file

---

## Cloudinary

*Repo: `real-estate-app` — known risk.*

### Unauthenticated sign endpoint

**Problem:** `POST /api/cloudinary/sign` returns `signature` + `api_key` to anyone.

**Fix:**

```typescript
export async function POST(request: NextRequest) {
  const supabase = await createServerSupabaseClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
  // then sign...
}
```

**Also remove:** `console.log` of signature params in production.

---

## Admin auth (cookie-based)

*Repo: `burgas-massage-app` — patterns to fix when auditing similar code.*

| Issue | Risk | Fix |
|-------|------|-----|
| Cookie value `'authenticated'` | Forgery — set cookie in DevTools | Signed token (JWT / iron-session) |
| `username === ADMIN_USER` | Timing leak | `safeEqual` |
| No CSRF on POST login | Cross-site login | SameSite strict + CSRF token |
| GET returns auth status | Fingerprinting | Acceptable if no sensitive data |

**Good parts to keep:**
- `httpOnly: true`
- `secure` in production
- `sameSite: 'strict'`
- `Cache-Control: no-store` on auth responses

---

## Mailtrap / email

*Repo: `hairdresser-app`.*

```typescript
const token =
  process.env.MAILTRAP_API_TOKEN?.trim() ||
  process.env.MAILTRAP_API_KEY?.trim();
```

**Probes:**
- Send only from server (`sendSignupNotification`)
- `MAILTRAP_FROM_EMAIL` fixed — user input never in `from`
- User `name`/`email` in body escaped for HTML injection in templates
- Sandbox mode (`MAILTRAP_USE_SANDBOX`) not enabled in production env

---

## Vercel deployment

| Check | Action |
|-------|--------|
| Production env | All secrets set; Preview may differ intentionally |
| `NEXT_PUBLIC_*` audit | Only truly public values |
| Serverless logs | No PII/secrets in `console.log` |
| WAF / rate limiting | Enable for public form endpoints if abused |
| Deployment protection | Preview URLs may expose unfinished features |

---

## Env surface reference (hairdresser-app)

From `.env.example` — audit that each is correctly scoped:

| Variable | Scope | Risk if public |
|----------|-------|----------------|
| `NEXT_PUBLIC_SITE_URL` | Public | Low |
| `NEXT_PUBLIC_SANITY_*` | Public | Low (project ID/dataset are public by design) |
| `SANITY_API_READ_TOKEN` | Server | Medium — draft content access |
| `SANITY_API_WRITE_TOKEN` | Server | **Critical** — document creation |
| `SANITY_REVALIDATE_SECRET` | Server/webhook | **Critical** — cache purge |
| `STUDIO_BASIC_AUTH_*` | Server | **Critical** — studio access |
| `MAILTRAP_API_TOKEN` | Server | **High** — email send quota |

---

## Legacy: Vite + react-router

*Repo: `association-app`.*

- API keys in `import.meta.env.VITE_*` are **always public**
- No server-side validation unless separate backend
- SPA admin routes: security theater without server auth
- Check Netlify/Vercel redirects don't expose admin paths
