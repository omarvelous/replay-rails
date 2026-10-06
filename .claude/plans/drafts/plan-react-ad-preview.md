# Plan: React Ad Preview via iframe

## Context

Ad previews are rendered twice: Rails ERB partials for the admin (show page, standalone preview) and React components for the player. Every layout change requires updating both. This plan replaces the admin's ERB rendering with React via iframe — React becomes the single ad rendering engine for persisted ads. The form builder's live preview is out of scope for now.

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

**Flow:** iframe loads `preview.html?pid=abc123` → React fetches ad data from a Rails API endpoint → renders with `AdRenderer`. Simple URL-based, no postMessage.

---

## Phase 1: Preview API endpoint

**Goal:** A Rails endpoint that returns a single ad as `ManifestPlaylistAd` JSON.

### New files
- **`app/services/ad/manifest_serializer.rb`** — Converts a persisted `Ad` to ManifestPlaylistAd JSON:
  - `initialize(ad, position: 0, duration: 10)`
  - `as_json` → Hash matching the ManifestPlaylistAd TypeScript type
  - Handles all 4 ad types (ListingAd, AgentAd, BrandAd, CollectionAd)
  - Uses `rails_storage_proxy_url` for image attachments
  - CollectionAd: recursively serializes member ads

- **`app/controllers/app/ads/previews_controller.rb`** — API endpoint:
  ```ruby
  # GET /app/ads/:id/preview.json
  def show
    @ad = Current.account.ads.find_by_param!(params[:ad_id])
    authorize! @ad, to: :show?
    render json: Ad::ManifestSerializer.new(@ad).as_json
  end
  ```

- **`spec/services/ad/manifest_serializer_spec.rb`** — Unit tests for each ad type

### Modified files
- **`config/routes.rb`** — Add JSON preview route nested under ads:
  ```ruby
  resources :ads do
    resource :preview, only: :show, controller: "ads/previews"
  end
  ```

### Reference — mirror these existing jbuilder partials:
- `app/views/api/v1/players/manifests/_ad.json.jbuilder`
- `app/views/api/v1/players/manifests/ads/_listing_ad.json.jbuilder`
- `app/views/api/v1/players/manifests/_listing.json.jbuilder`
- `app/views/api/v1/players/manifests/_agent.json.jbuilder`
- (and agent_ad, brand_ad, collection_ad variants)

---

## Phase 2: React preview entry point

**Goal:** A standalone React page that fetches an ad by PID and renders it.

### New files
- **`player-app/preview.html`** — Minimal HTML page, mounts `<AdPreview />`
- **`player-app/src/preview.tsx`** — Entry point: `createRoot` → `<AdPreview />`
- **`player-app/src/components/ads/AdPreview/index.tsx`** — Core component:
  - Reads `pid` from URL search params
  - Fetches ad data from `/app/ads/:pid/preview.json`
  - Renders `<AdRenderer ad={ad} />` when data loaded
  - Shows dark placeholder while loading

### Modified files
- **`player-app/vite.config.ts`** — Add multi-page input + proxy for `/app/ads` preview endpoint:
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
  Add proxy entry:
  ```ts
  '/app/ads': {
    target: process.env.API_URL || 'http://localhost:3000',
    changeOrigin: true,
    headers: { 'Host': 'app.replay.localhost' }
  }
  ```

### Verification
Open `http://play.replay.localhost:3100/preview.html?pid=<ad_public_id>` — should render the ad.

---

## Phase 3: Show page + standalone preview → iframe

**Goal:** Replace ERB layout rendering on show page and standalone preview with React iframe.

### Modified files
- **`app/views/app/ads/show.html.erb`** — Replace `render "app/ads/layouts/#{@ad.layout}", ad: @ad` with:
  ```erb
  <div class="w-full aspect-video">
    <iframe src="<%= ad_preview_iframe_url(@ad) %>"
            class="w-full h-full border-0"
            sandbox="allow-scripts" loading="eager" />
  </div>
  ```

- **`app/views/app/ads/preview.html.erb`** — Full-screen iframe:
  ```erb
  <iframe src="<%= ad_preview_iframe_url(@ad) %>"
          class="w-dvw h-dvh border-0"
          sandbox="allow-scripts" loading="eager" />
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
- Add `PLAYER_PREVIEW_URL` to dev/staging/production environments
- Dev: `http://play.replay.localhost:3100`
- Prod: `https://play.replaytv.co`

---

## Out of scope

- **Form builder live preview** — still uses ERB partials via Turbo Stream (migrate later)
- **ERB partial deletion** — can't delete layout/content partials while form builder still references them
- **Unsaved ad preview** — only persisted ads are supported via PID

---

## Verification

1. **Phase 1:** `make test-file FILE=spec/services/ad/manifest_serializer_spec.rb` — all green
2. **Phase 2:** Open `preview.html?pid=<pid>` in browser — ad renders correctly
3. **Phase 3:** View ad show page — preview renders in iframe; click Preview button — full-screen iframe
