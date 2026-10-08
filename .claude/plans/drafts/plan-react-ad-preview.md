# Plan: React Ad Preview via iframe

## Context

The admin show page and standalone preview render ads via ERB partials (`render "app/ads/layouts/#{@ad.layout}"`). Only `overlay`, `split`, and `stat_grid` have ERB partials — the 5 new layouts (`band`, `card`, `type_photo`, `mosaic`, `diptych`) will crash. Rather than create ERB partials for layouts that already have React compositions, embed the React player as an iframe. React is the single ad rendering engine.

## Architecture

```
Rails Admin                          React Player App
┌──────────────────────┐             ┌──────────────────────┐
│  Show / Preview page │             │  preview.html         │
│  ┌────────────────┐  │  URL param  │  ┌────────────────┐  │
│  │ <iframe>       │──┼─ ?pid=abc ──┼─►│ AdPreview      │  │
│  └────────────────┘  │             │  │  fetch /api/..  │  │
│                      │             │  │  └─ AdRenderer  │  │
└──────────────────────┘             └──┼────────────────┼──┘
                                       │  GET /app/ads/  │
                                       │  :pid/preview   │
                                       └────────────────┘
```

**Flow:** iframe loads `preview.html?pid=abc123` → React fetches ad data from a Rails JSON endpoint → renders with `AdRenderer`.

---

## Phase 1: Preview API endpoint

**Goal:** A Rails endpoint that returns a single ad as ManifestPlaylistAd JSON.

### New files

**`app/services/ad/manifest_serializer.rb`** — Only handles ListingAd (the only ad type):
```ruby
class Ad::ManifestSerializer
  include Rails.application.routes.url_helpers

  def initialize(ad, position: 0, duration: 10)
    @ad = ad
    @position = position
    @duration = duration
  end

  def as_json(*)
    {
      pid: @ad.public_id,
      updated_at: @ad.updated_at.to_i,
      position: @position,
      duration: @duration,
      headline: @ad.headline,
      body: @ad.body,
      layout: @ad.layout,
      theme: @ad.theme,
      images: serialize_images(@ad),
      adable: serialize_listing_ad(@ad.adable)
    }
  end
end
```

Mirror the existing jbuilder partials:
- `app/views/api/v1/players/manifests/_ad.json.jbuilder`
- `app/views/api/v1/players/manifests/ads/_listing_ad.json.jbuilder`
- `app/views/api/v1/players/manifests/_listing.json.jbuilder`
- `app/views/api/v1/players/manifests/_agent.json.jbuilder`

Include structured address fields: `street`, `city`, `state`, `zip`, `neighborhood`.

**`app/controllers/app/ads_controller.rb`** — Update existing `preview` action to respond to JSON:
```ruby
def preview
  authorize! @ad, to: :show?
  respond_to do |format|
    format.html { render layout: "preview" }
    format.json { render json: Ad::ManifestSerializer.new(@ad).as_json }
  end
end
```

No route changes needed — the existing `member { get :preview }` handles both formats.

### Tests
- **`spec/services/ad/manifest_serializer_spec.rb`** — Verify JSON shape for a listing ad

---

## Phase 2: React preview entry point

**Goal:** A standalone React page that fetches an ad by PID and renders it.

### New files
- **`player-app/preview.html`** — Minimal HTML, mounts `<AdPreview />`
- **`player-app/src/preview.tsx`** — Entry point: `createRoot` → `<AdPreview />`
- **`player-app/src/components/ads/AdPreview/index.tsx`** — Core component:
  - Reads `pid` from URL search params
  - Fetches from `/app/ads/:pid/preview.json` (with credentials for session auth)
  - Renders `<AdRenderer ad={ad} />` when loaded
  - Dark placeholder while loading

### Modified files
- **`player-app/vite.config.ts`** — Add multi-page build input:
  ```ts
  build: {
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html'),
        preview: resolve(__dirname, 'preview.html'),
      }
    }
  }
  ```
  Add dev proxy for the preview endpoint:
  ```ts
  '/app/ads': {
    target: process.env.API_URL || 'http://localhost:3000',
    changeOrigin: true,
    headers: { 'Host': 'app.replay.localhost' }
  }
  ```

### Verification
Open `http://play.replay.localhost:3100/preview.html?pid=<ad_public_id>` — ad renders.

---

## Phase 3: Show page + standalone preview → iframe

**Goal:** Replace ERB layout rendering with React iframe.

### Modified files
- **`app/views/app/ads/show.html.erb`** — Replace `render "app/ads/layouts/#{@ad.layout}", ad: @ad` with:
  ```erb
  <div class="w-full aspect-video">
    <iframe src="<%= ad_preview_iframe_url(@ad) %>"
            class="w-full h-full border-0"
            sandbox="allow-scripts allow-same-origin"
            loading="eager"></iframe>
  </div>
  ```

- **`app/views/app/ads/preview.html.erb`** — Full-screen iframe:
  ```erb
  <iframe src="<%= ad_preview_iframe_url(@ad) %>"
          class="w-dvw h-dvh border-0"
          sandbox="allow-scripts allow-same-origin"
          loading="eager"></iframe>
  ```

- **`app/helpers/ads_helper.rb`** — Add helper:
  ```ruby
  def ad_preview_iframe_url(ad)
    base = ENV.fetch("PLAYER_PREVIEW_URL", "http://play.replay.localhost:3100")
    "#{base}/preview.html?pid=#{ad.public_id}"
  end
  ```

### CSP update
- **`config/initializers/content_security_policy.rb`** — Add `frame-src`:
  ```ruby
  policy.frame_src :self, "http://play.replay.localhost:*", "https://play.replaytv.co"
  ```

### Environment
- `PLAYER_PREVIEW_URL` — Dev: `http://play.replay.localhost:3100`, Prod: `https://play.replaytv.co`

### Notes
- `sandbox="allow-scripts allow-same-origin"` needed so the iframe can fetch from the Rails API with session cookies
- The iframe fetches `/app/ads/:pid/preview.json` which requires authentication — the session cookie flows through since it's same-origin in production (both on `replaytv.co`)
- In dev, the Vite proxy forwards `/app/ads` to Rails at `:3000`

---

## Out of scope

- **Form builder live preview** — still uses ERB partials via Turbo Stream
- **ERB partial deletion** — form builder's `_preview_canvas.html.erb` still calls `render "app/ads/layouts/#{ad.layout}"`; partials stay for now
- **Unsaved ad preview** — only persisted ads supported via PID

---

## Verification

1. **Phase 1:** `make test-file FILE=spec/services/ad/manifest_serializer_spec.rb`
2. **Phase 2:** Open `preview.html?pid=<pid>` in browser — ad renders
3. **Phase 3:** Ad show page renders preview in iframe; Preview button opens full-screen iframe
