# Plan: React Player App

**Created:** 2026-10-01
**Status:** Draft
**Branch:** TBD

## Problem

The server-rendered player (ERB + Stimulus) has fundamental
limitations:

- **No offline support** — if the network drops, the player goes
  blank. Kiosk/signage devices need to keep playing.
- **Cookie-based auth** — fragile across subdomains, revocations
  break the device, browser kiosk modes clear cookies.
- **Full page reloads on content change** — switching content types
  (playlist ↔ experience) requires a page navigation. Flickers,
  loses JS state, re-initializes Stimulus controllers.
- **ETag/manifest detection fragile** — CDN stripping headers,
  race conditions between fetch and navigation.
- **No local state** — every page load fetches everything from
  scratch. No caching, no incremental updates.

## Goals

1. React SPA in `player-app/` within this repo
2. Bearer token auth (localStorage) — no cookies
3. Content changes re-render in place — no page reloads
4. ActionCable for real-time push, heartbeat as fallback
5. Hosted on Cloudflare Pages (`play.replaytv.co`)
6. Offline playback via Service Worker (Phase 2)
7. Existing HTML player remains functional during migration

## Design

### Directory structure

```
replay-rails/
├── player-app/
│   ├── src/
│   │   ├── main.tsx
│   │   ├── App.tsx
│   │   ├── api/
│   │   │   ├── client.ts           # fetch wrapper with bearer auth
│   │   │   ├── players.ts          # register, show, heartbeat
│   │   │   └── manifest.ts         # fetch manifest
│   │   ├── channels/
│   │   │   ├── consumer.ts         # createConsumer with token
│   │   │   ├── usePairingChannel.ts
│   │   │   └── useScreenChannel.ts
│   │   ├── components/
│   │   │   ├── PairingScreen.tsx
│   │   │   ├── Slideshow.tsx
│   │   │   ├── Experience.tsx
│   │   │   ├── IdleScreen.tsx
│   │   │   └── UnpairedScreen.tsx
│   │   ├── context/
│   │   │   └── PlayerContext.tsx   # token, publicId, api client, consumer
│   │   ├── hooks/
│   │   │   ├── usePlayer.ts        # identity, registration, state + localStorage sync
│   │   │   ├── useHeartbeat.ts     # 30s liveness + content version
│   │   │   └── useManifest.ts      # fetch + cache manifest data
│   │   └── types/
│   │       └── index.ts            # Player, Screen, Playlist, Ad, etc.
│   ├── public/
│   ├── index.html
│   ├── package.json
│   ├── tsconfig.json
│   ├── vite.config.ts
│   └── wrangler.toml
├── app/                            # Rails (unchanged)
└── ...
```

### Auth — bearer tokens, no cookies

Two values persisted in localStorage, hydrated into React state:
- `player_public_id` — device identity
- `player_token` — bearer token from registration

localStorage is persistence only. React state is the source of
truth at runtime. A `PlayerContext` provides the token to the
API client and all hooks — nothing reads localStorage directly
after initial hydration.

```typescript
// hooks/usePlayer.ts
const [token, setToken] = useState(() => localStorage.getItem("player_token"))
const [publicId, setPublicId] = useState(() => localStorage.getItem("player_public_id"))

function register(data: RegistrationResponse) {
  localStorage.setItem("player_token", data.token)
  localStorage.setItem("player_public_id", data.public_id)
  setToken(data.token)
  setPublicId(data.public_id)
}

function clear() {
  localStorage.removeItem("player_token")
  localStorage.removeItem("player_public_id")
  setToken(null)
  setPublicId(null)
}
```

```typescript
// api/client.ts — receives token from context, not localStorage
export function createApiClient(token: string | null) {
  return async function api(path: string, options: RequestInit = {}) {
    return fetch(path, {
      ...options,
      headers: {
        ...options.headers,
        ...(token && { "Authorization": `Bearer ${token}` }),
        "Content-Type": "application/json",
      },
    })
  }
}
```

### Player state machine

```
LOADING → check localStorage for token
  ├── no token → REGISTERING → POST /api/v1/players → store token
  │                 └→ PAIRING (show code, subscribe to PairingChannel)
  ├── token exists → GET /api/v1/player
  │   ├── 401 → clear localStorage → REGISTERING
  │   ├── paired: false → PAIRING
  │   └── paired: true → FETCHING_MANIFEST
  │                         └→ GET /api/v1/player/manifest
  │                             ├── playlist → PLAYING_PLAYLIST
  │                             ├── experience → PLAYING_EXPERIENCE
  │                             └── no content → IDLE
  └── UNPAIRED (received unpaired event) → PAIRING
```

All state transitions happen in React — no page navigations.
Switching from playlist to experience is a component swap, not
a reload.

### ActionCable connection

Use `@rails/actioncable` npm package. Pass bearer token via
query parameter on the WebSocket URL:

The consumer is created inside a hook that reads the token from
PlayerContext — not from localStorage:

```typescript
// channels/consumer.ts
import { createConsumer } from "@rails/actioncable"

export function createPlayerConsumer(token: string) {
  const wsUrl = `wss://${location.host}/cable?token=${encodeURIComponent(token)}`
  return createConsumer(wsUrl)
}
```

**Rails-side change required:** `ApplicationCable::Connection`
must authenticate players via bearer token in the query string,
not just cookies:

```ruby
# app/channels/application_cable/connection.rb
def find_verified_player
  # Existing cookie path
  if session = PlayerSession.active.find_by(id: cookies.signed[:player_session_id])
    return session.player
  end

  # Bearer token path (React app)
  if token = request.params[:token]
    session_id = Rails.application.message_verifier(:player_session).verify(token)
    PlayerSession.active.find_by(id: session_id)&.player
  end
rescue ActiveSupport::MessageVerifier::InvalidSignature
  nil
end
```

### Channels

**PairingChannel** — unchanged. React subscribes with the
pairing code, receives `{ paired: true }`, transitions to
manifest fetch.

**ScreenChannel** — unchanged. React subscribes after pairing,
receives `content_changed` / `unpaired` events. On
`content_changed`, refetch manifest and re-render. On `unpaired`,
transition to pairing state.

### Heartbeat with content version

The heartbeat response includes a content version so the device
can detect changes even if ActionCable misses a broadcast:

```ruby
# app/controllers/play/api/v1/players/heartbeats_controller.rb
def create
  # ... existing heartbeat logic ...
  screen_content = current_player.screen&.active_screen_content
  render_data({
    status: "ok",
    content_version: screen_content&.updated_at&.to_i
  })
end
```

React hook compares the version:

```typescript
// hooks/useHeartbeat.ts
if (data.content_version !== currentVersion) {
  refetchManifest()
}
```

**Touch chain** ensures `updated_at` cascades:
- `PlaylistAd` → touches `Playlist`
- `Playlist` → touches `ScreenContent` (via after_save callback)
- `ScreenContent#updated_at` becomes the authoritative version

### Content rendering

The manifest response already contains everything the player
needs. React components render directly from the manifest data:

- **Slideshow** — cycles through `playlist_ads` with timed
  transitions. Fires `content.impressed` analytics events via
  the API (Ahoy tracker).
- **Experience** — renders listing details, agent card, photos.
  Touch interactions for kiosk mode.
- **Idle** — "No content assigned" with a polling check.

Content switching (playlist → experience or vice versa) is a
React component swap — no DOM teardown, no flicker, no reload.

### CORS (Rails side)

The React app on Cloudflare Pages (`play.replaytv.co`) calls
the API on Render (`api.replaytv.co` or same origin via proxy).

**Option A — Cloudflare proxy:** Cloudflare routes `/api/*` on
`play.replaytv.co` to the Render backend. Same origin, no CORS
needed. Clean but requires Cloudflare Workers or Page Rules.

**Option B — CORS headers:** Add `rack-cors` gem scoped to
`/api/v1/*` and `/cable` for the Pages origins:

```ruby
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins /https:\/\/.*\.replaytv\.co/, /https:\/\/.*\.replaytv\.dev/
    resource "/api/v1/*", headers: :any, methods: [:get, :post, :patch], credentials: false
    resource "/cable", headers: :any, methods: [:get], credentials: false
  end
end
```

Option A is preferred — simpler, no CORS complexity. Cloudflare
can route API traffic to Render and serve static assets from
Pages, all on the same domain.

### Cloudflare Pages deployment

**`player-app/wrangler.toml`:**
```toml
name = "replay-player"
pages_build_output_dir = "./dist"
```

**Cloudflare Pages project:**
- Connect GitHub repo
- Root directory: `player-app/`
- Build command: `npm run build`
- Output directory: `dist`
- Build watch paths: `player-app/**`

**DNS changes:**
- `play.replaytv.co` → Cloudflare Pages (production)
- `play.replaytv.dev` → Cloudflare Pages (staging)
- Preview deploys on PRs via Cloudflare Pages automatic previews

**Environment variables:**
- `VITE_API_URL` — API base URL (e.g., `https://play.replaytv.co`
  if proxied, or `https://api.replaytv.co` if direct)

### Analytics

The current player fires Ahoy events via `ahoy.track()` which
uses the Ahoy JS library and cookies. The React app should fire
events via the API instead:

- `POST /api/v1/player/events` — new endpoint
- Accepts governed event name + properties
- Server-side creates the Ahoy event with the player's visit
- Bearer auth identifies the player

This avoids Ahoy cookie dependency and keeps event creation
server-authoritative.

Alternatively, the React app can use the Ahoy JS library
directly if same-origin (via Cloudflare proxy).

## Rails-side changes summary

| Change | File | Notes |
|--------|------|-------|
| ActionCable bearer auth | `application_cable/connection.rb` | Token from query params |
| CORS or Cloudflare proxy | `config/initializers/cors.rb` or Cloudflare | API access from Pages origin |
| Heartbeat content version | `heartbeats_controller.rb` | Return `content_version` |
| Touch chain | `playlist_ad.rb`, `screen_content.rb` | Cascade `updated_at` |
| Events API (optional) | New controller | Server-side event creation |

Existing API endpoints, channels, services, and models are
unchanged. The React app consumes the same API the Stimulus
controllers use.

## Execution

### Phase 1 — Scaffold + registration + pairing
```
1. npm create vite@latest player-app -- --template react-ts
   Install Tailwind, @rails/actioncable
   COMMIT

2. usePlayer hook — localStorage identity, registration
   API client with bearer auth
   COMMIT

3. PairingScreen component — code display, QR, countdown
   usePairingChannel hook — subscribe, receive paired event
   COMMIT

4. Test full registration + pairing flow against local Rails API
   COMMIT
```

### Phase 2 — Content rendering
```
5. useManifest hook — fetch and cache manifest data
   COMMIT

6. Slideshow component — playlist ad rotation with timers
   COMMIT

7. Experience component — listing kiosk with touch interactions
   COMMIT

8. IdleScreen + UnpairedScreen components
   App.tsx state machine wiring
   COMMIT
```

### Phase 3 — Real-time + heartbeat
```
9. useScreenChannel hook — content_changed, unpaired events
   Refetch manifest on change, re-render in place
   COMMIT

10. useHeartbeat hook — 30s interval, content_version comparison
    COMMIT

11. Rails: ActionCable bearer auth in Connection
    Rails: heartbeat content_version response
    Rails: touch chain on PlaylistAd → Playlist → ScreenContent
    COMMIT
```

### Phase 4 — Deploy
```
12. Cloudflare Pages project setup
    wrangler.toml, build config, preview deploys
    COMMIT

13. Cloudflare proxy rules — /api/* and /cable to Render
    Or: rack-cors configuration
    COMMIT

14. DNS: play.replaytv.dev → Cloudflare Pages (staging)
    Test full flow on staging
    COMMIT

15. DNS: play.replaytv.co → Cloudflare Pages (production)
    COMMIT
```

### Phase 5 — Offline + polish (future)
```
16. Service Worker — cache app shell, manifest, images
17. IndexedDB — persist manifest for offline playback
18. Analytics — events API or Ahoy JS integration
19. Deprecate HTML player templates
```

## Out of scope

- Native app (iOS/Android/Fire TV) — separate initiative
- Server-side rendering — SPA is appropriate for a device player
- Multi-language support — player has no user-facing text
- Player admin UI — stays in the Rails app

## Risks

- **Device compatibility** — Fire TV Silk, Raspberry Pi Chromium
  must support React 18+ and modern JS. Vite's output targets
  can be configured for older browsers if needed.
- **Cloudflare proxy complexity** — routing `/api/*` through
  Cloudflare to Render adds a layer. Alternative is direct CORS.
- **Two players in parallel** — during migration, both the HTML
  and React players exist. DNS determines which one serves. No
  code conflicts, but two things to maintain temporarily.

## Verification

1. Register a new device — shows pairing code
2. Pair from the app — transitions to content without reload
3. Change content type (playlist → experience) — swaps in place
4. Unplug network — player keeps showing last content (Phase 5)
5. Reconnect — player picks up changes automatically
6. Heartbeat visible in admin — device shows as online
7. Analytics events fire on impressions and scans
