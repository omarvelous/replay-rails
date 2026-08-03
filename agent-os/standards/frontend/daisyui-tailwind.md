# Standard: DaisyUI + Tailwind CSS

## Setup

DaisyUI v5 is installed as an npm package and loaded via the Tailwind CSS v4 plugin system.

**`app/assets/tailwind/application.css`:**
```css
@import "tailwindcss";
@plugin "daisyui";
```

The `daisyui` package is declared in `package.json` and installed via `npm install`. The `tailwindcss-rails` gem's standalone CLI resolves the plugin from `node_modules/`.

## Rule

Use DaisyUI semantic component classes for standard UI elements. Use raw Tailwind utility classes for layout, spacing, and one-off adjustments.

## Component Classes

| UI Element | DaisyUI Classes |
|---|---|
| Primary button | `btn btn-primary` |
| Secondary/ghost button | `btn btn-ghost` |
| Small button | `btn btn-sm` (combine with variant) |
| Destructive button | `btn btn-error btn-outline btn-sm` |
| Text input | `input input-bordered w-full` |
| Form field wrapper | `fieldset` with class `fieldset` |
| Form label | `fieldset-label` (inside `fieldset.fieldset`) |
| Error/alert message | `alert alert-error` |
| Success message | `alert alert-success` |
| Card container | `card bg-base-100 shadow-sm` |
| Card content | `card-body` |
| Navigation bar | `navbar bg-base-100` |
| Badge/count | `badge badge-ghost badge-sm` |
| Text link | `link link-hover` or `link link-primary` |
| Hero section | `hero` + `hero-content` |

## Theme

The default DaisyUI theme is used. Set `data-theme="light"` on the `<html>` tag.

DaisyUI theme-aware colors replace hardcoded Tailwind colors:
- `bg-base-100` instead of `bg-white`
- `border-base-300` instead of `border-gray-200`
- `text-base-content/60` instead of `text-gray-500`

## When to Use Raw Tailwind

Raw Tailwind utility classes are appropriate for:
- Layout: `flex`, `grid`, `gap-4`, `justify-between`, `items-center`
- Spacing: `mt-6`, `mb-4`, `p-4`, `mx-auto`
- Sizing: `w-full`, `md:w-2/3`, `max-w-md`
- Typography sizing: `text-4xl`, `text-sm`, `font-bold`
- One-off adjustments not covered by DaisyUI components

## Why

- DaisyUI classes are semantic (`btn btn-primary` vs. `bg-blue-600 hover:bg-blue-500 text-white rounded-md px-3.5 py-2.5 font-medium`) — easier to read and maintain
- Theme-aware colors adapt automatically if themes change
- Consistent component appearance without manually matching utility classes across views
