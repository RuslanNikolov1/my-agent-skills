# Internationalisation with next-intl (SEO layer)

How multilingual sites tell search engines which version to serve. Covers URL strategy, `hreflang`, localised metadata, sitemaps, and CMS patterns with **next-intl** on the App Router.

For runtime formatting (dates, numbers, ICU plurals) and language-switcher UX, use `edge-cases` / `translation-guidelines` — this doc is the **SEO head + crawl** layer only.

## Contents

- [Assumed setup](#assumed-setup)
- [URL strategy](#url-strategy)
- [Middleware & locale detection](#middleware--locale-detection)
- [Localised metadata](#localised-metadata)
- [hreflang via alternates.languages](#hreflang-via-alternateslanguages)
- [Localised sitemap](#localised-sitemap)
- [CMS content per locale](#cms-content-per-locale)
- [JSON-LD & Open Graph locale](#json-ld--open-graph-locale)
- [Internal links](#internal-links)
- [Checklist](#checklist)

## Assumed setup

Typical App Router layout:

```
app/
  [locale]/
    layout.tsx          # NextIntlClientProvider (client) or pass messages from server
    page.tsx
    blog/[slug]/page.tsx
  sitemap.ts
  robots.ts
i18n/
  routing.ts            # defineRouting({ locales, defaultLocale, localePrefix })
  request.ts            # getRequestConfig
middleware.ts           # createMiddleware(routing)
messages/
  en.json
  bg.json
```

Prefer **`localePrefix: 'always'`** (e.g. `/en/about`, `/bg/about`) for clearest hreflang and crawl behaviour. `'as-needed'` omits the default locale prefix — still valid, but ensure canonicals and `alternates.languages` use absolute URLs consistently.

## URL strategy

Pick **one** pattern for all locales and keep it:

| Pattern | Example | Notes |
|---|---|---|
| Subdirectory | `example.com/en/`, `example.com/bg/` | **Default with next-intl.** Inherits domain authority. |
| Subdomain | `bg.example.com` | Possible; separate signals; extra DNS/TLS. |
| ccTLD | `example.bg` | Strongest geo signal; most expensive. |

Optionally localise slugs per locale (`/bg/produkti` vs `/en/products`) — only when CMS provides translated slugs and you can keep reciprocal hreflang in sync.

## Middleware & locale detection

**Do not** auto-redirect visitors by IP or `Accept-Language` for SEO pages. It traps users, breaks shared links, and confuses crawlers.

In `middleware.ts`, disable automatic locale detection when SEO matters:

```typescript
import createMiddleware from 'next-intl/middleware';
import { routing } from '@/i18n/routing';

export default createMiddleware({
  ...routing,
  localeDetection: false, // user picks locale via switcher; URL is source of truth
});

export const config = {
  matcher: ['/', '/(bg|en|de|ru)/:path*'],
};
```

- Serve the locale in the URL as-is.
- Optional: dismissible banner suggesting another locale — never a hard redirect from `/en/...` to `/bg/...` based on geo.
- Language switcher must link to the **equivalent path** in the target locale, not always the homepage.

## Localised metadata

Translate **everything in the head and structured data**, not just the body. A Bulgarian page with an English `<title>` is a half-translation.

Translate per locale:

- `<title>`, `<meta name="description">`
- Open Graph `title`, `description`, `locale`
- JSON-LD `name`, `description`, `headline`, etc.
- Image `alt` text (CMS field or `t()`)

### Static page (messages file)

```typescript
// app/[locale]/about/page.tsx
import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { routing } from '@/i18n/routing';

type Props = { params: Promise<{ locale: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: 'AboutPage' });

  return {
    title: t('meta.title'),
    description: t('meta.description'),
    openGraph: {
      title: t('meta.title'),
      description: t('meta.description'),
      locale: ogLocale(locale),
    },
  };
}
```

### Dynamic page (CMS)

```typescript
// app/[locale]/blog/[slug]/page.tsx
import type { Metadata } from 'next';
import { getTranslations } from 'next-intl/server';
import { notFound } from 'next/navigation';
import { getPost, getPostSlugsByLocale } from '@/lib/cms';
import { buildLanguageAlternates } from '@/lib/seo/alternates';

type Props = { params: Promise<{ locale: string; slug: string }> };

export async function generateMetadata({ params }: Props): Promise<Metadata> {
  const { locale, slug } = await params;
  const post = await getPost(slug, locale);
  if (!post) return {};

  const alternates = await buildLanguageAlternates({
    pathname: '/blog/[slug]',
    slug,
    locale,
  });

  return {
    title: post.seoTitle ?? post.title,
    description: post.seoDescription ?? post.excerpt,
    alternates,
    openGraph: {
      title: post.seoTitle ?? post.title,
      description: post.seoDescription ?? post.excerpt,
      locale: ogLocale(locale),
      images: post.ogImage ? [{ url: post.ogImage, alt: post.imageAlt ?? post.title }] : undefined,
    },
  };
}
```

## hreflang via alternates.languages

Declare each language with **BCP 47** codes (`en`, `bg`, `de`, `x-default`). Rules:

- **Reciprocal:** every alternate lists every other alternate, including itself.
- Include **self-reference** and **`x-default`** (usually the default locale URL).
- Emit in **one** place only: Metadata API `alternates.languages` (HTML `<head>`) **or** XML sitemap — not both duplicated with conflicting URLs.

### Helper (shared across pages)

```typescript
// lib/seo/alternates.ts
import { routing } from '@/i18n/routing';

const baseUrl = process.env.NEXT_PUBLIC_SITE_URL!;

/** Map next-intl locale → Open Graph locale */
export function ogLocale(locale: string): string {
  const map: Record<string, string> = {
    en: 'en_US',
    bg: 'bg_BG',
    de: 'de_DE',
    ru: 'ru_RU',
  };
  return map[locale] ?? `${locale}_${locale.toUpperCase()}`;
}

/** Build alternates.languages for a path that exists in all locales with the same slug */
export function buildStaticLanguageAlternates(
  locale: string,
  path: string, // e.g. '/about' — no locale prefix
): { canonical: string; languages: Record<string, string> } {
  const languages = Object.fromEntries(
    routing.locales.map((l) => [l, `${baseUrl}/${l}${path}`]),
  );
  languages['x-default'] = `${baseUrl}/${routing.defaultLocale}${path}`;

  return {
    canonical: `${baseUrl}/${locale}${path}`,
    languages,
  };
}
```

Next.js emits:

```html
<link rel="alternate" hreflang="en" href="https://example.com/en/about" />
<link rel="alternate" hreflang="bg" href="https://example.com/bg/about" />
<link rel="alternate" hreflang="x-default" href="https://example.com/en/about" />
<link rel="canonical" href="https://example.com/bg/about" />
```

If a translation **does not exist** for a locale, omit that hreflang entry entirely — do not point to a 404 or the homepage.

## Localised sitemap

List **every indexable locale URL** with absolute URLs. For large sites, put hreflang alternates in the sitemap instead of (or in addition to) head — but never with conflicting URLs.

```typescript
// app/sitemap.ts
import type { MetadataRoute } from 'next';
import { routing } from '@/i18n/routing';
import { getAllPosts } from '@/lib/cms';

const baseUrl = process.env.NEXT_PUBLIC_SITE_URL!;

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const staticPaths = ['', '/about', '/contact'];
  const posts = await getAllPosts(); // include locale + slug

  const staticEntries = routing.locales.flatMap((locale) =>
    staticPaths.map((path) => ({
      url: `${baseUrl}/${locale}${path}`,
      lastModified: new Date(),
      changeFrequency: 'weekly' as const,
      priority: path === '' ? 1 : 0.8,
      alternates: {
        languages: Object.fromEntries(
          routing.locales.map((l) => [l, `${baseUrl}/${l}${path}`]),
        ),
      },
    })),
  );

  const postEntries = posts.map((post) => ({
    url: `${baseUrl}/${post.locale}/blog/${post.slug}`,
    lastModified: new Date(post.updatedAt),
    changeFrequency: 'monthly' as const,
    priority: 0.7,
    alternates: {
      languages: Object.fromEntries(
        post.translations.map((t) => [t.locale, `${baseUrl}/${t.locale}/blog/${t.slug}`]),
      ),
    },
  }));

  return [...staticEntries, ...postEntries];
}
```

Ensure `metadataBase` in root layout matches `baseUrl`.

## CMS content per locale

- Fetch content with **locale as a first-class argument** (`getPost(slug, locale)`).
- Store SEO fields per locale: `seoTitle`, `seoDescription`, `ogImage`, `slug` (if localised).
- **`notFound()`** when a slug has no translation — never return 200 with empty or wrong-language content (soft 404).
- On CMS publish webhook: `revalidateTag` / `revalidatePath` for affected locale paths and sitemap.

## JSON-LD & Open Graph locale

Localise visible and schema text from the same CMS/message source:

```typescript
const jsonLd = {
  '@context': 'https://schema.org',
  '@type': 'Article',
  headline: post.title,
  description: post.excerpt,
  inLanguage: locale, // BCP 47
  // datePublished/dateModified from CMS — never hardcoded
};
```

Set `openGraph.locale` per page; add `openGraph.alternateLocale` for other published locales when useful.

## Internal links

Use **`Link` from `@/i18n/navigation`** (next-intl's locale-aware wrapper), not raw `<a href="/about">` or default `next/link` without locale prefix:

```typescript
import { Link } from '@/i18n/navigation';

<Link href="/blog/my-post">…</Link> // renders /bg/blog/my-post when locale is bg
```

Crawlers follow internal links — broken locale prefixes split crawl budget and confuse canonical signals.

## Checklist

- [ ] One URL pattern for all locales (`/[locale]/…` subdirectory)
- [ ] `localeDetection: false` (or equivalent) — no IP/`Accept-Language` redirects
- [ ] `metadataBase` + absolute canonical per locale page
- [ ] `alternates.languages` reciprocal with self-ref + `x-default`
- [ ] Title, description, OG, JSON-LD, and image alt translated per locale
- [ ] Sitemap lists all locale URLs (with `alternates.languages` at scale)
- [ ] Missing translation → real `404`, not 200
- [ ] Internal links use locale-aware `Link`
- [ ] Language switcher links to equivalent path in target locale
