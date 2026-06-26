---
name: nextjs-seo
description: Next.js App Router SEO optimization and auditing. Use when implementing or fixing SEO in a Next.js app — metadata and generateMetadata, viewport/themeColor, Open Graph and og/twitter images (file conventions + ImageResponse), web app manifest, favicons/icons, sitemap.xml, robots.txt, canonical URLs, hreflang and next-intl localised metadata (crawl/index layer only — defer runtime i18n to next-intl-app-router), JSON-LD structured data and rich results, E-E-A-T content quality, Sanity CMS SEO patterns (also load seo-aeo-best-practices for Sanity content/AEO strategy), Core Web Vitals only when tied to indexing or Search Console, redirects/indexing policy, programmatic SEO, security headers and privacy/consent, AI search/GEO/AEO and AI crawler rules (GPTBot, OAI-SearchBot), or diagnosing Google indexing problems (Search Console, "Discovered/Crawled - currently not indexed"). Also use to run a full SEO audit with evidence. For non-SEO performance work (Lighthouse, slow pages, bundle size without indexing context), defer to performance-optimizer. Not for general Next.js feature work, visual redesigns, or layout changes unrelated to SEO.
argument-hint: "[question or URL]"
---

# Next.js SEO Optimization

Comprehensive SEO guide for Next.js App Router applications.

## Scope

- **IS:** crawlability, metadata, structured data, canonicals, redirects, hreflang (next-intl), Core Web Vitals when tied to SEO/indexing, programmatic SEO, security/privacy headers, and error-page status behaviour.
- **IS NOT:** visual redesigns, layout changes, or general Next.js feature work unrelated to SEO.
- **Defer to `performance-optimizer`:** Lighthouse tuning, slow pages, caching, bundle size, or CWV fixes when the user has not mentioned indexing, Search Console, or SEO.
- **Defer to `next-intl-app-router`:** locale routing, middleware/proxy, message files, `useTranslations`, dates/numbers/plurals, language-switcher UX.
- **Defer to `translation-guidelines`:** copy translation quality between languages.
- **Also load `seo-aeo-best-practices` when Sanity is involved:** content strategy, EEAT, AEO, and CMS-level SEO patterns beyond Next.js implementation (this skill owns the Next.js wiring; Sanity plugin owns content principles).

**Allowed file surface:** metadata, structured data, semantic HTML, internal links, alt text, `app/sitemap.ts`, `app/robots.ts`, `next.config.ts` redirects and headers, error pages, performance tuning for SEO. Never touch component styling or layout.

## Workflow

Copy and track this checklist for audits and implementation projects:

```text
SEO progress:
- [ ] Step 1: Inventory routes and decide index intent per route
- [ ] Step 2: Fix crawl/index foundations (sitemap, robots, canonicals, redirects, status codes)
- [ ] Step 3: Implement metadata + structured data (+ next-intl localisation if applicable)
- [ ] Step 4: Improve semantics, internal links, and Core Web Vitals
- [ ] Step 5: Validate with references/checklist.md and report evidence
```

**Audit triage order:** (1) crawl/index — robots, sitemap, stray `noindex`, canonicals, redirect chains, soft 404s; (2) technical — HTTPS, CWV field data, mobile/desktop parity; (3) on-page — title/H1 uniqueness, internal links, thin pages to remove or `noindex`.

For steps 2–4, read the relevant reference before writing code (see [References](#references)).

## Quick SEO Audit

Run this checklist for any Next.js project:

1. **Check robots.txt**: `curl https://your-site.com/robots.txt`
2. **Check sitemap**: `curl https://your-site.com/sitemap.xml`
3. **Check metadata**: View page source, search for `<title>` and `<meta name="description">`
4. **Check JSON-LD**: View page source, search for `application/ld+json`
5. **Check Core Web Vitals**: Use PageSpeed Insights (pagespeed.web.dev) and the Search Console CWV report for field data — Lighthouse is lab-only and can't measure INP

## Essential Files

### app/layout.tsx - Root Metadata

```typescript
import type { Metadata, Viewport } from 'next';

// Viewport must be a separate export — `themeColor`, `colorScheme`, and
// `viewport` inside the `metadata` object are not supported.
export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 5,
  userScalable: true,
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#ffffff' },
    { media: '(prefers-color-scheme: dark)', color: '#0a0a0a' },
  ],
};

export const metadata: Metadata = {
  metadataBase: new URL('https://your-site.com'),
  title: {
    default: 'Site Title - Main Keyword',
    template: '%s | Site Name',
  },
  description: 'Compelling description with keywords (150-160 chars; Google typically displays this range)',
  keywords: ['keyword1', 'keyword2', 'keyword3'],
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: 'https://your-site.com',
    siteName: 'Site Name',
    title: 'Site Title',
    description: 'Description for social sharing',
    images: [{ url: '/og-image.png', width: 1200, height: 630, alt: 'Site preview' }],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Site Title',
    description: 'Description for Twitter',
    images: ['/og-image.png'],
  },
  alternates: {
    canonical: '/',
  },
  robots: {
    index: true,
    follow: true,
  },
};
```

### app/sitemap.ts - Dynamic Sitemap

```typescript
import type { MetadataRoute } from 'next';

export default function sitemap(): MetadataRoute.Sitemap {
  const baseUrl = 'https://your-site.com';

  return [
    {
      url: baseUrl,
      lastModified: new Date(),
      changeFrequency: 'weekly',
      priority: 1,
      images: [`${baseUrl}/og-image.png`], // Image Sitemap entry
    },
    {
      url: `${baseUrl}/about`,
      lastModified: new Date(),
      changeFrequency: 'monthly',
      priority: 0.8,
    },
  ];
}
```

### app/robots.ts - Robots Configuration

```typescript
import type { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  const baseUrl = 'https://your-site.com';

  return {
    rules: [
      {
        userAgent: '*',
        allow: '/',
        disallow: ['/api/', '/admin/'],
        // Do NOT disallow /_next/ — crawlers need render-critical CSS/JS
        // Do NOT add bot-specific rules (Googlebot, Bingbot) unless overriding wildcard
      },
    ],
    sitemap: `${baseUrl}/sitemap.xml`,
  };
}
```

> `host` was omitted intentionally — it's a non-standard directive Google ignores. Use canonical URLs / 301s to declare the preferred host instead. See [references/sitemap-robots.md](references/sitemap-robots.md).

### app/manifest.ts - Web App Manifest

```typescript
import type { MetadataRoute } from 'next';

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'Site Name',
    short_name: 'Site',
    description: 'Site description',
    start_url: '/',
    display: 'standalone',
    background_color: '#ffffff',
    theme_color: '#0a0a0a',
    icons: [
      { src: '/icon-192.png', sizes: '192x192', type: 'image/png' },
      { src: '/icon-512.png', sizes: '512x512', type: 'image/png' },
    ],
  };
}
```

Same `MetadataRoute` family as sitemap/robots; place at the root of `app/`. Minor for ranking, but expected for PWA completeness. (A static `app/manifest.json` works too.)

### OG / Twitter Images

Three ways to set social images — prefer the file conventions over hand-syncing URLs in the metadata object:

1. **External URL in metadata** (the `openGraph.images` / `twitter.images` examples above) — fine for externally hosted images.
2. **Static file convention (recommended default):** drop `opengraph-image.(png|jpg|gif)` and/or `twitter-image.*` into a route segment (`app/opengraph-image.png` for the root, `app/blog/opengraph-image.png` for `/blog`). Next.js auto-emits `og:image`/`twitter:image` + `:type/:width/:height`. A deeper, more specific image overrides one above it. Add alt text with a sibling `opengraph-image.alt.txt`. Build fails if the file exceeds 8 MB (OG) / 5 MB (Twitter).
3. **Dynamic generation with `ImageResponse`** (per-page/per-post images):

```tsx
// app/blog/[slug]/opengraph-image.tsx
import { ImageResponse } from 'next/og';

export const alt = 'Post preview';
export const size = { width: 1200, height: 630 };
export const contentType = 'image/png';

export default async function Image({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;            // params is a Promise in v16
  const post = await getPost(slug);
  return new ImageResponse(
    <div style={{ display: 'flex', fontSize: 64, width: '100%', height: '100%' }}>{post.title}</div>,
    { ...size },
  );
}
```

`ImageResponse` renders via Satori — **flexbox only, no `display: grid`**. These files are statically optimized at build time unless they read request-time data. See [references/metadata-api.md](references/metadata-api.md) for fonts, `generateImageMetadata`, and the favicon/`icon.tsx`/`apple-icon` conventions.

## Key Principles

### Cache Components & SEO

With `cacheComponents: true` in next.config.ts (the v16 top-level flag that unifies the old `experimental.dynamicIO`/`ppr`/`useCache`), use the `"use cache"` directive for SEO-critical server components:

```typescript
// app/(home)/sections/hero-section.tsx
import { cacheLife, cacheTag } from "next/cache";

export async function HeroSection() {
  "use cache";
  cacheLife("hours");   // SEO content that changes a few times/day; see profiles below
  cacheTag("hero");     // Invalidate via updateTag("hero") in a Server Action

  const data = await fetchData();
  return <div>{/* SEO-visible content */}</div>;
}
```

**Built-in `cacheLife` profiles** (`stale` / `revalidate` / `expire`): `seconds` (30s/1s/1m), `minutes` (5m/1m/1h), `hours` (5m/1h/1d), `days` (5m/1d/1w), `weeks` (5m/1w/30d), `max` (5m/30d/1y), and the implicit `default` (5m/15m/never). For SEO pages pick by how often content changes — `days` for blog/docs, `max` for legal/marketing. (`minutes` revalidates every 1 min — too aggressive for most SEO content.)

**Key rules:**
- `"use cache"` must be the first statement in the function body (or at the top of the file for file-level caching)
- No `cookies()`/`headers()`/`searchParams` inside a plain `"use cache"` scope — good for SEO, since indexable content should be request-agnostic. (`"use cache: private"` *does* allow them, but is never prerendered, so it never lands in the static SEO shell.)
- Invalidate with `updateTag("hero")` inside a Server Action (read-your-writes), or `revalidateTag("hero")` from a Route Handler / webhook — prefer these over `export const revalidate`
- Short-lived caches (`seconds`, or revalidate < 5 min) are excluded from the prerender and become dynamic holes that need a `<Suspense>` boundary — keep SEO-critical content on a longer profile so it stays in the static shell
- Sitemaps and metadata are static by default — only add `"use cache"` (+ `cacheTag`) if they fetch CMS/dynamic data you want to invalidate on publish

### Rendering Strategy for SEO

| Strategy | Use When | SEO Impact |
|----------|----------|------------|
| "use cache" | Server components with periodic data | Best - cached HTML, fast TTFB |
| SSG (Static) | Content rarely changes | Best - pre-rendered HTML |
| SSR | Dynamic content per request | Great - server-rendered |
| CSR | Dashboards, authenticated areas | Poor - avoid for SEO pages |

### Core Web Vitals Targets

| Metric | Target | Impact |
|--------|--------|--------|
| LCP (Largest Contentful Paint) | < 2.5s | Loading speed |
| INP (Interaction to Next Paint) | < 200ms | Interactivity |
| CLS (Cumulative Layout Shift) | < 0.1 | Visual stability |

- **Measured on field data, not lab.** Google ranks on the 75th percentile of real users (Chrome UX Report, 28-day rolling window, mobile/desktop separate). A URL group passes only when ≥75% of visits hit "Good" on all three. Use PageSpeed Insights and the Search Console CWV report for the real signal — **Lighthouse is lab-only and cannot measure INP**.
- **INP replaced FID** as a Core Web Vital on 2024-03-12; FID is deprecated. INP is the most commonly failed metric — prioritize it.
- **Page experience is a tiebreaker, not a standalone ranking system** (Google de-emphasized it). Good CWV won't rescue thin content; content relevance and quality come first. Treat CWV as baseline UX hygiene.
- **Myths to ignore:** 2026 SEO blogs falsely claim "LCP was lowered to 2.0s" and invent an "Engagement Reliability" metric. Neither exists in any Google/web.dev source — the thresholds above are current and unchanged since 2021.

### Ranking Signals Beyond Technical SEO

Metadata + CWV alone don't drive rankings. Keep these in mind:

- **Helpful content** is part of core ranking (since 2024-03), evaluated continuously — not an episodic penalty.
- **E-E-A-T** (Experience, Expertise, Authoritativeness, Trust): cite real authors/credentials and first-hand experience, especially on YMYL pages. Full guide: [references/eeat.md](references/eeat.md)
- **Mobile-first indexing is complete** (since 2024-07): Google indexes the mobile rendering only. Ensure the mobile view has the same content, metadata, and structured data as desktop; never block mobile resources. (Mostly automatic with Next.js responsive design.)

### Internationalisation (next-intl)

For multi-locale sites using **next-intl** (`app/[locale]/…`):

- One URL pattern for all locales; **`localeDetection: false`** — no IP or `Accept-Language` redirects
- Reciprocal **`alternates.languages`** (hreflang) with self-reference + `x-default` via `generateMetadata`
- Translate title, description, OG, JSON-LD, and image alt — not just body copy
- Localised **`app/sitemap.ts`** listing every locale URL
- Missing translation → **`notFound()`** (real 404), never 200 with wrong-language content
- Internal links via locale-aware **`Link`** from `@/i18n/navigation`

Full patterns, helpers, and CMS examples: [references/next-intl-seo.md](references/next-intl-seo.md)

### Redirects & indexing policy

- Permanent moves: **301/308**; temporary: **302/307**. No redirect chains — point straight to the final URL.
- Public pages default to `index, follow`; staging, admin, thin, or private routes get explicit `noindex` via `metadata.robots` (HTML) or `X-Robots-Tag` (non-HTML / whole environments).
- Missing content → **`notFound()`** (real 404). Maintenance → **503 + `Retry-After`**.

```typescript
// Per-page noindex
export const metadata: Metadata = { robots: { index: false, follow: false } };
```

```typescript
// next.config.ts — staging environment only
async headers() {
  return [{
    source: '/:path*',
    headers: [{ key: 'X-Robots-Tag', value: 'noindex' }],
  }];
}
```

### Programmatic SEO (pages at scale)

- Validate search demand for the repeatable pattern before generating pages
- Each page needs unique value backed by defensible data — templated text swaps are doorway pages
- Clean subfolder URLs, hub-and-spoke linking, breadcrumbs on every page
- Index only strong pages; `noindex` the long tail; monitor indexation and cannibalisation in Search Console

Full guidance: [references/programmatic-seo.md](references/programmatic-seo.md)

## References

- **Metadata API**: See [references/metadata-api.md](references/metadata-api.md) — generateMetadata, OG/icon file conventions, ImageResponse, manifest
- **Sitemap & Robots**: See [references/sitemap-robots.md](references/sitemap-robots.md)
- **JSON-LD Structured Data**: See [references/json-ld.md](references/json-ld.md)
- **next-intl & hreflang**: See [references/next-intl-seo.md](references/next-intl-seo.md) — localised metadata, sitemap, middleware, CMS
- **Programmatic SEO**: See [references/programmatic-seo.md](references/programmatic-seo.md) — scalable landing pages, indexation policy
- **Technical hardening**: See [references/technical-hardening.md](references/technical-hardening.md) — security headers, privacy/consent, resilience
- **E-E-A-T & content quality**: See [references/eeat.md](references/eeat.md) — author signals, YMYL, trust
- **Sanity CMS SEO**: See [references/cms-sanity-seo.md](references/cms-sanity-seo.md) — stega, GROQ sitemap, redirects. Also load **`seo-aeo-best-practices`** (Sanity plugin) for content strategy, EEAT, and AEO principles.
- **AI Search (GEO/AEO) & AI Crawlers**: See [references/ai-search.md](references/ai-search.md)
- **SEO Audit Checklist**: See [references/checklist.md](references/checklist.md)
- **Troubleshooting**: See [references/troubleshooting.md](references/troubleshooting.md)

## Validation (step 5)

- Copy [references/checklist.md](references/checklist.md) and mark every item pass/fail
- Check HTTP response headers for correct status codes and redirect targets (`curl -sI`)
- Confirm `robots.txt` directives and that `sitemap.xml` lists all indexed routes with valid absolute URLs
- Verify canonical, OpenGraph, and Twitter Card tags appear in **served HTML source**, not just the React tree
- CWV on **field data** (PageSpeed Insights / Search Console) — Lighthouse is lab-only and cannot measure INP
- Validate JSON-LD per URL with Google's Rich Results Test
- Report remaining blockers with exact URLs and recommended action

## Gotchas

### Next.js & metadata

1. **Mixing next-seo with Metadata API** — Use only Metadata API in App Router
2. **Missing canonical URLs** — Always set `alternates.canonical`; keep one host, one casing, one trailing-slash policy
3. **Conflicting canonicals** — Trailing slash vs none, `www` vs apex, or uppercase variants split ranking signal
4. **Missing metadataBase** — Required for relative URLs in metadata and hreflang
5. **Viewport in metadata** — Must be a separate export
6. **Mixing metadata object and generateMetadata** — Use one or the other in the same route segment
7. **Duplicating icons in metadata + file conventions** — Prefer `favicon.ico`/`icon.*`/`opengraph-image.*`; they override the metadata object

### Crawling & indexing

8. **Blocking `/_next/` in robots.txt** — Crawlers need render-critical CSS/JS; never disallow `/_next/`
9. **Blocking crawlers unintentionally** — Check `robots.txt`, stray `noindex`, and auth walls on routes meant to rank before shipping
10. **Using CSR for SEO pages** — Ship SSG, SSR, or `"use cache"` HTML for indexable content
11. **Soft 404s** — Missing pages must return **real 404**, not 200 with a friendly message; search engines refuse to index them
12. **URL changes without redirects** — Permanent moves need **301/308** straight to the final URL; no redirect chains
13. **Maintenance windows** — Return **503 + `Retry-After`**, not 200 or 404, so the site isn't deindexed
14. **Thin / doorway pages at scale** — Templated text swaps hurt sitewide quality; index only pages with unique value

### Structured data & i18n

15. **JSON-LD that doesn't match visible content** — Google treats mismatched markup as spam
16. **Non-reciprocal hreflang** — Search engines ignore entire hreflang sets if alternates aren't mutual; omit locales with no translation
17. **Half-translated pages** — Localised body with English `<title>` / OG / JSON-LD fails locale intent
18. **Auto locale redirects** — IP or `Accept-Language` redirects break crawlers and shared links; URL is source of truth

### AI crawlers & security

19. **Blanket-blocking AI crawlers** — `GPTBot disallow: /` blocks training but can affect AI search visibility; don't accidentally block citation bots (OAI-SearchBot, PerplexityBot). See [references/ai-search.md](references/ai-search.md)
20. **HSTS preload too early** — Don't set `Strict-Transport-Security` with `preload`/`includeSubDomains` until every subdomain is HTTPS; it's effectively irreversible

## Quick Fixes

### Add noindex to a page

```typescript
export const metadata: Metadata = {
  robots: {
    index: false,
    follow: false,
  },
};
```

### Dynamic metadata per page

```typescript
type Props = { params: Promise<{ id: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { id } = await params;            // params is a Promise in current Next.js
  const product = await getProduct(id);
  return {
    title: product.name,
    description: product.description,
  };
}
```

### Canonical for dynamic routes

```typescript
type Props = { params: Promise<{ slug: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { slug } = await params;
  return {
    alternates: {
      canonical: `/products/${slug}`,
    },
  };
}
```
