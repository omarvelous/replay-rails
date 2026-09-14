# Analysis: Ad & Experience Rendering Architecture

## The Question

Should ad and experience rendering stay in Rails ERB, move to a
JavaScript framework (React, etc.), or go native (React Native)?
The goal: **faster UI/UX iteration** on the player-facing content.

---

## Current Architecture

### How ads render today

```
Rails Server
  ├── GET /players/:token (HTML)
  │     └── ERB layout partial (hero, split, minimal, etc.)
  │           └── ERB content partial (listing_ad, agent_ad, etc.)
  │                 └── Rails helpers (number_to_currency, image_tag, ad_theme_style)
  │
  └── GET /api/players/:token/manifest (JSON)
        └── Metadata only (IDs, timestamps, attachment IDs)
            └── Used for change detection (ETag polling), NOT rendering
```

**Key fact:** The player loads a full HTML page from Rails. The
manifest API exists but only serves metadata for cache invalidation —
it doesn't include the data needed to render ads (no prices,
addresses, agent names, photo URLs, etc.).

### Where ads currently render

| Surface | How | Tech |
|---------|-----|------|
| Player playback (device) | Server-rendered HTML, full page load | ERB + Stimulus (slideshow transitions) |
| Admin ad preview | Same ERB partials inline | ERB |
| Admin full-screen preview | Same ERB partials, full viewport | ERB |
| Ad form live edit | Simplified placeholder (NOT real layout) | Stimulus (text-only updates) |
| Experience kiosk | Server-rendered HTML, photo gallery | ERB + Stimulus (experience controller) |

**The layout partials are the single source of truth.** One set of
templates renders ads everywhere. No duplication.

### What makes iteration slow today

1. **Server round-trip for every change.** Editing an ad's layout or
   theme requires a save → reload to see the result. The form live
   preview is a simplified placeholder, not the actual ad layout.

2. **ERB is not component-oriented.** Partials share data via locals,
   not typed interfaces. Changing a partial's expected data can break
   callers silently. No unit tests for rendering.

3. **No hot reload.** Changing a partial requires a page refresh.
   Stimulus controllers hot-reload, but ERB does not.

4. **CSS iteration is fine.** Tailwind + container queries + CSS
   custom properties already enable fast styling iteration. The
   bottleneck is the HTML structure and data flow, not the styling.

5. **Experiences are more complex.** Photo galleries, touch gestures,
   idle timeouts, modal overlays — these are UI-heavy interactions
   that Stimulus handles but not elegantly at scale.

---

## Option A: Keep Everything in Rails (Status Quo + Improvements)

### What this means

Stay with ERB partials + Stimulus. Improve iteration speed by fixing
the specific pain points without changing the architecture.

### Improvements available

1. **Real-time form preview with Turbo Frames.** Replace the
   simplified placeholder with a Turbo Frame that re-renders the
   actual layout partial on each form change. Debounced form
   submission → server renders the real ad → Turbo Frame replaces
   the preview. ~200ms round-trip in development.

2. **ViewComponent for ad layouts.** (Already planned — see
   `plan-lookbook-viewcomponent.md`.) Typed interfaces, unit-testable
   rendering, Lookbook for visual browsing. Doesn't change the
   rendering technology, but makes iteration safer and more visible.

3. **Stimulus component library.** Build reusable Stimulus controllers
   for common patterns: carousel, modal, idle-timeout, touch-swipe.
   These compose to build the Experience UI without a framework.

4. **Rails 8.1 Hotwire improvements.** Turbo 8 morphing can do
   partial page updates without full reloads. Combined with Turbo
   Streams, the admin preview can update in real-time.

### Pros

- **Zero migration cost.** Everything works today. Incremental
  improvements, not a rewrite.
- **One codebase.** No build pipeline, no API contract to maintain,
  no deployment coordination.
- **SEO/SSR for free.** Go pages and marketing site are server-
  rendered HTML. No hydration concerns.
- **Team knowledge.** You know Rails. Context-switching to React
  has a learning curve and a productivity dip.
- **Hotwire is getting better.** Turbo 8 morphing, Stimulus hot-
  reload, and the Rails ecosystem are actively closing the gap
  with SPAs for most use cases.

### Cons

- **Ceiling on interactivity.** Complex touch interactions (pinch-
  to-zoom, gesture-based navigation, physics-based animations) are
  awkward in Stimulus. Not impossible, but you're fighting the grain.
- **No component dev server.** Even with Lookbook, you can't iterate
  on a component in isolation with hot reload the way you can with
  Storybook + React.
- **Form preview latency.** Even with Turbo Frames, the real-time
  preview has a server round-trip. React would be instant.
- **Experiences will strain Stimulus.** The experience controller
  is already the most complex Stimulus controller in the app. Adding
  sections (floor plan viewer, mortgage calculator, neighborhood
  content) will push it further.

### Best for

Projects where the admin dashboard and player share the same
rendering stack and interactivity needs are moderate. Which is
exactly where RePlay is today.

### Effort: Low (weeks of incremental improvements)

---

## Option B: React for Player & Experience Rendering Only

### What this means

The Rails app remains the admin/management layer. The player and
experience rendering moves to a React app that consumes the manifest
API. The admin still uses ERB for its own UI.

```
Rails App (admin, go pages, marketing, API)
  └── API: /api/players/:token/manifest (enriched with display data)

React App (player rendering)
  ├── Playlist slideshow (React components for each layout)
  ├── Experience kiosk (React components with touch interactions)
  └── Hosted as static assets, loaded in WebView or iframe
```

### What changes

1. **Manifest API gets enriched.** Currently serves only IDs and
   timestamps. Would need to include all display data: headline,
   body, price, address, beds/baths/sqft, agent name/phone, photo
   URLs, QR code SVGs, theme, layout — everything the ad partials
   currently pull from ActiveRecord.

2. **Ad layout components in React.** Each layout (hero, split,
   minimal, etc.) becomes a React component. Same CSS (Tailwind +
   container queries + CSS custom properties). Different templating.

3. **Experience becomes a React SPA.** Photo gallery, touch
   gestures, idle timeout, lead form — all React components with
   proper state management.

4. **Player app loads React instead of Rails HTML.** The Android
   WebView points to a static React build (or a thin Rails page
   that bootstraps React) instead of server-rendered HTML.

5. **Admin preview embeds React.** The ad form preview uses the
   same React components (via iframe or embedded mount), giving
   instant client-side preview without server round-trips.

### Pros

- **Instant preview in admin.** Change headline → see it in the
  real layout immediately. No server round-trip.
- **Rich interactions for Experiences.** React's component model,
  state management, and ecosystem (Framer Motion, react-spring,
  Swiper) make complex touch UIs much easier.
- **Hot module reload.** Change a layout component → see it update
  instantly in the browser. Fastest possible iteration loop.
- **Component isolation.** Each layout is a self-contained component
  with typed props (TypeScript). Storybook for visual browsing and
  testing. Exactly the dev experience you're looking for.
- **Shared rendering across platforms.** The same React components
  render in the player WebView, the admin preview, and potentially
  a future web-based player (no Android app needed).
- **Better tooling for animation/gesture.** Libraries like Framer
  Motion, react-use-gesture, and Swiper are purpose-built for the
  kind of interactions Experiences need.

### Cons

- **Two rendering stacks.** Ad layouts exist in both ERB (admin
  show/preview pages) and React (player). Or you go all-in on React
  for all ad rendering and embed it in the admin too — but now you
  have a JS build pipeline in a Rails app.
- **API contract maintenance.** Every model change needs a
  corresponding API change. Add a field to ListingAd → update the
  Jbuilder → update the React component. Two places to change
  instead of one.
- **Build complexity.** React needs a build step (Vite, esbuild,
  etc.). The app currently uses importmap-rails with zero build.
  Adding a JS build pipeline is a one-time cost but adds ongoing
  complexity.
- **Duplication risk.** If the admin show page still uses ERB to
  render ads (for non-player contexts), you have two sources of
  truth for how an ad looks. They will drift.
- **Overkill for passive playlists.** The slideshow is a simple
  opacity crossfade on a timer. React adds complexity for something
  Stimulus does in 50 lines. The value is in Experiences, not
  playlists.

### Architecture variant: React in Rails (not separate app)

Instead of a separate React app, embed React components inside the
Rails app using a tool like `react-rails`, `vite_rails`, or
`inertia-rails`:

- **react-rails gem:** Mount React components in ERB views.
  `<%= react_component("AdLayout", ad: @ad.as_json) %>`. Simple
  but feels bolted-on.
- **Inertia.js:** Replace ERB views with React pages while keeping
  Rails controllers. The Rails app serves JSON props, React renders
  the page. Clean separation but replaces ALL views, not just ads.
- **Vite Rails + islands:** Use `vite_rails` for the JS build and
  mount React "islands" only where needed (ad preview, player page).
  The rest stays ERB. Most surgical option.

### Best for

Projects where the player UI is significantly more interactive than
the admin UI, and you want to invest in a rich component library.
This is where RePlay is heading with Experiences.

### Effort: Medium-Large (4-6 weeks for player + experience)

---

## Option C: React Native for the Player App

### What this means

Replace the Android WebView player entirely with a React Native app.
Ad layouts and experiences are React Native components rendering
natively on the device.

```
Rails App (admin, API)
React Native App (player)
  ├── Native UI components (not a WebView)
  ├── Consumes manifest API
  ├── Native touch gestures, animations, transitions
  └── Builds to Android APK (and iOS if needed later)
```

### What changes

1. **Player is no longer a WebView.** Native rendering instead of
   HTML/CSS in a browser container.
2. **Ad layouts rewritten in React Native.** Same visual design,
   but using `<View>`, `<Text>`, `<Image>` instead of HTML divs.
3. **No CSS container queries.** React Native doesn't support CSS.
   Responsive scaling would use `Dimensions` API or `useWindowDimensions`.
4. **Native gestures.** Pinch-to-zoom, swipe, drag — all handled by
   `react-native-gesture-handler` and `react-native-reanimated`.

### Pros

- **Best possible performance.** Native rendering is smoother than
  WebView for animations and transitions.
- **True native touch.** Gesture handling is first-class, not
  bridged through a WebView.
- **Offline-first.** React Native makes it natural to cache content
  locally and sync when online.
- **Platform capabilities.** Direct access to battery, WiFi, HDMI-CEC,
  sensors — no JS bridge needed.
- **React Native + Expo.** Modern React Native (with Expo) has
  excellent DX, hot reload, and OTA updates via EAS.

### Cons

- **Throws away your entire CSS system.** Container queries, CSS
  custom properties, Tailwind classes — none of this works in React
  Native. Every ad layout is a ground-up rewrite using React Native's
  StyleSheet API.
- **Two completely separate UI stacks.** Admin is Rails/ERB/Tailwind.
  Player is React Native. Zero code sharing for rendering. An ad
  will look different in the admin preview vs. on the device unless
  you meticulously keep both in sync.
- **You already have a working Android app.** The custom player app
  (plan-custom-player-app.md) is ~50 lines of Kotlin wrapping a
  WebView. It works. React Native replaces a simple, working solution
  with a complex one.
- **Larger team needed.** React Native requires a different skill set
  from Rails. You'd need to maintain two stacks or hire.
- **OEM Android displays may have quirks.** React Native on cheap
  OEM Android tablets can have rendering issues, touch calibration
  problems, and missing native modules. WebView is more universally
  compatible.
- **No code sharing with admin.** Unlike Option B (React for web),
  React Native components can't render in the Rails admin preview
  without a web target build (React Native Web), which adds another
  layer of complexity.

### Best for

Projects where the player needs to feel like a native app (think:
a consumer mobile app). RePlay's player is a kiosk display — it
doesn't need to feel like an app store app. It needs to render
content reliably on commodity Android hardware.

### Effort: Large (8-12 weeks, plus ongoing dual-stack maintenance)

---

## Option D: React Web Components (Islands Architecture)

### What this means

Keep Rails as the primary framework. Build ad layouts and experience
UI as **Web Components** (using React, Lit, or Svelte internally)
that can be dropped into any HTML context — ERB templates, the
player WebView, even a future non-Rails frontend.

```
Rails App (everything)
  └── ERB views embed Web Components
        <replay-ad layout="hero" theme="dark" :data="<%= @ad.to_json %>">
        </replay-ad>

Web Component Library (separate package)
  ├── <replay-ad> — renders any ad layout
  ├── <replay-experience> — interactive kiosk
  ├── <replay-slideshow> — playlist player
  └── Built with React/Lit/Svelte, compiled to Web Components
```

### What changes

1. **Ad layouts become framework-agnostic components.** They render
   anywhere HTML renders: Rails ERB, a static page, an iframe, a
   WebView.
2. **Data passed via attributes/properties.** The Rails view
   serializes ad data as JSON and passes it to the component. No
   server-side rendering of ad HTML.
3. **One component, many surfaces.** The same `<replay-ad>` renders
   in admin preview, player playback, form live preview, and Lookbook.
4. **Separate dev server for components.** Storybook or similar for
   isolated component development with hot reload.

### Pros

- **True single source of truth.** One component definition renders
  everywhere. No ERB partial AND React component for the same ad.
- **Framework-agnostic.** If you ever move away from Rails, the
  components come with you.
- **Works with importmap.** Web Components don't require a full SPA
  build pipeline. You can load them as ES modules via importmap.
- **Incremental adoption.** Replace one ERB partial at a time. No
  big bang migration.
- **Admin preview is instant.** Change data props → component
  re-renders client-side. No server round-trip.

### Cons

- **Web Components have rough edges.** Server-side rendering is
  limited (Declarative Shadow DOM helps but isn't universal). Form
  integration is fiddly. Styling encapsulation can fight Tailwind.
- **Smaller ecosystem.** Fewer libraries, fewer examples, fewer
  developers who've built with Web Components at scale.
- **Shadow DOM vs. Tailwind.** If components use Shadow DOM, Tailwind
  classes from the parent don't penetrate. You'd need to either skip
  Shadow DOM (losing encapsulation) or bundle Tailwind inside each
  component (bundle size).
- **Learning curve.** Web Components are conceptually simple but
  have practical gotchas that trip up experienced developers.

### Best for

Projects that need framework-agnostic rendering and are willing to
deal with Web Component rough edges. Interesting architecturally but
may be more complexity than the problem warrants.

### Effort: Medium (4-6 weeks, similar to Option B)

---

## Option E: Hybrid — Rails + React Islands for Player Only

### What this means

This is the surgical version of Option B. Rails stays as-is for
everything except the player and experience views, which get React
"islands" mounted into the existing Rails pages.

```
Rails App (everything, including player routes)
  ├── Admin: ERB (no change)
  ├── Marketing/Go: ERB (no change)
  ├── Player show: ERB shell + React island for slideshow
  ├── Experience: ERB shell + React island for kiosk UI
  └── Ad form preview: ERB shell + React island for live preview
```

### What changes

1. **Add Vite to the Rails app** (`vite_rails` gem). Runs alongside
   importmap — existing Stimulus controllers are unaffected.
2. **Build React components for:**
   - `<AdCanvas>` — renders any ad layout with theme/data props
   - `<Slideshow>` — playlist rotation with transitions
   - `<ExperienceKiosk>` — photo gallery, touch, lead form, idle
   - `<AdPreview>` — real-time form preview
3. **Mount points in ERB.** The Rails view renders a div with
   `data-react-component="Slideshow"` and `data-props="<%= json %>"`.
   Vite's JS picks it up and mounts React.
4. **Manifest API enriched.** Same as Option B — full display data
   in JSON for client-side rendering.
5. **Stimulus controllers retire gradually.** `slideshow_controller`
   and `experience_controller` are replaced by React. `device_playback_controller`
   stays (it handles ActionCable and heartbeat, which are transport
   concerns, not rendering).

### Pros

- **Surgical.** Only 3-4 views change. The other 50+ views stay ERB.
- **One repo, one deploy.** No separate frontend app to deploy and
  version.
- **Shared CSS.** React components use the same Tailwind config and
  CSS custom properties. Container queries work in React the same
  way they work in ERB — they're CSS, not framework-specific.
- **Admin preview uses the same components.** The ad form page mounts
  `<AdPreview>` with live data from form inputs. Instant, accurate,
  no server round-trip.
- **Incremental.** Start with the ad preview island. Then slideshow.
  Then experience. Each is an independent migration.
- **TypeScript for ad data contracts.** Define `AdProps`,
  `ListingAdProps`, etc. as TypeScript interfaces. The API and
  components share a typed contract. Changes are caught at compile
  time.

### Cons

- **Two JS paradigms.** Stimulus for most of the app, React for
  player rendering. Developers need to know both.
- **Vite adds build complexity.** Currently zero JS build. Adding
  Vite is a one-time cost but it's a new thing to maintain.
- **ERB ad partials become legacy.** The admin show page and preview
  page still use ERB partials for ad rendering (unless you replace
  those with React islands too). During migration, ads render in
  two places.

### Best for

Projects that need rich interactivity in specific areas but don't
want to rewrite the whole frontend. **This is the sweet spot for
RePlay.**

### Effort: Medium (3-5 weeks, incremental)

---

## Comparison Matrix

| Factor | A: Rails Only | B: React App | C: React Native | D: Web Components | E: React Islands |
|--------|:---:|:---:|:---:|:---:|:---:|
| **Migration effort** | None | Large | Very Large | Medium | Medium |
| **Iteration speed (ads)** | Moderate | Fast | Fast | Fast | Fast |
| **Iteration speed (experiences)** | Moderate | Fast | Fastest | Fast | Fast |
| **Admin preview fidelity** | Good (Turbo) | Exact | Separate | Exact | Exact |
| **Touch/gesture support** | Adequate | Good | Best | Good | Good |
| **Code duplication risk** | None | High | Very High | None | Low (during migration) |
| **Build complexity** | None | Medium | High | Low-Medium | Low-Medium |
| **Team skill required** | Rails | Rails + React | Rails + RN | Rails + WC | Rails + React |
| **Offline capability** | Low | Medium | High | Medium | Medium |
| **CSS system reuse** | 100% | 100% | 0% | Partial | 100% |
| **Works on OEM Android** | Yes | Yes | Risky | Yes | Yes |
| **Future flexibility** | Low | Medium | Medium | High | Medium |

---

## Recommendation

### Short-term (now → NYC launch): Option A

Don't change the architecture before launch. The current stack works.
The pain points are real but manageable:

- Add **ViewComponent + Lookbook** (already planned) for component
  isolation and visual browsing
- Improve the **form preview with Turbo Frames** for faster editing
- Build Experiences in Stimulus — it's adequate for v1

This keeps you shipping features, not rewriting infrastructure.

### Medium-term (post-launch, 10+ customers): Option E

Once the product is validated and you're iterating on the Experience
UI based on real agent feedback, add **React islands for the player
and experience views only**:

1. Add `vite_rails` to the project
2. Build `<AdCanvas>` and `<Slideshow>` React components
3. Enrich the manifest API with full display data
4. Mount React islands in the player and experience views
5. Add `<AdPreview>` to the ad form for instant live preview
6. Retire `slideshow_controller.js` and `experience_controller.js`

This gives you the fast iteration loop for the content that matters
most (what agents and visitors see) without touching the 50+ admin
views that work fine in ERB.

### Don't do (for now)

- **React Native (Option C):** Your player is a WebView kiosk, not a
  consumer mobile app. The WebView approach works on every Android
  device. React Native throws away your entire CSS system for
  marginal performance gains on hardware that doesn't need them.

- **Full React SPA (Option B as separate app):** Creates a second
  deployment, a second codebase, and a versioning problem between
  the API and the frontend. The benefits over React islands don't
  justify the operational cost at your scale.

- **Web Components (Option D):** Interesting architecture but the
  ecosystem and tooling aren't mature enough. Shadow DOM + Tailwind
  is a known pain point. Revisit in a year.

---

## If You Go With Option E: Key Decisions

### 1. Build tool

**Vite via `vite_rails` gem.** It coexists with importmap — existing
Stimulus controllers keep working. Vite handles only the React
components. One `vite.config.ts`, one `package.json` addition.

### 2. React components scope

Start narrow:

| Component | Replaces | Priority |
|-----------|----------|----------|
| `<AdCanvas>` | ERB layout partials (hero, split, etc.) | First — it's the core rendering unit |
| `<Slideshow>` | `slideshow_controller.js` | Second — wraps AdCanvas in playlist rotation |
| `<ExperienceKiosk>` | `experience_controller.js` | Third — the big UX win |
| `<AdPreview>` | The simplified form placeholder | Fourth — instant admin preview |
| `<LeadForm>` | Go page lead form | Optional — only if you want consistency |

### 3. Data flow

Enrich the manifest API to serve everything React needs:

```json
{
  "contentable": {
    "type": "Playlist",
    "playlist_ads": [{
      "position": 1,
      "duration": 10,
      "ad": {
        "layout": "hero",
        "theme": "dark",
        "headline": "Beautiful Oceanview Estate",
        "body": "Experience luxury coastal living.",
        "image_url": "https://...",
        "adable": {
          "type": "listing_ad",
          "badge": "just_listed",
          "listing": {
            "price": 2450000,
            "address": "1234 Oceanview Dr",
            "beds": 4, "baths": 3, "sqft": 3200,
            "photos": ["https://...", "..."],
            "qr_svg": "<svg>...</svg>"
          },
          "agent": {
            "name": "Sarah Johnson",
            "phone": "+1 310-555-0147",
            "photo_url": "https://..."
          }
        }
      }
    }]
  }
}
```

The manifest becomes the source of truth for player rendering.
Rails server renders nothing for the player — just serves data.

### 4. CSS sharing

React components use the same Tailwind config and CSS custom
properties. Container queries work identically — they're CSS, not
framework-dependent. The `ad-canvas` class and `--ad-*` / `--s-*`
variables are pure CSS that React components inherit.

### 5. Keep `device_playback_controller.js` in Stimulus

ActionCable subscription, heartbeat, impression recording — these
are transport/analytics concerns, not rendering. They stay in
Stimulus and communicate with React via custom events or a shared
state store.

---

## Open Questions

1. **TypeScript or JavaScript?** TypeScript adds type safety for the
   ad data contract (which has many shapes: 4 ad types × 6 layouts).
   Worth the setup cost for this use case.

2. **State management?** The slideshow is simple state (current index,
   timer). The experience is more complex (active section, idle state,
   form data, gallery position). React's built-in useState/useReducer
   is probably sufficient — no need for Redux/Zustand at this scale.

3. **Testing?** React components can be tested with Vitest + Testing
   Library. Storybook for visual testing. This replaces Lookbook for
   the React components (Lookbook stays for any remaining ERB
   components).

4. **Deployment?** Vite builds assets at deploy time. `vite_rails`
   integrates with the Rails asset pipeline — `bin/rails assets:precompile`
   runs the Vite build. No separate deployment.
