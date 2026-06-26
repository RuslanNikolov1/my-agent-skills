---
name: browser-review
description: >-
  Verify UI in a real browser after implementation. Uses cursor-ide-browser MCP
  for navigation, snapshots, screenshots, and interaction tests at mobile and
  desktop widths. Use in /new-feature Phase ⑤ when the feature has UI surface,
  after lint/build pass; skip for backend-only changes. Defers WCAG formal audits
  to BrowserStack accessibility scan; defers Lighthouse deep dives to
  performance-optimizer.
disable-model-invocation: true
---

# Browser Review

Confirm the feature **looks and behaves correctly in a browser** — evidence build/lint cannot provide.

**Core principle:** Snapshot + screenshot + exercise critical flows before claiming UI work is done.

**Tool:** `cursor-ide-browser` MCP (`CallMcpTool`, server `cursor-ide-browser`). Read each tool's schema in `mcps/cursor-ide-browser/tools/` before calling.

### Enable in Cursor (not in mcp.json)

`cursor-ide-browser` is **built into Cursor** — you will not find it in `~/.cursor/mcp.json` next to GitHub, Vercel, etc.

1. Open **Settings → Tools & MCP → Browser Automation**
2. Turn **Browser Automation** on
3. Mode: **Browser Tab** (built-in) or **Google Chrome**
4. Status should show connected (e.g. "Connected to Browser Tab")
5. In chat, you can also invoke with **@Browser**

**If tools are missing:** toggle Browser Automation off → wait → on → fully restart Cursor → start a **new chat**.

**Remote / devcontainer / SSH:** browser runs on your local machine. Add to User Settings JSON if needed:

```json
"remote.extensionKind": {
  "anysphere.cursor-browser-automation": ["ui"]
}
```

Forward dev-server ports so `localhost:3000` in the browser reaches the container. Enterprise teams may need an admin to enable browser automation.

---

## When to use

**Run when:**

- Feature adds or changes visible UI (pages, components, layouts, forms, modals)
- `/new-feature` Phase ⑤ and lint/build/tests already passed
- Dev server or preview URL is reachable

**Skip when:**

- Backend-only, config-only, or copy-in-JSON with no layout change
- No runnable URL and user declines to start dev server
- Auth/captcha block automation — report blocker, ask user to verify manually

---

## Preconditions

1. **Dev server running** — detect from `package.json` (`next dev`, `npm run dev`). Start in background if not running; note the port (default `3000`).
2. **Target URLs** — list every route the feature touches, including `[locale]` prefix when `next-intl` is present (e.g. `/en/settings`).
3. **Feature brief** — critical flows to exercise (open dialog, submit form, toggle filter).

If the server fails to start, stop and report — do not claim browser verification passed.

---

## Workflow

Announce: "I'm using the browser-review skill to verify UI in the browser."

### 1. Open and navigate

```
browser_tabs (action: list) → reuse tab or browser_navigate
```

- `browser_navigate` to each target URL
- Omit `position` for background automation unless user asked to see the browser
- On existing tab with target page: `browser_lock` before interactions, `browser_unlock` when done

### 2. Capture evidence (each URL)

| Step | Tool | Purpose |
|------|------|---------|
| Structure + a11y tree | `browser_snapshot` | Labels, roles, interactive refs |
| Visual proof | `browser_take_screenshot` or `take_screenshot_afterwards: true` on snapshot | Layout, spacing, typography |
| Viewport | `browser_cdp` — resize via `Emulation.setDeviceMetricsOverride` | Mobile 375px + desktop 1280px minimum |

**Hallmark mobile floor:** also spot-check 320px if layout is tight or user reported overflow issues.

### 3. Exercise critical flows

Use `browser_snapshot` first to get element refs, then:

| Flow | Tools |
|------|-------|
| Click button / link | `browser_click` |
| Fill form | `browser_fill` or `browser_type` |
| Select option | `browser_select_option` |
| Keyboard | `browser_press_key` (Tab, Enter, Escape) |
| Scroll into view | `browser_scroll` |
| Open overlay | click trigger → snapshot → Escape closes |

**Radix / interactive UI:** verify dialog traps focus, Escape closes, dropdown positions in viewport. Defer component patterns to `radix-ui-design-system`; this skill confirms they work in the running app.

**Forms:** submit invalid + valid data; confirm error messages and focus move to first error.

### 4. Check against feature spec

Cross-check the approved design doc and domain checklist:

- [ ] Layout matches spec — no obvious overflow or broken grid
- [ ] Loading skeleton → content transition (if async UI)
- [ ] Focus visible on interactive elements
- [ ] No console errors worth fixing (`browser_cdp` → `Runtime.evaluate` or check snapshot for error states)
- [ ] i18n routes render correct locale strings (if applicable)
- [ ] Design tokens visibly consistent — no rogue colors/fonts vs rest of app

### 5. Report

Emit a structured summary before Phase ⑤ completion claim:

```markdown
## Browser review

**Environment:** http://localhost:3000 · Next.js dev
**URLs:** /en/settings, /en/settings/filters

| URL | 375px | 1280px | Flows |
|-----|-------|--------|-------|
| /en/settings | ✅ screenshot | ✅ screenshot | filter open/close ✅ |

**Issues found:** none | list with severity
**Blockers:** none | auth required — manual verify needed
```

Fix issues found → re-run affected URLs → update report. Do not claim UI complete with open browser failures.

---

## Red flags — STOP

- Claiming "looks good" without snapshot or screenshot evidence
- Skipping mobile width on responsive features
- Clicking without a fresh snapshot (stale refs)
- Using `browser_cdp` Input.* for clicks (denied — use `browser_click`)
- Retry loops — max 4 attempts per action; then report blocker with observed state
- Using browser automation when user only asked for a code review

---

## Integration

| Skill | Relationship |
|-------|----------------|
| `verification-before-completion` | Browser review runs **after** lint/build/test; both required before "done" |
| `new-feature` | Phase ⑤ conditional — UI features only |
| `responsive-design` | Viewport widths to test |
| `radix-ui-design-system` | Expected keyboard/focus behavior |
| `hallmark` | Visual quality bar; browser catches what slop-test can't at runtime |
| `performance-optimizer` | Defer Lighthouse / CWV deep dives |
| BrowserStack `scan-and-fix-accessibility` | Defer formal WCAG scan unless user requests compliance audit |

---

## Fallback when MCP unavailable

1. State: "Browser MCP unavailable — manual verification required."
2. List URLs, viewports, and flows for the user to check.
3. Do not claim browser verification passed.
