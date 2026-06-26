# Programmatic SEO

Building indexable pages at scale from a repeatable data pattern (locations, categories, integrations, comparisons). Applies to Next.js App Router with dynamic routes and CMS/API data.

## Contents

- [When it makes sense](#when-it-makes-sense)
- [When to avoid it](#when-to-avoid-it)
- [Implementation rules](#implementation-rules)
- [Indexation policy](#indexation-policy)
- [Next.js patterns](#next-js-patterns)

## When it makes sense

- Real search demand for the pattern (keyword research, not gut feel)
- Each URL can show **unique, defensible value** — local data, pricing, inventory, reviews, CMS-authored copy
- A clear hub page links to spokes (e.g. `/services` → `/services/plumbing-sofia`)
- You can maintain quality as the set grows (monitor Search Console index coverage)

## When to avoid it

- Swapping `{city}` and `{service}` in the same paragraph across thousands of URLs
- Pages with no unique data, thin copy, or duplicate intent vs existing URLs
- Auto-generating every permutation without a quality threshold
- Building pages for keywords with zero volume just because the data exists

Google treats low-value templated pages as **doorway pages** — sitewide quality drops and indexation suffers.

## Implementation rules

1. **Clean URLs** — subfolders, not query params: `/en/plumbers/sofia` not `/search?city=sofia&trade=plumber`
2. **Unique metadata per URL** — `generateMetadata` from real fields, not a single template string
3. **One h1 per page** with logical h2–h6; body content must differ meaningfully between URLs
4. **Breadcrumbs** on every programmatic page → hub → home
5. **Internal links** — hub lists strong spokes; related spokes cross-link where relevant
6. **Canonical** on every page; no duplicate URLs for the same intent
7. **Structured data** only when it matches visible content (LocalBusiness, Service, FAQ where applicable)
8. **Localise properly** — with next-intl, generate locale URLs in sitemap and hreflang; see [next-intl-seo.md](next-intl-seo.md)

## Indexation policy

Not every generated URL should be indexed.

| Page quality | Action |
|---|---|
| Strong — unique data + demand + internal links | `index, follow`; include in sitemap |
| Weak — thin copy, low demand, duplicate intent | `noindex, follow` or don't generate |
| Long tail you can't maintain | `noindex` until improved |

Monitor in Search Console:

- **Indexed vs submitted** in sitemap
- **Cannibalisation** — multiple URLs ranking for the same query
- **"Crawled - currently not indexed"** — quality signal to improve or noindex

## Next.js patterns

### Dynamic route with quality gate

```typescript
// app/[locale]/services/[city]/[trade]/page.tsx
import { notFound } from 'next/navigation';
import type { Metadata } from 'next';

export async function generateMetadata({ params }): Promise<Metadata> {
  const { locale, city, trade } = await params;
  const page = await getServicePage(city, trade, locale);
  if (!page || !page.indexable) return { robots: { index: false, follow: true } };

  return {
    title: page.seoTitle,
    description: page.seoDescription,
    alternates: { canonical: `/${locale}/services/${city}/${trade}` },
  };
}

export default async function Page({ params }) {
  const { locale, city, trade } = await params;
  const page = await getServicePage(city, trade, locale);
  if (!page) notFound();
  // …
}
```

### `generateStaticParams` with a cap

Pre-render only high-value combinations; let the rest be on-demand or excluded:

```typescript
export async function generateStaticParams() {
  const topPages = await getTopServicePages({ limit: 200, minSearchVolume: 50 });
  return topPages.map((p) => ({ locale: p.locale, city: p.city, trade: p.trade }));
}
```

### Sitemap: index strong pages only

```typescript
const entries = await getAllServicePages();
return entries
  .filter((p) => p.indexable)
  .map((p) => ({
    url: `${baseUrl}/${p.locale}/services/${p.city}/${p.trade}`,
    lastModified: new Date(p.updatedAt),
  }));
```
