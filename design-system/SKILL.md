---
name: design-system
description: >-
  Grow the project design system incrementally while building UI features.
  Extends shared tokens, components, and design.md without forking one-off
  styles. Use during /new-feature planning and implementation, when a feature
  needs new UI primitives, or when adding reusable patterns to an existing
  Hallmark-managed system. Defers visual voice and anti-slop layout to hallmark;
  component a11y to radix-ui-design-system; SCSS structure to scss-best-practices.
disable-model-invocation: true
---

# Design System

Extend the shared design system **while** building a feature — not after, not as a separate pass.

This skill bridges feature work (`/new-feature`) and Hallmark's token/system model (`design.md`, `tokens.css`). It does **not** replace Hallmark for layout, genre, theme, or anti-slop decisions.

---

## When to use

- Building a new UI feature that introduces colors, spacing, typography, or components
- A feature needs a primitive not yet in the shared library (Button variant, Dialog, Select, etc.)
- Early project with partial or no locked system yet
- `design.md` exists and a feature must stay consistent with it

**Skip when:** Pure logic/backend change, copy-only edit, or bug fix with no new UI surface.

---

## Hallmark compatibility (read first)

| Hallmark artifact | This skill's rule |
|-------------------|-------------------|
| `design.md` at project root | **Read first.** Genre, theme, typography, motion, CTA voice defer to it. Do not override locally — amend via `## Variants` if the feature genuinely needs an exception. |
| `tokens.css` | **Source of truth** for `--color-*`, `--font-*`, `--space-*`, `--text-*`, `--ease-*`, `--dur-*`, `--rule-*`, `--radius-*`. Extend in place; never duplicate values in feature SCSS. |
| No `design.md` yet | Extend tokens and shared components; surface *"Say `lock the system` when ready"* — do **not** auto-emit `design.md` (Hallmark opt-in only). |
| Diversification rule | On `design.md` projects: **consistency wins** — new feature matches the locked system. Without `design.md`: follow Hallmark per-feature picks; still extract reusable tokens/components for the next feature. |
| Component stamps | New shared components get Hallmark component stamp: `/* Hallmark · component: <type> · genre: <genre> · theme: <theme> · states: … */` |
| Page stamps | Feature pages stamp allegiance when `design.md` exists: `design-system: design.md · designed-as-app` |

**Division of labor:**

- **Hallmark** — what the UI looks and feels like (layout, macrostructure, voice, slop test)
- **This skill** — where shared artifacts live and how they grow across features
- **scss-best-practices** — module structure, `@use`, naming, no `@import` sprawl
- **radix-ui-design-system** — headless primitives, focus, keyboard, ARIA

---

## Step 0 — System inventory (before design or code)

Scan in order; cite what you found:

1. `design.md` / `DESIGN.md` — locked system?
2. `tokens.css`, `tokens.json`, or `:root` / `@theme` in globals
3. Shared component dirs — e.g. `components/ui/`, `src/components/`, shadcn path
4. Global styles entry — e.g. `app/globals.scss`, `styles/_variables.scss`
5. Existing Radix/shadcn primitives already installed (`package.json`)

Emit a short block:

```
Design system inventory:
· Locked system: yes/no (design.md at …)
· Token source: tokens.css | globals.scss :root | Tailwind @theme | none
· Shared components: <path> (<N> files)
· Gaps for this feature: <list or "none yet">
```

Cache mentally for the feature; include the inventory summary in the feature spec (Phase ①) and plan (Phase ③).

---

## Step 1 — Design phase (with `/new-feature` brainstorming)

After Hallmark-informed layout decisions, add a **System impact** section to the feature spec:

```markdown
## System impact

### Reuse (existing)
- Button, Card, … (paths)

### Extend (shared layer)
- New token: `--color-surface-elevated` — reason
- New variant: `Button` `ghost` — reason

### Add (new shared primitive)
- `FilterChip` — Radix Toggle Group · path: `components/ui/filter-chip/`

### Local only (feature-scoped)
- `FeatureHero.module.scss` — layout unique to this route; no new tokens

### design.md
- No change | Amend `## Variants` | Recommend `lock the system` after ship
```

**Rules:**

- Prefer **reuse** → **extend** → **add** → **local only** (in that order)
- Every new color/spacing/font value must land in the token source, not inline in a module
- If `design.md` forbids the needed pattern, stop and propose an amendment — do not ship a local override

---

## Step 2 — Planning (task decomposition)

Every plan that touches UI must include explicit system tasks when Step 1 flagged extends or adds:

```
- [ ] Extend tokens.css with --color-surface-elevated
- [ ] Add FilterChip to components/ui/filter-chip/ (Radix + SASS module)
- [ ] Wire feature route using FilterChip — no duplicate styles
- [ ] Update design.md ## Components (if locked system exists)
```

**File placement defaults** (adapt to project conventions found in Step 0):

| Artifact | Default location |
|----------|------------------|
| Design tokens | Project's existing token file — prefer Hallmark's `tokens.css` or globals `:root` |
| Shared UI components | Colocated folder: `ComponentName/ComponentName.tsx` + `ComponentName.module.scss` |
| Feature-only layout | Route-colocated `*.module.scss` |
| Barrel export | Update `components/ui/index.ts` only if the project already uses one |

---

## Step 3 — Implementation order

Within each feature task, apply this order (aligns with `/new-feature` Phase ④):

1. **Tokens** — add named variables to the canonical token source
2. **Shared primitive** — if needed; follow `radix-ui-design-system` for behavior, Hallmark tokens for appearance
3. **Feature components** — compose from shared primitives; SASS modules reference `var(--…)` only
4. **Feature SCSS** — layout and page-specific rules only; no new raw hex/oklch in modules
5. **System doc** — if `design.md` exists, append to `## Components` or `## Variants`; never overwrite the file

### Token extension rules

```scss
// ✅ Extend the canonical source
:root {
  --color-surface-elevated: oklch(98% 0.01 260);
}

// ✅ Consume by name in modules
.card {
  background: var(--color-surface-elevated);
}

// ❌ One-off in a feature module
.card {
  background: oklch(98% 0.01 260);
}
```

Name tokens by **role**, not by feature: `--color-surface-elevated`, not `--color-settings-panel-bg`.

### New shared component checklist

- [ ] Uses existing tokens only (or adds tokens first)
- [ ] Radix primitive if interactive (`radix-ui-design-system`)
- [ ] All 8 states for interactive elements (Hallmark component-scope)
- [ ] Hallmark component stamp in CSS/SCSS
- [ ] Exported from shared path if siblings are
- [ ] Feature imports from shared path — not a forked copy

---

## Step 4 — `design.md` amendments (locked systems only)

When `design.md` exists and the feature adds reusable surface:

**Do:** Append under `## Components`:

```markdown
## Components

### FilterChip
- Path · `components/ui/filter-chip/`
- Primitive · Radix Toggle Group
- Added · 2026-06-24 · feature: settings-filters
```

**Do:** Use `## Variants` for intentional per-area exceptions (Hallmark redesign flow).

**Do not:** Overwrite `design.md`, change locked genre/theme without user approval, or emit a second token source.

When no `design.md` exists but tokens grew substantially across 2+ features, note in the PR/summary: *"System is maturing — consider `lock the system` to emit design.md."*

---

## Step 5 — Verification

Before marking the feature done:

- [ ] No raw color/spacing/font values in feature SCSS that aren't in the token source
- [ ] New shared components live under the shared path, not inside the route folder
- [ ] Feature uses shared components — no copy-paste from another feature
- [ ] `design.md` drift check — tokens/fonts match locked system (if applicable)
- [ ] Hallmark stamp present on new pages/components per compatibility table above
- [ ] Radix a11y checklist passed for new interactive primitives

Run alongside `/new-feature` Phase ⑤ verification.

---

## Anti-patterns

| Anti-pattern | Fix |
|--------------|-----|
| Feature-scoped `--color-*` in a `.module.scss` | Lift to token source |
| Duplicate `Button` in `app/settings/` | Extend or import shared `Button` |
| New theme pick on a `design.md` project | Defer to locked system |
| Auto-write `design.md` on first feature | Wait for user `lock the system` |
| Design system mega-refactor mid-feature | Scope to this feature's needs only |

---

## Related skills

| Skill | Role |
|-------|------|
| `hallmark` | Visual voice, layout, anti-slop, `design.md` / `tokens.css` emission |
| `new-feature` | Orchestrator — invokes this skill during planning + implementation |
| `scss-best-practices` | SASS module architecture |
| `radix-ui-design-system` | Accessible primitives |
| `responsive-design` | Breakpoints and layout — after tokens/components exist |
| `loading-skeletons` | Skeleton tokens inherit from project CSS variables |
