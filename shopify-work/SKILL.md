---
name: shopify-work
description: Use when a task involves Shopify — apps, headless storefronts, Admin GraphQL, Storefront API, themes, Liquid, or CLI workflows. Orchestrates Shopify plugin skills; does not replace them.
disable-model-invocation: true
---

# Shopify Work

Use this skill for any Shopify-related task in your projects. It coordinates with the **Shopify plugin** — it does not replace API-specific plugin skills.

## Required workflow

1. Use Shopify plugin skills first — pick by task:
   - **Scaffold / CLI / dev store:** `shopify-onboarding-dev`
   - **Run or validate via CLI:** `shopify-use-shopify-cli`
   - **Headless storefront GraphQL:** `shopify-storefront-graphql`
   - **Admin GraphQL (design/generate):** `shopify-admin`
   - **Embedded admin app UI:** `shopify-polaris-app-home`
   - **Checkout / customer account extensions:** `shopify-polaris-checkout-extensions`, `shopify-polaris-customer-account-extensions`
   - **Hydrogen storefront:** `shopify-hydrogen` (when Hydrogen is named — not default for Next.js)
   - **Themes / Liquid:** `shopify-liquid`
   - **Metafields / metaobjects:** `shopify-custom-data`
   - **Functions:** `shopify-functions`
   - **Broad doc search:** `shopify-dev`
2. For generated GraphQL from plugin skills, follow each skill's **search_docs** / **validate** workflow when required.
3. Prefer plugin doc search over training-data assumptions — Shopify APIs change frequently.

## Capability check (required)

At the start of work, report:

```
Shopify capability check:
- Plugin skills (shopify-onboarding-dev, etc.): available/missing
- Shopify CLI (`shopify version`): installed/missing
- Project type: app | storefront | theme | unset
- Needed setup: Partner account, dev store, CLI install, env vars (if any)
```

If required Shopify capability is missing, do not proceed silently. Tell the user what to install or configure first.

## Next.js + Vercel note

This stack's default bootstrap is **Next.js App Router**. For **Storefront**, integrate Storefront API in the Next.js app. For **Apps**, Shopify CLI often scaffolds Remix — use a subfolder/monorepo or follow `shopify-onboarding-dev` without replacing the Next.js app unless the user explicitly chooses a Shopify-only scaffold.
