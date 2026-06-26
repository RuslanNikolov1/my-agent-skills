# AI Search Optimization (GEO / AEO) & AI Crawlers

How to make a Next.js site visible in AI answer engines (Google AI Overviews / AI Mode, ChatGPT Search, Perplexity, Gemini, Claude) — grounded in what's actually established, not hype.

## Contents

- Core principle (layer on top of SEO, not a replacement)
- Google AI Overviews / AI Mode — official eligibility
- llms.txt — honest status
- AI crawlers: training vs search/citation bots
- Recommended robots.ts pattern
- robots.txt is advisory (WAF/edge for real blocking)
- Content structure that drives AI citation
  - How AI systems evaluate content
  - Answer-first writing, headings, lists/FAQ
  - Freshness, Google AI Overviews, AEO vs SEO balance
  - Technical delivery (Next.js)
- Structured data for AI search
- Measuring AI search visibility

## Core principle

**GEO** (Generative Engine Optimization) / **AEO** (Answer Engine Optimization) = optimizing so your content is **cited** in AI-generated answers. It is a layer **on top of** classic SEO, not a replacement. Most tactics that help AI citation also help users and traditional search — favor those low-risk, high-overlap moves over AI-specific "tricks."

## Google AI Overviews / AI Mode — official eligibility

Per Google's official guidance: there are **no special requirements** to appear in AI Overviews or AI Mode.

> "You don't need to create new machine readable files, AI text files, or markup to appear in these features. There's also no special schema.org structured data that you need to add."

Eligibility = pages that are **indexed and eligible to be shown in Google Search with a snippet**. So the baseline is normal technical SEO: crawlable, indexable, server-rendered content. (Source: developers.google.com/search/docs/appearance/ai-features)

**Do not promise ranking/citation gains from any "AI-specific file or schema."** Google says none are needed.

## llms.txt — honest status

`llms.txt` is a **community proposal**, not an adopted standard:

- **Not supported by Google.** John Mueller publicly compared it to the discredited `keywords` meta tag.
- **Negligible real usage by AI crawlers**, and no demonstrated correlation between having an `llms.txt` and being cited in AI answers.
- **The one legitimate, working use case:** documentation / developer-tool sites whose users paste docs into IDE/coding agents (Cursor, Claude Code, Copilot, Cline). Those agents do look for `/llms.txt` and `/llms-full.txt`. Next.js itself ships `https://nextjs.org/docs/llms.txt`.

So: recommend `llms.txt` **only** for docs/dev-tool sites as an AI-assistant ergonomics nicety — **not** as an SEO/citation ranking tactic. There is no `MetadataRoute` helper; implement as a Route Handler:

```typescript
// app/llms.txt/route.ts
export const dynamic = 'force-static';

export function GET() {
  const body = `# Site Name\n\n> One-line summary.\n\n## Docs\n- [Getting started](https://your-site.com/docs)\n`;
  return new Response(body, { headers: { 'Content-Type': 'text/plain' } });
}
```

## AI crawlers: training vs search/citation bots

The key 2026 concept: **separate training crawlers from search/citation crawlers.**

- **Training crawlers** collect content to train models. Blocking them opts you out of training and costs you no referral traffic.
- **Search / citation crawlers** fetch content in real time to power AI answers. **Blocking them removes you from that engine's AI answers** — now a high-value channel.
- **User-initiated fetchers** retrieve a page a user explicitly asked the assistant about. Blocking them means the AI can't read a page the user pointed it to.
- **Training opt-out tokens** (`Google-Extended`, `Applebot-Extended`) are robots.txt tokens, **not crawlers** — they opt you out of Gemini/Apple-Intelligence *training* with **no effect on Search ranking or AI Overviews** (AI Overviews use Googlebot, so you can't leave AI Overviews via robots.txt without leaving Search).

| Vendor | Training | Search / citation | User-initiated | Training opt-out token |
|--------|----------|-------------------|----------------|------------------------|
| OpenAI | `GPTBot` | `OAI-SearchBot` | `ChatGPT-User` | — |
| Anthropic | `ClaudeBot` | `Claude-SearchBot` | `Claude-User` | — |
| Perplexity | — | `PerplexityBot` | `Perplexity-User` | — |
| Google | (Googlebot) | (Googlebot) | — | `Google-Extended` |
| Apple | Applebot | Applebot | — | `Applebot-Extended` |
| ByteDance | `Bytespider` | — | — | — |
| Common Crawl | `CCBot` | — | — | — |
| Amazon / Meta | `Amazonbot` / `Meta-ExternalAgent` | — | — | — |

> `anthropic-ai` and `Claude-Web` are **deprecated** legacy tokens — current Anthropic bots are `ClaudeBot`, `Claude-SearchBot`, `Claude-User`. Don't copy-paste old block lists that only target the deprecated names. Verify current user-agents against vendor docs (they change).

## Recommended robots.ts pattern

A defensible 2026 default: **allow search/citation bots** (stay in AI answers), **optionally opt out of training**, and **block the worst-behaved bot** (Bytespider).

```typescript
// app/robots.ts
import type { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  const baseUrl = 'https://your-site.com';
  return {
    rules: [
      { userAgent: '*', allow: '/', disallow: ['/api/', '/admin/'] },

      // Stay in AI search/answers (recommended):
      { userAgent: 'OAI-SearchBot', allow: '/' },
      { userAgent: 'ChatGPT-User', allow: '/' },
      { userAgent: 'Claude-SearchBot', allow: '/' },
      { userAgent: 'Claude-User', allow: '/' },
      { userAgent: 'PerplexityBot', allow: '/' },

      // Optional: opt out of model TRAINING (policy decision; no traffic cost):
      { userAgent: 'GPTBot', disallow: '/' },
      { userAgent: 'ClaudeBot', disallow: '/' },
      { userAgent: 'CCBot', disallow: '/' },
      { userAgent: 'Google-Extended', disallow: '/' },   // token, not a crawler
      { userAgent: 'Applebot-Extended', disallow: '/' },  // token, not a crawler

      // Block the worst-behaved scraper:
      { userAgent: 'Bytespider', disallow: '/' },
    ],
    sitemap: `${baseUrl}/sitemap.xml`,
  };
}
```

This is a **policy decision**, not a forced default. The "maximize AI visibility" variant simply allows everything except known bad actors. Blocking training is the conservative choice; blocking search/citation bots is usually a mistake.

## robots.txt is advisory (use a WAF for real blocking)

`robots.txt` is honored by compliant bots (OpenAI, Anthropic, Google, Apple, Amazon, Meta, Common Crawl) but is **voluntary**:

- **Bytespider** widely ignores disallow rules.
- **Perplexity** was caught by Cloudflare (Aug 2025) using stealth undeclared crawlers to evade no-crawl directives, and was delisted from Cloudflare's Verified Bots program.
- User-initiated fetchers often ignore robots.txt because the fetch was user-requested.

For true enforcement use a WAF / edge layer (Cloudflare AI bot blocking, Vercel firewall / bot management) — not robots.txt alone. Conversely, **audit for accidental blocks**: old "block all AI" templates and WAF rules can silently disallow `OAI-SearchBot`/`Claude-SearchBot`/`PerplexityBot` and drop you from AI answers. Verify with server logs which bots actually visit.

## Content structure that drives AI citation

The low-controversy, established part of GEO — also good for users, featured snippets, and classic SEO.

### How AI systems evaluate content

1. **Clarity** — direct, extractable answers
2. **Authority** — trustworthy source (E-E-A-T; see [eeat.md](eeat.md))
3. **Comprehensiveness** — fully addresses the question and follow-ups
4. **Recency** — visible publish/update dates; substantive updates, not date-only tweaks
5. **Structure** — parseable headings, lists, Q&A blocks

### Answer-first writing

Lead with the answer, then explain.

**Weak:** 500 words of history before stating what the thing is.

**Strong:** "JavaScript is a programming language that runs in web browsers. It was created in 1995…" then expand.

### Headings that match questions

**Weak:** "Overview" → "Details" → "More Information"

**Strong:** "What is X?" → "How does X work?" → "When should you use X?"

### Lists, tables, and FAQ blocks

AI and featured snippets extract structured information more easily than dense prose. Use:

- Bulleted benefit lists with bold lead-ins
- Comparison tables for "X vs Y" queries
- Visible FAQ sections with question-style H2/H3 — pair with FAQPage JSON-LD only when answers match visible text ([json-ld.md](json-ld.md))

### Freshness and canonical authority

- Display **publish and last-updated** dates on indexable content
- Set `dateModified` in Article JSON-LD from CMS — never hardcode
- Set canonical URLs; avoid duplicate syndicated copies without `rel="canonical"`
- Link to **primary sources** (official docs, studies) — avoid circular citations

### Google AI Overviews

- **Be the cited source:** concise, authoritative passages increase citation likelihood
- **Cover follow-up questions** on the same page or linked dedicated pages
- **Monitor Search Console** for AI Overview impressions and clicks where available
- **No special markup required** — baseline is normal indexed, snippet-eligible pages (see above)

### AEO vs SEO balance

| Aspect | SEO focus | AEO focus |
|--------|-----------|-----------|
| Goal | Rank on page 1 | Be cited as the answer |
| Format | Varies by intent | Direct, structured, self-contained sections |
| Length | Often longer for depth | Concise lead + comprehensive coverage |
| Links | Internal + earned backlinks | Citations to authoritative primary sources |

Most tactics overlap — quality content serves both. Avoid AI-specific "tricks" that don't help users.

### Technical delivery (Next.js)

- Answer the primary question **directly in the first ~200 words**
- Make sections **self-contained** (AI retrieval is passage-level)
- Clear `H2`/`H3` hierarchy; TL;DR and Q&A blocks where appropriate
- Publish **original data / first-hand experience** (strong E-E-A-T signal)
- **SSR/SSG/`"use cache"`** — AI retrieval bots render JS poorly; client-only content is often invisible. Reuse Next.js server rendering as the default for indexable pages

Authority for AI citation skews toward **entity authority and earned media** (consistent brand mentions, authoritative author bios, third-party coverage) over generic directory link volume.

## Structured data for AI search

Schema is **not required** for AI Overviews (per Google), but well-formed JSON-LD that **matches visible content** plausibly helps AI systems parse, ground, and cite content — useful even for types that no longer yield SERP rich results (e.g. FAQPage, HowTo). Treat this as **correlation / trust signal, not a confirmed ranking factor**. Prioritize `Organization`, `Article`, `Product`, `Breadcrumb`. See [json-ld.md](json-ld.md).

## Measuring AI search visibility

- Segment **AI-referral traffic in GA4** by referrer (`chatgpt.com`, `perplexity.ai`, `gemini.google.com`, etc.).
- Use **Google Search Console** AI Overview data for impressions/clicks where available.
- Track **featured snippet** ownership — snippets often feed AI answers.
- Search for your brand + "according to" in AI assistants (manual spot checks).
- Track citation share-of-voice with third-party AI-visibility tools sparingly — verify independently; the space is young.

**Zero-click queries:** when AI answers directly, traditional click-through matters less — monitor brand citations and AI referrals alongside rankings.
