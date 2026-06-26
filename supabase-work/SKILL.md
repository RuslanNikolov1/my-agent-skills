---
name: supabase-work
description: Use when a task involves Supabase (database, auth, storage, edge functions, realtime, SSR integration). Orchestrates Supabase plugin MCP/tools and plugin skills. Do not confuse with the plugin's built-in `supabase` skill — this is the local workflow entry point.
disable-model-invocation: true
---

# Supabase Work

Use this skill for any Supabase-related task in your projects. It coordinates with the Supabase plugin — it does not replace it.

## Required workflow

1. Use Supabase plugin capabilities first:
   - MCP server: `plugin-supabase-supabase`
   - Plugin skills: `supabase`, `supabase-postgres-best-practices`
2. Before calling a Supabase MCP tool, read that tool schema/descriptor.
3. For schema/query/performance changes, apply `supabase-postgres-best-practices`.
4. For auth/session/SSR integration, apply the plugin `supabase` skill guidance.

## Capability check (required)

At the start of work, report:

```
Supabase capability check:
- MCP: available/missing
- Plugin skills (supabase, supabase-postgres-best-practices): available/missing
- Needed setup: auth/config/install (if any)
```

If required Supabase capability is missing, stop and tell the user exactly what is missing and what to set up.
