# Sanity CMS + Next.js SEO

Patterns when the CMS is **Sanity** with `next-sanity`, Portable Text, and Visual Editing. For generic Next.js SEO, see `SKILL.md` and other references.

## Contents

- [Metadata (stega)](#metadata-stega)
- [Dynamic sitemap from GROQ](#dynamic-sitemap-from-groq)
- [CMS-managed redirects](#cms-managed-redirects)
- [JSON-LD from Portable Text](#json-ld-from-portable-text)
- [Author schema for E-E-A-T](#author-schema-for-e-e-a-t)

## Metadata (stega)

**Never enable stega in metadata fetches** — invisible encoding breaks `<title>`, OG tags, and JSON-LD.

```typescript
import { sanityFetch } from '@/sanity/lib/live';

export async function generateMetadata({ params }): Promise<Metadata> {
  const { slug } = await params;
  const { data } = await sanityFetch({
    query: PAGE_QUERY,
    params: { slug },
    stega: false, // critical for SEO metadata
  });

  if (!data) return {};

  return {
    title: data.seo?.title || data.title,
    description: data.seo?.description,
    openGraph: {
      images: data.seo?.image
        ? [{ url: urlFor(data.seo.image).width(1200).height(630).url(), width: 1200, height: 630 }]
        : [],
    },
    robots: data.seo?.noIndex ? { index: false, follow: false } : undefined,
    alternates: { canonical: `/pages/${slug}` },
  };
}
```

## Dynamic sitemap from GROQ

Exclude `seo.noIndex` documents and include `_updatedAt`:

```typescript
// app/sitemap.ts
import type { MetadataRoute } from 'next';
import { client } from '@/sanity/lib/client';

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const pages = await client.fetch(`
    *[_type in ["page", "post"] && defined(slug.current) && seo.noIndex != true]{
      "path": select(
        _type == "page" => "/" + slug.current,
        _type == "post" => "/blog/" + slug.current
      ),
      _updatedAt
    }
  `);

  const baseUrl = process.env.NEXT_PUBLIC_SITE_URL!;

  return pages.map((page: { path: string; _updatedAt: string }) => ({
    url: `${baseUrl}${page.path}`,
    lastModified: new Date(page._updatedAt),
  }));
}
```

With **next-intl**, include locale in the GROQ query or generate one sitemap entry per locale — see [next-intl-seo.md](next-intl-seo.md).

## CMS-managed redirects

```typescript
// next.config.ts
import { client } from '@/sanity/lib/client';

async function sanityRedirects() {
  return client.fetch(`
    *[_type == "redirect" && isEnabled == true]{
      source,
      destination,
      permanent
    }
  `);
}

const nextConfig = {
  async redirects() {
    return sanityRedirects();
  },
};
```

Permanent moves → `permanent: true` (308). Revalidate redirect documents on publish via webhook.

## JSON-LD from Portable Text

Structured data needs **plain text**, not Portable Text arrays:

```groq
*[_type == "faq"]{
  question,
  "answer": pt::text(answer)
}
```

```typescript
const faqSchema = {
  '@context': 'https://schema.org',
  '@type': 'FAQPage',
  mainEntity: faqs.map((faq) => ({
    '@type': 'Question',
    name: faq.question,
    acceptedAnswer: { '@type': 'Answer', text: faq.answer },
  })),
};
```

FAQPage rich results were removed in 2026 — still useful for AI parsing when content matches visible FAQ. See [json-ld.md](json-ld.md).

## Author schema for E-E-A-T

Sanity document types for author E-E-A-T fields:

```typescript
defineType({
  name: 'author',
  type: 'document',
  fields: [
    defineField({ name: 'name', type: 'string' }),
    defineField({ name: 'role', type: 'string' }),
    defineField({ name: 'bio', type: 'text' }),
    defineField({ name: 'credentials', type: 'array', of: [{ type: 'string' }] }),
    defineField({ name: 'image', type: 'image' }),
    defineField({
      name: 'sameAs',
      type: 'array',
      of: [{ type: 'url' }],
      description: 'Profile URLs for schema.org Person (LinkedIn, etc.)',
    }),
  ],
});

defineType({
  name: 'post',
  type: 'document',
  fields: [
    defineField({ name: 'author', type: 'reference', to: [{ type: 'author' }] }),
    defineField({ name: 'publishedAt', type: 'datetime' }),
    defineField({ name: 'updatedAt', type: 'datetime' }),
    defineField({ name: 'reviewedBy', type: 'reference', to: [{ type: 'author' }] }),
    defineField({ name: 'sources', type: 'array', of: [{ type: 'url' }] }),
    defineField({
      name: 'seo',
      type: 'object',
      fields: [
        defineField({ name: 'title', type: 'string' }),
        defineField({ name: 'description', type: 'text' }),
        defineField({ name: 'image', type: 'image' }),
        defineField({ name: 'noIndex', type: 'boolean' }),
      ],
    }),
  ],
});
```

Full E-E-A-T guidance: [eeat.md](eeat.md).
