# Security audit examples

Illustrative outputs for Ruslan's app shapes. Format matches SKILL.md template.

---

## Example 1 · Signup API (hairdresser-app)

**Invocation:** `security-audit review /api/signup`

```markdown
# Security audit: /api/signup

**Attack surface:** Anonymous POST creates Sanity documents and triggers notification email.
**Stack detected:** Next.js Route Handler, Sanity write client, Mailtrap

## Findings

### 🟠 High
- **[SEC-001] No rate limiting** — `src/app/api/signup/route.ts`
  - **Risk:** Spam signups flood Sanity + notification inbox
  - **Exploit:** `while(true) fetch('/api/signup', { method:'POST', body })`
  - **Fix:** Add IP rate limit (Upstash) or Vercel WAF rule; honeypot field

### 🟡 Medium
- **[SEC-002] Manual validation without length caps** — `src/lib/signup/submitSignup.ts:10`
  - **Risk:** Multi-MB `name` stored; email header abuse in notifications
  - **Exploit:** POST `{ name: "A".repeat(1e6), ... }`
  - **Fix:** Zod schema with `.max(100)` on strings, `.max(254)` on email

- **[SEC-003] Write-token misconfig message** — `submitSignup.ts:44`
  - **Risk:** Reveals env var name `SANITY_API_WRITE_TOKEN` to end user
  - **Exploit:** Informational — aids recon
  - **Fix:** Generic "Формата временно не е налична."

### 🟢 Low
- **[SEC-004] Email regex only** — `submitSignup.ts:9`
  - **Risk:** Accepts unusual addresses; low practical risk
  - **Fix:** `z.string().email()` when migrating to Zod

## Fixed
- SEC-002: added shared `signupSchema` with max lengths
- SEC-003: generic error message

## Deferred
- SEC-001: rate limit — needs Upstash or Vercel config (flagged for user)
```

---

## Example 2 · Studio gate (hairdresser-app — mostly passing)

**Invocation:** `security-audit review studio gate`

```markdown
# Security audit: studio gate

**Attack surface:** `/studio` Sanity CMS in production.
**Stack detected:** Next.js middleware, HTTP Basic Auth

## Findings

### 🟢 Low
- **[SEC-001] Dev mode open without creds** — `middleware.ts:12`
  - **Risk:** Local `/studio` accessible on shared network
  - **Fix:** Document; optional: require creds in dev too

## Passing controls
- ✅ `safeEqual` timing-safe compare (`gate.ts`)
- ✅ 404 when creds unset in production (no existence leak)
- ✅ Narrow matcher `/studio` only
- ✅ `atob` parse in try/catch

## Fixed
- (none required)
```

---

## Example 3 · Cloudinary sign (real-estate-app)

**Invocation:** `security-audit review cloudinary sign`

```markdown
# Security audit: /api/cloudinary/sign

**Attack surface:** Returns upload signature + api_key to any caller.
**Stack detected:** Next.js Route Handler, Cloudinary, Supabase

## Findings

### 🔴 Critical
- **[SEC-001] Unauthenticated signature generation** — `route.ts:4`
  - **Risk:** Anyone uploads to your Cloudinary account; quota/billing abuse
  - **Exploit:** `curl -X POST /api/cloudinary/sign` → use signature to upload
  - **Fix:** Require `getUser()` session; optionally verify admin role

### 🟡 Medium
- **[SEC-002] Signature params logged** — `route.ts:44`
  - **Risk:** Upload signing details in Vercel function logs
  - **Fix:** Remove `console.log` block

## Fixed
- SEC-001: added `getUser()` guard; 401 if missing
- SEC-002: removed debug log
```

---

## Example 4 · Admin auth (burgas-massage-app)

**Invocation:** `security-audit review admin auth`

```markdown
# Security audit: /api/admin/auth

**Attack surface:** Cookie-based admin session for site management.
**Stack detected:** Next.js Route Handler, cookie auth

## Findings

### 🟠 High
- **[SEC-001] Forgeable session cookie** — `route.ts:42`
  - **Risk:** Attacker sets `admin-auth=authenticated` in browser → admin access
  - **Exploit:** DevTools → Application → Cookies → set value
  - **Fix:** Signed session (iron-session / JWT) with server secret

### 🟡 Medium
- **[SEC-002] Timing-unsafe password compare** — `route.ts:38`
  - **Risk:** Theoretical credential leak via timing
  - **Fix:** `safeEqual(username, ADMIN_USER)` and `safeEqual(password, ADMIN_PASS)`

- **[SEC-003] Credentials in env without rotation docs** — `route.ts:7`
  - **Risk:** Long-lived `ADMIN_PASS` in Vercel env
  - **Fix:** Document rotation; consider hashed password storage

## Passing controls
- ✅ `httpOnly`, `secure`, `sameSite: 'strict'`
- ✅ `Cache-Control: no-store` on auth responses

## Fixed
- SEC-001: migrated to iron-session with `SESSION_SECRET`
- SEC-002: `safeEqual` compare
```

---

## Example 5 · Supabase approve route (real-estate-app)

**Invocation:** `security-audit review pending approve`

```markdown
# Security audit: /api/properties/pending/[id]/approve

**Attack surface:** Promotes pending listing to live properties table.
**Stack detected:** Supabase SSR auth, admin client

## Findings

### 🟠 High
- **[SEC-001] Hardcoded admin email** — `route.ts:52`
  - **Risk:** Admin access tied to one email; no audit trail; can't delegate
  - **Exploit:** Compromise that email account → full admin
  - **Fix:** `user.app_metadata.role === 'admin'` or `admin_users` table

### 🟡 Medium
- **[SEC-002] No ID format validation** — `route.ts:44`
  - **Risk:** Odd UUID inputs cause confusing errors
  - **Fix:** `z.string().uuid()` on `id` param

## Passing controls
- ✅ `getUser()` before action (not `getSession()`)
- ✅ Admin client used server-side only
- ✅ 401/403 distinction correct

## Fixed
- SEC-001: check `app_metadata.role` set via Supabase dashboard
```

---

## Example 6 · Revalidate webhook (hairdresser-app — passing)

**Invocation:** `security-audit review revalidate webhook`

```markdown
# Security audit: /api/revalidate

**Attack surface:** Sanity webhook triggers on-demand revalidation.
**Stack detected:** @sanity/webhook, Next.js

## Passing controls
- ✅ HMAC signature validation before parse
- ✅ Fail closed when `SANITY_REVALIDATE_SECRET` missing (500)
- ✅ Type filter ignores non-module payloads
- ✅ Generic error messages to caller

## Findings

### 🟢 Low
- **[SEC-001] No replay dedup** — `route.ts`
  - **Risk:** Duplicate webhook deliveries revalidate twice (harmless but noisy)
  - **Fix:** Optional idempotency by `_id` + `_updatedAt`

## Fixed
- (none — optional SEC-001 deferred)
```

---

## Example 7 · Environment surface (whole project)

**Invocation:** `security-audit review env audit only`

```markdown
# Security audit: environment variables

**Attack surface:** All `process.env` and `NEXT_PUBLIC_*` usage in hairdresser-app.
**Stack detected:** Next.js, Sanity, Mailtrap

## Findings

### 🟢 Low
- **[SEC-001] `.env.example` complete** — all server secrets documented with scope comments

### Passing
- ✅ No write token in client components
- ✅ Sanity project ID/dataset correctly public
- ✅ Mailtrap token only in server lib

## Next steps
Run `security-audit review /api/signup fix all` for endpoint hardening.
```

---

## Audit-only example

**Invocation:** `security-audit review middleware audit only`

When user says **audit only**, emit findings with no ## Fixed section. End with:

```markdown
## Next steps
Run `security-audit review middleware fix critical` to apply 🔴 fixes.
```
