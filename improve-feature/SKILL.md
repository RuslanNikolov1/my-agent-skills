---
name: improve-feature
description: Harden and optimize an existing feature. Invoke with /improve-feature and name the feature, route, or files. Pipeline — audit edge-cases, security-audit, performance-optimizer, vercel-react-best-practices, nextjs-seo; fix; review-security; verify. For building new UI, use new-feature instead.
disable-model-invocation: true
---

# Improve Feature

Orchestrator for hardening, securing, optimizing, and SEO-tuning an **existing** feature in a Next.js + TypeScript app.

The user invokes `/improve-feature` and names the target (route, component, feature label, or files). Default: **audit and fix** unless the user says `audit only`.

For net-new UI work, use `/new-feature` instead.

## Pipeline overview

```
/improve-feature "<target>"
    → ① Scope the target
    → ② Audit pass (domain skills, in order)
    → ③ Fix pass (implement findings)
    → ④ review-security (subagent on diff)
    → ⑤ verification-before-completion
    → ⑥ finishing-a-development-branch (optional)
```

**Escape hatches:**

- Root-cause bugs during audit/fix → `systematic-debugging`
- Architecture or RSC validity issues → `next-best-practices`

---

## Phase ① — Scope the target

From the user's message, identify:

- **Target** — file, directory, route, component, or feature label (e.g. `gallery`, `/contact`, `src/components/Gallery.tsx`)
- **Modifiers** — `audit only`, `fix critical`, `fix all` (default: fix 🔴 and 🟡)
- **SEO scope** — is this a public/marketing route that needs crawl/index checks?

If the target is ambiguous, ask **one** focused question, then continue.

Explore project context: read the target files, related routes, data sources, and existing tests.

---

## Phase ② — Audit pass (mandatory, in order)

Read each skill's `SKILL.md` and relevant topic/rule files. Track progress:

```
Domain checklist:
- [ ] Edge cases — edge-cases
- [ ] Security — security-audit
- [ ] Optimization — performance-optimizer + vercel-react-best-practices
- [ ] SEO — nextjs-seo
```

Run audits **in this order** — later skills may defer back to earlier ones (e.g. security ↔ edge-cases).

### 1. Edge cases — `edge-cases`

Path: `~/.agents/skills/edge-cases/SKILL.md`

Invoke pattern: `edge-cases review <target>`

Cover: null/empty states, async races, form validation gaps, CMS field guards, i18n fallbacks, URL/state desync, loading/error/retry, double-submit.

Read `categories.md`, `stack-patterns.md`, or `examples.md` when the target matches those patterns.

Defer: form wiring → `react-hook-form-zod`; a11y → `radix-ui-design-system`; root-cause bugs → `systematic-debugging`.

### 2. Security — `security-audit`

Path: `~/.agents/skills/security-audit/SKILL.md`

Invoke pattern: `security-audit review <target>`

Cover: `NEXT_PUBLIC_` leaks, Server Action auth, middleware matchers, API validation, Sanity webhooks, Supabase RLS, XSS, unsafe cookies, CSRF, IDOR.

Read `nextjs-patterns.md`, `categories.md`, `stack-patterns.md` as needed.

Defer: logic gaps → `edge-cases`; component a11y → `radix-ui-design-system`.

**Note:** This phase audits and fixes. Subagent review happens in Phase ④ (`review-security`).

### 3. Optimization — `performance-optimizer` + `vercel-react-best-practices`

Paths:

- `~/.agents/skills/performance-optimizer/SKILL.md`
- `~/.agents/skills/vercel-react-best-practices/SKILL.md`

**performance-optimizer** — diagnose slow paths, Core Web Vitals, caching, images, fonts, bundle issues for this target.

**vercel-react-best-practices** — apply CRITICAL and HIGH rules (`async-`, `bundle-`, `server-` prefixes) to the target code. Read individual rule files under `rules/` for specific issues found.

If SEO/indexing is **not** in scope, prefer these over CWV work in `nextjs-seo`. If the user mentioned Search Console or indexing, SEO phase owns CWV tied to crawl/index.

Also apply `next-best-practices` when fixes touch RSC boundaries, data placement, or route structure.

### 4. SEO — `nextjs-seo`

Path: `~/.agents/skills/nextjs-seo/SKILL.md`

Apply when the target is a **public route** or affects crawlability, metadata, structured data, canonicals, sitemap/robots, hreflang, or indexing.

Read relevant references under `references/` (metadata-api, json-ld, sitemap-robots, checklist, etc.).

**Allowed surface:** metadata, structured data, semantic HTML, internal links, alt text, sitemap/robots, redirects/headers — **not** visual redesign or layout.

Defer: runtime i18n → `next-intl-app-router`; general perf without SEO context → `performance-optimizer`; Sanity content strategy → `seo-aeo-best-practices`.

Skip this phase only when the target is clearly non-public (admin, studio, auth internals, pure client widgets with no indexable page).

---

## Phase ③ — Fix pass

Implement fixes from the audit unless the user said `audit only`.

**Priority:** 🔴 critical → 🟡 important → 🟢 nice-to-have (unless user said `fix critical` or `fix all`).

For many independent fixes across domains, optionally use `subagent-driven-development` with a short fix plan. For scoped targets, fix inline.

**Conditional TDD — `test-driven-development`**

Use when a fix changes **behavior** (validation rules, auth checks, redirect logic, API contracts). Skip for pure perf or metadata tweaks unless tests already exist.

Re-run relevant audits mentally after fixes — ensure security fixes didn't introduce edge-case regressions.

---

## Phase ④ — Security review (subagent)

**Skill:** `review-security`

After fixes are applied, launch the `security-review` subagent on the local diff (follow `review-security` skill exactly).

This catches issues the audit pass may have missed and validates the fix diff.

Skip only if the user said `audit only` and no code was changed.

---

## Phase ⑤ — Verification before completion

**Skill:** `verification-before-completion` (Superpowers)

Run fresh verification commands (lint, build, test). Show evidence. No "done" claims without command output.

**Improve checklist:**

- [ ] Edge cases: empty/null/loading/error paths handled
- [ ] Security: no new secret exposure; auth on mutations; input validated
- [ ] Performance: no new waterfalls; bundle/RSC serialization reasonable
- [ ] SEO (if applicable): metadata, canonical, structured data, indexability
- [ ] No unrelated refactors outside the target scope

---

## Phase ⑥ — Finish branch (optional)

**Skill:** `finishing-a-development-branch` (Superpowers)

Use when work is on a feature branch and the user wants merge/PR options. Skip for in-place improvements on main.

---

## Boundaries

| Topic | Defer to |
|-------|----------|
| New UI from scratch | `new-feature` |
| Visual redesign / Hallmark | `hallmark` |
| SASS / responsive / skeletons / a11y | `new-feature` domain skills |
| Forms + Zod implementation | `react-hook-form-zod` |
| i18n routing | `next-intl-app-router` |
| General code review (non-security) | `parallel-code-review` or `requesting-code-review` |
| Bug root-cause investigation | `systematic-debugging` |

## Superpowers skills NOT in this pipeline

- `brainstorming`, `writing-plans` — for new work; use `/new-feature`
- `executing-plans` — use `subagent-driven-development` if needed during fix pass
- `requesting-code-review` — optional add-on; `review-security` covers security review here
