# Standard: Tailwind CSS + TailwindPlus Elements

## Setup

Tailwind CSS v4 with the `@tailwindcss/typography` plugin and `@tailwindplus/elements` for interactive components.

**`app/assets/tailwind/application.css`:**
```css
@import "tailwindcss";
@plugin "@tailwindcss/typography";
```

**`app/views/layouts/app.html.erb`:**
```html
<script src="https://cdn.jsdelivr.net/npm/@tailwindplus/elements@1" type="module"></script>
```

## Rule

Use raw Tailwind utility classes for all UI elements. Use TailwindPlus Elements (`<el-dialog>`, `<el-dialog-panel>`, etc.) for interactive components like modals and dialogs. Use custom CSS variables for theming.

## UI Patterns

| UI Element | Tailwind Classes |
|---|---|
| Primary button | `rounded-md bg-indigo-600 px-2.5 py-1.5 text-sm font-semibold text-white shadow-xs hover:bg-indigo-500` |
| Secondary button | `rounded-md bg-white px-2.5 py-1.5 text-sm font-semibold text-gray-900 ring-1 ring-gray-300 ring-inset hover:bg-gray-50` |
| Destructive button | `rounded-md bg-red-600 px-2.5 py-1.5 text-sm font-semibold text-white hover:bg-red-500` |
| Text input | `block w-full rounded-md bg-white px-3 py-2 text-sm text-gray-900 outline-1 -outline-offset-1 outline-gray-300 placeholder:text-gray-400 focus:outline-2 focus:-outline-offset-2 focus:outline-indigo-600` |
| Select | `block w-full rounded-md bg-white py-2 pl-3 pr-8 text-sm text-gray-900 outline-1 -outline-offset-1 outline-gray-300 focus:outline-2 focus:-outline-offset-2 focus:outline-indigo-600` |
| Card container | `rounded-lg bg-white shadow-sm ring-1 ring-gray-900/5` |
| Card content | `p-5` or `p-4` |
| Badge | `inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium` (with color variants) |
| Section header | `text-sm font-semibold text-gray-500 uppercase tracking-wider` |

## Dialogs and Modals

Use TailwindPlus Elements for interactive overlays:

```html
<el-dialog>
  <el-dialog-backdrop class="fixed inset-0 bg-gray-900/80 transition-opacity"></el-dialog-backdrop>
  <el-dialog-panel class="relative w-full max-w-md rounded-lg bg-white p-6 shadow-xl">
    <!-- content -->
  </el-dialog-panel>
</el-dialog>
```

## Flash Messages

Flash messages use a Stimulus `dismissable` controller with auto-dismiss timers:

| Type | Color | Delay |
|------|-------|-------|
| `notice` | Green | 4s |
| `alert` | Red | 8s |
| `warning` | Amber | 6s |
| `info` | Blue | 4s |

Rendered via `app/views/app/shared/_flash.html.erb`. Use `flash[:notice]` for success, `flash[:alert]` for errors.

## Theming

Custom CSS variables are defined in `application.css` for marketing pages (`--m-*`) and ad canvas (`--s-*` for signage scale, `--ad-*` for ad theming). App pages use standard Tailwind colors directly.

## Ad Canvas

Ad templates use container query units (`cqw`) for proportional scaling on any screen size. The `.ad-canvas` class sets `container-type: inline-size` and defines `--s-*` variables (e.g., `--s-hero: 7cqw`, `--s-pad-lg: 7cqw`). See `docs/architecture/signage-css.md`.

## Why

- Raw Tailwind gives full control without abstraction layers
- TailwindPlus Elements provide accessible interactive components without a full component library
- Custom CSS variables enable consistent theming across marketing and app surfaces
