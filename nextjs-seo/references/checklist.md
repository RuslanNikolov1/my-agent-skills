# Next.js SEO Audit Checklist

## Contents

Critical | Important | Nice to Have | Audit Tools | Red Flags

## Critical (Must Have)

### Technical Foundation

- [ ] `metadataBase` set in root layout
- [ ] Unique `<title>` on every page (50-60 chars)
- [ ] Unique `meta description` on every page (150-160 chars)
- [ ] `robots.txt` exists and allows crawling
- [ ] `sitemap.xml` exists and is valid
- [ ] Sitemap submitted to Google Search Console
- [ ] No `noindex` on pages you want indexed
- [ ] Canonical URLs set for all pages
- [ ] `viewport` exported separately from `metadata`
- [ ] `favicon.ico` (or `app/icon`) present — appears in Google SERPs and browser tabs
- [ ] `app/manifest.ts` present (name, short_name, theme_color, icons) — PWA completeness

### Rendering

- [ ] SEO pages use SSG, SSR, or `"use cache"` Cache Components (not CSR)
- [ ] Content visible without JavaScript (test with JS disabled)
- [ ] No client-side only content for SEO-critical text

### Core Web Vitals

- [ ] LCP (Largest Contentful Paint) < 2.5s
- [ ] INP (Interaction to Next Paint) < 200ms
- [ ] INP optimized (INP replaced FID in March 2024)
- [ ] CLS (Cumulative Layout Shift) < 0.1
- [ ] CWV checked on FIELD data (PageSpeed Insights / Search Console CrUX, 75th percentile) — not just Lighthouse (Lighthouse can't measure INP)
- [ ] Mobile parity — same content/metadata/structured-data on mobile (mobile-first indexing complete since July 2024)

## Important (Should Have)

### Structured Data

- [ ] WebSite schema on homepage
- [ ] Organization schema
- [ ] Relevant page-specific schemas (Article, Product) for rich results
- [ ] FAQPage = AI-search/LLM signal only (rich results removed 2026-05-07)
- [ ] JSON-LD matches visible content
- [ ] Validated with Rich Results Test

### Content quality & E-E-A-T (articles, YMYL, blog)

- [ ] Author name and credentials visible on content pages
- [ ] Publish and update dates displayed
- [ ] Primary sources cited where claims need backing
- [ ] YMYL content reviewed by qualified expert (if applicable)

See [eeat.md](eeat.md).

### Open Graph & Social

- [ ] Open Graph title and description
- [ ] OG image (1200x630 recommended)
- [ ] OG image set via `opengraph-image` file convention or `ImageResponse` (not just a hardcoded URL)
- [ ] Twitter Card configured
- [ ] Images tested with Facebook Debugger

### Links & Navigation

- [ ] Internal links use `<Link>` component (locale-aware `Link` from `@/i18n/navigation` when using next-intl)
- [ ] No broken internal links
- [ ] Logical URL structure
- [ ] Breadcrumbs implemented (if applicable)
- [ ] Single h1 per page with logical h2–h6 hierarchy

### Redirects & status codes

- [ ] Moved URLs return 301/308 (permanent), not 302/307; no redirect chains
- [ ] Missing pages return real 404 (no soft 404s returning 200)
- [ ] Staging/admin/thin pages have explicit `noindex` / `X-Robots-Tag`
- [ ] Maintenance returns 503 + `Retry-After` (not 200 or 404)

### Images

- [ ] All images have `alt` text
- [ ] Images use `next/image` component
- [ ] Images in sitemap
- [ ] Appropriate image sizes (no oversized images)

## Nice to Have (Optimization)

### Performance

- [ ] JavaScript bundle optimized
- [ ] Fonts use `next/font`
- [ ] Critical CSS inlined
- [ ] Third-party scripts deferred

### International — next-intl (if applicable)

- [ ] One URL pattern for all locales (`/[locale]/…` subdirectory)
- [ ] No IP / `Accept-Language` auto-redirects (`localeDetection: false`)
- [ ] Reciprocal `alternates.languages` (hreflang) with self-ref + `x-default` on every indexable page
- [ ] Title, description, OG, JSON-LD, and image alt translated per locale
- [ ] Localised sitemap listing every locale URL (see [next-intl-seo.md](next-intl-seo.md))
- [ ] Missing translation returns real 404, not 200
- [ ] Internal links use locale-aware `Link` from `@/i18n/navigation`

### Security & privacy (if client-facing / production)

- [ ] HTTPS enforced; HTTP→HTTPS redirect; HSTS set (preload only when all subdomains are HTTPS)
- [ ] `Content-Security-Policy`, `X-Content-Type-Options: nosniff`, `frame-ancestors`
- [ ] `Referrer-Policy` and `Permissions-Policy` set
- [ ] Third-party scripts use Subresource Integrity where applicable
- [ ] Cookies use `Secure` / `HttpOnly` / `SameSite` flags
- [ ] `/.well-known/security.txt` published
- [ ] Privacy policy present and accurate
- [ ] Non-essential cookies gated behind opt-in consent (EU/UK)
- [ ] Global Privacy Control (`Sec-GPC: 1`) honoured

See [technical-hardening.md](technical-hardening.md) for header values and rollout notes.

### Resilience

- [ ] Custom 404/500 return correct status codes; no leaked stack traces
- [ ] Uptime monitored from outside own infra

### Advanced

- [ ] Video sitemap (if video content)
- [ ] News sitemap (if news site)
- [ ] App links configured (if mobile app)

## Final validation

- [ ] Copy this checklist; mark every item pass/fail with evidence
- [ ] `curl -sI` on key URLs — correct status codes and redirect targets
- [ ] Canonical, OG, and Twitter tags in served HTML source (View Source, not DevTools React tree)
- [ ] CWV checked on field data (PageSpeed Insights / Search Console CrUX)
- [ ] JSON-LD validated per URL (Rich Results Test)
- [ ] Social sharing previews render correctly
- [ ] Report remaining blockers with exact URLs and recommended action

## Audit Tools

| Tool | Purpose | URL |
|------|---------|-----|
| Google Search Console | Indexing, errors | search.google.com/search-console |
| PageSpeed Insights | Core Web Vitals | pagespeed.web.dev |
| Rich Results Test | Structured data | search.google.com/test/rich-results |
| Lighthouse | Overall audit | Chrome DevTools |
| Mobile-Friendly Test | Mobile usability | search.google.com/test/mobile-friendly |
| Ahrefs/Semrush | Backlinks, rankings | ahrefs.com / semrush.com |

## Quick Commands

```bash
# Check robots.txt
curl https://your-site.com/robots.txt

# Check sitemap
curl https://your-site.com/sitemap.xml

# Check if indexed
# Search in Google: site:your-site.com

# Test mobile rendering
# Use Chrome DevTools device emulation
```

## Red Flags to Watch

1. **"Discovered - currently not indexed"** in GSC
2. **Duplicate title tags** across pages
3. **Missing canonical URLs**
4. **Blocked resources in robots.txt**
5. **Slow LCP (> 4s)**
6. **High CLS (> 0.25)**
7. **No structured data**
8. **Missing alt text on images**
