---
name: security-audit
description: >-
  Audits and fixes security issues in Next.js App Router apps — NEXT_PUBLIC_
  leaks, Server Action auth, middleware matchers, API route validation, Sanity
  webhooks, Supabase RLS, XSS, and unsafe cookies. Use when the user invokes
  security-audit, asks to review/fix vulnerabilities, or scans Next.js env vars,
  middleware, or API routes.
disable-model-invocation: true
---

# Security Audit

Systematic security review for Ruslan's Next.js App Router apps: Sanity CMS, Supabase, Route Handlers, Server Actions, middleware, Mailtrap/Cloudinary.

**Default behaviour: audit and fix.** Find vulnerabilities, then implement fixes unless the user says audit-only.

---

## Boundaries

| This skill | Defer to |
|------------|----------|
| Auth bypass, secret leaks, injection, XSS, CSRF, IDOR, webhook forgery | — |
| Next.js env exposure, Server Actions, middleware matchers, security headers | — (see nextjs-patterns.md) |
| Null/empty states, race conditions, stale CMS data | `edge-cases` |
| WCAG, keyboard, screen readers, component a11y | `radix-ui-design-system` |

**Invocation examples:**

| Scenario | Command |
|----------|---------|
| "Review my PR for security" | `security-audit review <branch changes or files>` |
| "Audit the signup API" / "scan NEXT_PUBLIC_" / "secure /studio" | `security-audit review <target>` |

---

## Invocation

```
security-audit review <target>
```

**Target:** file, directory, route (`/api/signup`), feature (`studio gate`, `middleware`), env surface, `next.config`, or user flow.

**Modifiers:**
- `audit only` — findings, no edits
- `fix critical` — fix 🔴 only
- `fix all` — fix 🔴 and 🟠 (default when user says "review and fix")

**Optional first pass** (whole project):

```bash
bash ~/.cursor/skills/security-audit/scripts/scan.sh .
```

---

## Review workflow

```
Security audit:
- [ ] 0. (Optional) Run scripts/scan.sh for automated candidates
- [ ] 1. Scope — read target + dependencies (middleware, env, callers)
- [ ] 2. Map trust boundaries — client vs server, public vs gated
- [ ] 3. Inventory secrets — .env.example, NEXT_PUBLIC_*, next.config env
- [ ] 4. Run Next.js pass — see nextjs-patterns.md
- [ ] 5. Run category pass — see categories.md
- [ ] 6. Run stack pass — see stack-patterns.md
- [ ] 7. Emit findings — severity + exploit path + fix
- [ ] 8. Fix (unless audit-only) — smallest secure diff
- [ ] 9. Verify — no secrets in client bundle; auth paths re-tested
```

### Step 1 · Trust boundaries

For each entry point, answer:

1. **Who can call it?** (anonymous, authenticated user, admin, webhook only)
2. **What can they send?** (body, query, headers, cookies, slug param)
3. **What does it access?** (DB write, service-role, write token, email send, file upload)
4. **What leaks on failure?** (stack trace, env var name, internal IDs)

### Step 2 · Severity

| Tier | Criteria |
|------|----------|
| 🔴 **Critical** | Exploitable now: auth bypass, secret in client, unsigned webhook, service-role exposed, SQL/command injection |
| 🟠 **High** | Missing auth on sensitive action, IDOR, weak session, stored/reflected XSS, admin by email string |
| 🟡 **Medium** | No rate limit on abuse-prone public POST, verbose errors, timing-unsafe compare, missing CSRF on cookie auth |
| 🟢 **Low** | Missing security headers, debug logs in prod, defense-in-depth hardening |

### Step 3 · Emit findings

```markdown
# Security audit: <target>

**Attack surface:** <one sentence>
**Stack detected:** <list>

## Findings

### 🔴 Critical
- **[SEC-001] <title>** — `path:line`
  - **Risk:** <what an attacker gains>
  - **Exploit:** <minimal attack path>
  - **Fix:** <concrete change>

### 🟠 High
- **[SEC-002] …**

### 🟡 Medium / 🟢 Low
- **[SEC-003] …**

## Fixed
- SEC-001: <what changed>

## Deferred
- SEC-003: <why, if any>
```

### Step 4 · Fix discipline

1. **Smallest secure diff** — add auth check, Zod schema, signature verify, remove log. No drive-by refactors.
2. **Never weaken existing controls** to make tests pass.
3. **Don't commit secrets** — use env vars; update `.env.example` with placeholder only.
4. **Prefer established patterns** from Ruslan's repos (see stack-patterns.md).
5. **Generic errors to clients** — log details server-side only.
6. After fixes, re-check for **new** exposure introduced (e.g. auth check that leaks user existence).

### Step 5 · Verify

Minimum before handing back:
- Grep changed files for `process.env.` — no server secrets in `"use client"` files or `NEXT_PUBLIC_*`
- Check `next.config` has no sensitive `env` block
- Mentally trace: unauthenticated call to each fixed endpoint
- If auth added: confirm middleware matcher doesn't create redirect loops
- If Zod added: invalid body, oversized body, wrong types all return 400

---

## Reference files

| File | Contents |
|------|----------|
| [nextjs-patterns.md](nextjs-patterns.md) | NEXT_PUBLIC_, Server Actions, API routes, middleware, headers, grep commands |
| [categories.md](categories.md) | Full taxonomy (A/E/I/W/S/C/X/H/R/L/P) |
| [stack-patterns.md](stack-patterns.md) | Sanity, Supabase, Cloudinary, Mailtrap, per-repo probes |
| [examples.md](examples.md) | Sample audit outputs |
| [scripts/scan.sh](scripts/scan.sh) | Automated first-pass scanner |

---

## Category quick reference

| Code | Domain | Top probes |
|------|--------|------------|
| A | Auth & sessions | missing gate, hardcoded admin email, static cookie value |
| E | Env & secrets | `NEXT_PUBLIC_` misuse, `next.config env`, token in repo |
| I | Input validation | unvalidated `request.json()`, missing length limits, no Zod on server |
| W | Webhooks & signing | missing HMAC, shared secret in URL, replay without idempotency |
| S | Supabase & DB | service role client-side, RLS bypass, `.single()` error leak |
| C | CMS & Sanity | write token exposure, draft mode open, Studio public in prod |
| X | XSS & output | `dangerouslySetInnerHTML`, unsanitized CMS HTML, open redirect |
| H | HTTP & cookies | missing httpOnly/secure/sameSite, CORS `*`, cache on auth |
| R | Rate & abuse | public POST spam, email bomb, signup flood, enumeration |
| L | Logging & errors | `console.log` secrets, stack traces in JSON response |

---

## Project context (from GitHub portfolio)

| Repo | Security posture notes |
|------|------------------------|
| `hairdresser-app` | ✅ `safeEqual` basic auth, webhook signature, studio 404 when disabled — probe signup rate limit, Zod |
| `real-estate-app` | ⚠️ Cloudinary sign without auth, hardcoded admin email — probe all `/api/*` |
| `burgas-massage-app` | ⚠️ static `admin-auth` cookie, plain `===` compare — probe session fixation |
| `portfolio-website` | RHF + Zod forms — verify server-side mirror |
| `lawyer-app` | Marketing + Sanity — studio gate, env surface |
| `association-app` | Vite SPA — client-side secrets, API base URL exposure |

---

## Anti-patterns (this skill must not do)

- Full penetration test or OWASP report — focused code audit only
- Add auth library (Clerk/Auth0) without user asking — fix with minimal controls first
- Rotate or invent API keys — tell user to rotate in provider dashboard
- Skip PR/branch scope when user names a specific file or route — audit that target directly
- "Fix" by disabling a feature entirely without noting UX impact
- Flag public signup/contact routes as missing auth without checking validation + rate limits
