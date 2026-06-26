---
name: sanity-work
description: Use when a task involves Sanity CMS content, schemas, GROQ, datasets, studio workflows, or Sanity-backed frontend integration. Orchestrates Sanity plugin MCP/tools and plugin skills. Do not confuse with the plugin's built-in Sanity skills — this is the local workflow entry point.
disable-model-invocation: true
---

# Sanity Work

Use this skill for any Sanity CMS work in your projects. It coordinates with the Sanity plugin — it does not replace it.

## Required workflow

1. Use Sanity plugin capabilities first:
   - MCP server: `plugin-sanity-Sanity`
   - Plugin skills: `sanity-best-practices`, `content-modeling-best-practices`, `content-experimentation-best-practices`, `seo-aeo-best-practices` (when relevant)
2. Before calling a Sanity MCP tool, read that tool schema/descriptor.
3. Start by loading schema context before content queries/updates (`get_schema` when available).
4. Prefer `search_docs` and `read_docs` for current Sanity guidance before major implementation decisions.

## Capability check (required)

At the start of work, report:

```
Sanity capability check:
- MCP: available/missing
- Plugin skills (sanity-best-practices, etc.): available/missing
- Needed setup: auth/config/install (if any)
```

If required Sanity capability is missing, do not proceed silently. Tell the user what is missing and what to install/configure first.
