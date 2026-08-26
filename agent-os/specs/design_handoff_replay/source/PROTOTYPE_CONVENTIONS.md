# RePlay — project rules (read first)

RePlay is a real-estate digital-signage SaaS **design prototype** (HTML/React, no build step). Full detail in `SPEC.md` — read it before non-trivial work.

## Hard rules (breaking these breaks the app)
1. **No build step / no modules.** JSX is transpiled in-browser via `<script type="text/babel" src="…">`. No `import`/`export`, no `type="module"`.
2. **Reuse the exact pinned React/ReactDOM/Babel `<script>` tags** (with integrity hashes) from an existing HTML file. Never bump versions.
3. **Each babel script has its own scope.** Share components by assigning to `window` at the end of the file (`Object.assign(window, {…})` / `window.X = X`).
4. **Never declare a global `const styles = {…}`** — name collisions across babel files break everything. Use uniquely-named style objects or inline styles. (This project favors inline styles + CSS classes.)
5. **Load order is fixed** in `admin/RePlay Admin.html`: React → ReactDOM → Babel → tweaks-panel → icons → data → shell → screens-* → app. **`app.jsx` is always last.** A new screen file must be added to that list *before* `app.jsx`, then wired into the `Screen`/`titles` maps (app.jsx) and `NAV` (shell.jsx).

## Conventions
- **Design tokens live in `assets/replay.css`** (CSS custom properties). Use them — don't hardcode hexes. Accent = `--blue #2f6bff` primary + `--teal #0fb5a6` secondary on a cool-neutral foundation.
- **Mock data is centralized** in `admin/js/data.jsx`. Add entities there.
- **Imagery = placeholders, never hand-drawn.** Use `<div class="ph" data-label="…">`. Never write SVG photos.
- **Signage / ad / mobile frames use container queries** (`container-type: size` + `cqh`/`cqw` units) so type scales to the frame. Keep it that way.
- **Canonical HTML** (explicit closing tags, double-quoted attrs, no self-closed non-void elements) so the visual editor can direct-edit.

## Verifying
- **Screenshots lie for overlays & entrance animations.** Fixed overlays (command palette, popovers) and `pb-*` entrance animations don't render in html-to-image. Verify via live DOM (`eval_js`) instead of trusting a blank screenshot.
- Cards that show popovers must keep `overflow: visible` (clip only the inner media) and lift the open card with `z-index`.

## What's intentionally fake
No backend. "Publish", "Sync MLS", billing, and API keys are placeholders by design — don't "fix" them as bugs.
