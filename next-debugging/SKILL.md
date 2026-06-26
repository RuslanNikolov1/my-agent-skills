---
name: next-debugging
description: Use when debugging Next.js issues in development (App Router, runtime/build errors, route/render problems, Server Actions). Applies systematic root-cause debugging and integrates next-devtools MCP debug tricks for evidence-first investigation before any fix.
disable-model-invocation: true
---

# Next Debugging

Wrapper skill for Next.js debugging that combines strict `systematic-debugging` process with `next-best-practices/debug-tricks.md` evidence collection.

## Use When

- The project is Next.js and has runtime, build, routing, render, or Server Action errors.
- You need high-confidence root-cause analysis before changing code.
- You need Next dev-server MCP evidence (`get_errors`, `get_routes`, `get_logs`, metadata).

## Core Rule

Follow `systematic-debugging` phases exactly. This skill adds Next-specific instrumentation to Phase 1 and pattern checks for Phase 2.

No fixes before root cause is confirmed.

## Workflow

Copy this checklist and keep it updated:

```md
Next Debugging Progress:
- [ ] 1) Load systematic-debugging and follow Phase 1-4
- [ ] 2) Confirm Next dev server is running and determine actual port
- [ ] 3) Collect MCP evidence (errors, routes, metadata, logs)
- [ ] 4) Reproduce issue with exact steps and route
- [ ] 5) Compare with working Next patterns
- [ ] 6) Form one hypothesis and test minimally
- [ ] 7) Create failing test (when behavior/logic bug)
- [ ] 8) Implement single fix and verify
```

## Phase 1 Add-on: Next Evidence Collection

Before any fix, gather these artifacts:

1. Identify actual dev port from terminal output or scripts (do not assume `3000`).
2. Collect current Next errors via MCP (`get_errors`).
3. Collect route map via MCP (`get_routes`).
4. Collect project metadata via MCP (`get_project_metadata`).
5. If relevant, collect page metadata (`get_page_metadata`) with active browser session.
6. Collect log path via MCP (`get_logs`) and inspect relevant error window.
7. For Server Actions, resolve action with `get_server_action_by_id` when action id is available.

If MCP is unavailable, report that explicitly and use terminal/browser logs as fallback evidence.

## Phase 2 Add-on: Next Pattern Comparison

Compare broken behavior against known-correct patterns from `next-best-practices`:

- `rsc-boundaries.md` for server/client boundaries and serialization.
- `data-patterns.md` for fetching and waterfalls.
- `async-patterns.md` for async usage boundaries.
- `file-conventions.md` for route/file placement correctness.
- `error-handling.md` and `suspense-boundaries.md` for fallback and recovery behavior.

List concrete differences before proposing any fix.

## Phase 3-4 Execution Rules

- Form one hypothesis at a time and test with minimal change.
- If bug is behavior/logic related, add failing test first (use `test-driven-development`).
- Apply one fix only, then verify lint/build/test and issue reproduction.
- If 2 fixes fail, restart investigation.
- If 3+ fixes fail, stop and question architecture before another fix.

## Output Format

Use this structure when reporting:

```md
Root cause investigation:
- Reproduction: ...
- Evidence: ...
- Failing component/layer: ...
- Why this is root cause: ...

Hypothesis:
- I think ... because ...

Validation:
- Minimal test/change: ...
- Result: ...

Fix:
- Single change: ...
- Verification (lint/build/test + repro): ...
```

## Related Skills

- `systematic-debugging` (required base process)
- `test-driven-development` (required for behavior/logic bug fixes)
- `verification-before-completion` (required before completion claims)

