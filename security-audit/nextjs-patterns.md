# Next.js security patterns

App Router probes merged from the former `security-nextjs` skill. Run during every `security-audit review` on Next.js projects.

---

## Environment variable exposure

### The `NEXT_PUBLIC_` footgun

```
NEXT_PUBLIC_* → Bundled into client JavaScript → Visible to everyone
No prefix     → Server-only → Safe for secrets
```

**Audit steps:**
1. Grep all `NEXT_PUBLIC_` in `.env*` and source files
2. For each var, ask: "Would I be OK if this was in view-source?"
3. Common mistakes:
   - `NEXT_PUBLIC_API_KEY` → should be server-only
   - `NEXT_PUBLIC_DATABASE_URL` → must not use
   - `NEXT_PUBLIC_STRIPE_SECRET_KEY` → use `STRIPE_SECRET_KEY`
   - `NEXT_PUBLIC_CLOUDINARY_API_SECRET` → server-only (real-estate-app uses key public, secret server — verify)

**Safe pattern:**

```typescript
// Server-only (Route Handler, Server Component, Server Action)
const apiKey = process.env.SANITY_API_WRITE_TOKEN;

// Client-safe (truly public)
const projectId = process.env.NEXT_PUBLIC_SANITY_PROJECT_ID;
```

### `next.config` `env` is always bundled

Values under `env` in `next.config.js/ts/mjs` are inlined into the client bundle even without `NEXT_PUBLIC_`. Treat as public.

```javascript
// ❌ Exposed to browser
module.exports = {
  env: { DATABASE_URL: process.env.DATABASE_URL },
};
```

### Ruslan's safe `NEXT_PUBLIC_` values

| Variable | OK public? |
|----------|------------|
| `NEXT_PUBLIC_SITE_URL` | Yes |
| `NEXT_PUBLIC_SANITY_PROJECT_ID` | Yes |
| `NEXT_PUBLIC_SANITY_DATASET` | Yes |
| `NEXT_PUBLIC_SUPABASE_URL` | Yes |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Yes (RLS must protect data) |
| `NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME` | Yes |
| `NEXT_PUBLIC_CLOUDINARY_API_KEY` | Yes (pair with server secret) |

---

## Server Actions

### Missing auth (most common)

```typescript
// ❌ No auth check
"use server";
export async function deleteListing(id: string) {
  await db.from("listings").delete().eq("id", id);
}

// ✓ Supabase auth + authorization (real-estate pattern)
"use server";
export async function deleteListing(id: string) {
  const supabase = await createServerClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error("Unauthorized");
  // verify ownership or admin role before delete
}
```

### Input validation

```typescript
// ❌ Trusts client input
"use server";
export async function updateProfile(data: Record<string, unknown>) {
  await db.update(data);
}

// ✓ Zod (portfolio-website pattern)
"use server";
const schema = z.object({ name: z.string().max(100), bio: z.string().max(500) });
export async function updateProfile(formData: FormData) {
  const data = schema.parse(Object.fromEntries(formData));
  // ...
}
```

**Probes:**
- Every `"use server"` file that mutates data has auth
- Shared Zod schema with matching Route Handler
- No privileged fields accepted from client (`role`, `isAdmin`)

---

## API Routes (`app/api/**/route.ts`)

### Auth patterns by route type

| Route type | Auth pattern |
|------------|--------------|
| Public form (signup) | Zod validation + rate limit; no session required |
| Webhook (revalidate) | HMAC signature (`isValidSignature`) |
| Admin mutating | `getUser()` + role check |
| Sign/upload (Cloudinary) | `getUser()` before signing |
| Draft mode | next-sanity secret + read token server-only |

```typescript
// ❌ No auth on sensitive GET
export async function GET() {
  return Response.json(await db.users.findMany());
}

// ✓ Supabase session check
export async function GET() {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return new Response("Unauthorized", { status: 401 });
  // ...
}

// ✓ Webhook — signature not session (hairdresser-app)
const body = await request.text();
if (!signature || !(await isValidSignature(body, signature, secret))) {
  return NextResponse.json({ message: "Invalid signature" }, { status: 401 });
}
```

**False positives:** public POST routes (signup, contact) are intentionally unauthenticated — verify validation + rate limit instead.

### Pages Router (`pages/api/**`)

Legacy repos only (`association-app`). Check all handlers; inconsistent GET-public / POST-auth is common.

---

## Middleware

### Matcher coverage

```typescript
// ❌ Admin pages gated but API open
matcher: ["/dashboard/:path*"];
// /api/admin/* unprotected!

// ✓ Include API routes when they need auth
matcher: ["/dashboard/:path*", "/api/admin/:path*"];

// ✓ Narrow matcher — hairdresser studio gate
matcher: ["/studio", "/studio/:path*"];
```

### Auth quality

```typescript
// ❌ Cookie existence only
const token = request.cookies.get("session");
if (!token) return NextResponse.redirect("/login");

// ✓ Verify token (JWT decode, or defer to Route Handler auth)
// ✓ Timing-safe compare for basic auth (hairdresser gate.ts safeEqual)
```

**Probes:**
- Matcher not so broad it blocks webhooks (`/api/revalidate`) or draft callbacks
- Prod fail-closed when auth env unset (404, not open)
- No redirect loops with auth callback paths

---

## Security headers (`next.config`)

```typescript
// next.config.ts
const securityHeaders = [
  { key: "X-Frame-Options", value: "DENY" },
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  // CSP: start strict; avoid unsafe-inline/unsafe-eval unless documented debt
];
```

Severity: 🟢 Low — but add when touching `next.config`.

---

## Quick grep commands

```bash
# NEXT_PUBLIC_ in env and source
rg "NEXT_PUBLIC_" . -g "*.env*" -g "*.ts" -g "*.tsx"

# next.config env block (always bundled)
rg -n "env\s*:" next.config.*

# Server Actions
rg -l '"use server"' . -g "*.ts" -g "*.tsx"

# API routes
rg --files -g "**/app/api/**/route.ts"

# XSS surface
rg "dangerouslySetInnerHTML" . -g "*.tsx"

# Server secrets in client components
rg "process\.env\." src -g "*.tsx" -l | xargs rg -l '"use client"'

# Auth patterns (Supabase + Sanity + basic auth)
rg "(getUser|isValidSignature|isStudioAccessGranted|safeEqual)" .
```

---

## Automated first pass

Run the bundled scanner before manual review:

```bash
bash ~/.cursor/skills/security-audit/scripts/scan.sh .
```

Treat output as **candidates** — confirm each finding (public routes are not bugs).

---

## Severity quick reference

| Issue | Where to look | Severity |
|-------|---------------|----------|
| `NEXT_PUBLIC_` secrets | `.env*` files | 🔴 Critical |
| Unauth'd Server Actions | `"use server"` files | 🟠 High |
| Unauth'd sensitive API routes | `app/api/**/route.ts` | 🟠 High |
| Middleware matcher gaps | `middleware.ts` | 🟠 High |
| Missing input validation | Server Actions, API routes | 🟠 High |
| IDOR in `[id]` routes | dynamic route handlers | 🟠 High |
| `dangerouslySetInnerHTML` | components | 🟡 Medium |
| Missing security headers | `next.config.*` | 🟢 Low |
