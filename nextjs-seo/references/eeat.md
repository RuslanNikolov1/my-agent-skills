# E-E-A-T (Experience, Expertise, Authoritativeness, Trustworthiness)

Google's quality framework for content evaluation. Applies to traditional rankings and AI answer selection — especially on **YMYL** (Your Money or Your Life) topics: health, finance, legal, safety.

For technical trust signals (HTTPS, security headers, privacy policy), see [technical-hardening.md](technical-hardening.md). For content structure that helps AI citation, see [ai-search.md](ai-search.md).

## Contents

- [The four pillars](#the-four-pillars)
- [Implementation in Next.js](#implementation-in-nextjs)
- [YMYL considerations](#ymyl-considerations)
- [CMS author model](#cms-author-model)

## The four pillars

### Experience

First-hand or life experience with the topic.

**Signals:** personal case studies, "I tested this" content, real screenshots/results, customer reviews.

**Implementation:** author bios with relevant experience, "About the author" sections, testimonials, real examples not just theory.

### Expertise

Knowledge and skill in the subject area.

**Signals:** credentials, depth of coverage, technical accuracy, citations to authoritative sources.

**Implementation:** display author credentials, link primary sources, cover topics comprehensively, keep content updated.

### Authoritativeness

Recognition as a go-to source in the field.

**Signals:** backlinks from respected sites, industry mentions, social proof, brand recognition.

**Implementation:** thought leadership content, consistent publishing, recognizable brand voice. (Mostly off-site — the site should surface credentials and original research.)

### Trustworthiness

Accuracy, transparency, and legitimacy.

**Signals:** clear authorship and contact info, fact-checked content, HTTPS, privacy policy.

**Implementation:** author attribution on every article, visible publish/update dates, contact page, HTTPS + security headers.

## Implementation in Next.js

### Author on every indexable article

```typescript
// app/[locale]/blog/[slug]/page.tsx
export default async function PostPage({ params }) {
  const post = await getPost(params);
  return (
    <article>
      <header>
        <h1>{post.title}</h1>
        <p>
          <time dateTime={post.publishedAt}>{formatDate(post.publishedAt)}</time>
          {post.updatedAt && (
            <> · Updated <time dateTime={post.updatedAt}>{formatDate(post.updatedAt)}</time></>
          )}
        </p>
        <address rel="author">
          <Link href={`/authors/${post.author.slug}`}>{post.author.name}</Link>
          {post.author.role && ` — ${post.author.role}`}
        </address>
      </header>
      {/* body */}
      {post.sources?.length > 0 && (
        <section aria-labelledby="sources-heading">
          <h2 id="sources-heading">Sources</h2>
          <ul>{post.sources.map((url) => <li key={url}><a href={url}>{url}</a></li>)}</ul>
        </section>
      )}
    </article>
  );
}
```

### Person + Article JSON-LD

Include author in structured data — must match visible byline:

```typescript
{
  '@type': 'Article',
  headline: post.title,
  datePublished: post.publishedAt,
  dateModified: post.updatedAt ?? post.publishedAt,
  author: {
    '@type': 'Person',
    name: post.author.name,
    url: `${baseUrl}/authors/${post.author.slug}`,
    sameAs: post.author.profiles, // LinkedIn, etc.
  },
}
```

See [json-ld.md](json-ld.md) for full schema patterns.

### Localised E-E-A-T (next-intl)

Translate author bios, disclaimers, and "reviewed by" labels per locale. Keep `sameAs` URLs canonical (usually language-neutral profile URLs).

## YMYL considerations

Extra rigour required:

| Topic | Requirement |
|-------|-------------|
| Medical | Reviewed by qualified healthcare professional; clear disclaimers |
| Financial | From certified experts; risk disclaimers where required |
| Legal | Reviewed by licensed attorney; jurisdiction stated |
| Safety | Primary sources, official standards cited |

Display **reviewed by** separately from **written by** when applicable.

## CMS author model

Store these fields on author and post documents (any headless CMS):

**Author:** `name`, `role`, `bio`, `credentials[]`, `image`, `slug`, `sameAs[]` (profile URLs for JSON-LD Person)

**Post:** `author` (ref), `publishedAt`, `updatedAt`, `reviewedBy` (ref, optional), `sources[]` (URLs)

For **Sanity-specific** schema, GROQ, and `stega: false` metadata patterns, see [cms-sanity-seo.md](cms-sanity-seo.md).
