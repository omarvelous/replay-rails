# Plan: Accessibility Fixes

## Context

Audit found 6 accessibility gaps — no critical mobile issues. The app is responsive and well-structured, but image alt text, form labels, and ARIA coverage need work. WCAG AA compliance is the target.

---

## Phase 1: Image alt text (high priority)

Add meaningful `alt` attributes to all `image_tag` calls that currently lack them.

### Files to fix
- `app/views/app/listings/_listing_card.html.erb` — listing photos: `alt: listing.address`
- `app/views/app/leads/show.html.erb` — lead listing photo: `alt: @lead.listing.address`
- `app/views/go/agents/show.html.erb` — agent photo: `alt: @agent.name`
- `app/views/go/shared/_floor_plans.html.erb` — floor plan: `alt: "Floor plan"`
- `app/views/go/listings/show.html.erb` — listing gallery photos: `alt: "#{@listing.address} photo #{i+1}"`
- Any other `image_tag` without `alt` — grep and fix

### Rule
- Functional images: descriptive alt (address, name)
- Decorative images: `alt: ""`
- Photos in galleries: `alt: "Property photo"` or address-based

---

## Phase 2: Form labels (high priority)

Replace placeholder-only patterns with proper `<label>` elements. Placeholders disappear on focus — unusable for screen readers and users with cognitive disabilities.

### Public lead form
`app/views/go/listings/show.html.erb` (or wherever the lead capture form lives):
```erb
# Before
f.text_field :name, placeholder: "Your name"

# After
f.label :name, "Your name", class: "sr-only"
f.text_field :name, placeholder: "Your name"
```

Use `sr-only` (Tailwind's screen-reader-only class) to keep the visual design unchanged while making labels accessible.

### Files to fix
- `app/views/go/listings/show.html.erb` — lead form fields (name, email, phone, message)
- Any other forms using placeholder-only pattern

---

## Phase 3: Color contrast (medium priority)

`text-gray-300` on white backgrounds fails WCAG AA (3.7:1, needs 4.5:1). Replace with `text-gray-400` (4.5:1) or `text-gray-500` (5.8:1) minimum.

### Find and fix
```bash
grep -rn "text-gray-300" app/views/ --include="*.erb"
```

Review each usage — some may be on dark backgrounds where contrast is fine. Only fix instances on light/white backgrounds.

### Files
- Various view files — case-by-case review

---

## Phase 4: Skip link (low priority, quick win)

Add a "Skip to main content" link at the top of the application layout. Hidden until focused via keyboard.

### Implementation
```erb
# app/views/layouts/application.html.erb — first thing inside <body>
<a href="#main-content" class="sr-only focus:not-sr-only focus:absolute focus:z-50 focus:p-4 focus:bg-white focus:text-indigo-600 focus:font-semibold">
  Skip to main content
</a>

# On the main content area
<main id="main-content">
```

### Files
- `app/views/layouts/application.html.erb`
- `app/views/layouts/public.html.erb` (if separate)

---

## Phase 5: ARIA enhancements (medium priority)

Add missing ARIA attributes to interactive elements.

### Sidebar nav
- Add `aria-current="page"` to active nav link
- Add `aria-expanded` to mobile menu toggle button

### Modals/dialogs
- Ensure `role="dialog"` and `aria-modal="true"` on dialog panels
- Add `aria-labelledby` pointing to dialog title

### Buttons
- Add `aria-label` to icon-only buttons (close, delete, etc.)
- Add `focus-visible:ring-2 focus-visible:ring-indigo-500` to icon buttons

### Files
- `app/views/layouts/application.html.erb` — sidebar, mobile toggle
- Various views with icon-only buttons

---

## Phase 6: React player accessibility (medium priority)

The player runs on signage screens (no keyboard/screen reader users), but the preview iframe and Storybook should be accessible.

### AdPreview
- Add `role="img"` and `aria-label` to the ad canvas

### Elements
- `Badge`: already uses semantic `<span>` — fine
- `AgentStrip`: add `alt` to agent photo `<img>`
- `PhotoWrap`: add `alt` to listing photo `<img>` (currently `alt=""`)
- `QrCode`: add `aria-label="QR code"`

### Files
- `player-app/src/components/ads/elements/AgentStrip/index.tsx`
- `player-app/src/components/ads/elements/PhotoWrap/index.tsx`
- `player-app/src/components/ads/elements/QrCode/index.tsx`
- `player-app/src/components/ads/AdPreview/index.tsx`

---

## Execution order

| Phase | What | Effort | Impact |
|-------|------|--------|--------|
| 1 | Image alt text | 15 min | High — fixes critical a11y gap |
| 2 | Form labels | 15 min | High — screen reader usability |
| 3 | Color contrast | 15 min | Medium — WCAG AA compliance |
| 4 | Skip link | 5 min | Low — keyboard nav efficiency |
| 5 | ARIA enhancements | 30 min | Medium — interactive element a11y |
| 6 | React player a11y | 15 min | Medium — preview/Storybook a11y |

## Verification

- Phases 1-5: Manual check with browser accessibility inspector
- Phase 6: Run Storybook a11y addon — check for violations
- All phases: `make test` and `npm run build` still pass
