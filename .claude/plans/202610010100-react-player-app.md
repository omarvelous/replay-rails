# Plan: React Player App

**Created:** 2026-10-01
**Status:** In progress
**Branch:** `feature/react-player-app`

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

### Tech stack

- **React 18+** with TypeScript
- **Vite** for build tooling
- **TanStack Query** (React Query) for data fetching, caching,
  polling, and stale-while-revalidate
- **XState** (or `useReducer`) for the player state machine
- **@rails/actioncable** for WebSocket (same protocol as Solid Cable)
- **Tailwind CSS** to match the Rails app's styling

### Directory structure

```
replay-rails/
├── player-app/
│   ├── src/
│   │   ├── main.tsx
│   │   ├── App.tsx
│   │   ├── api/
│   │   │   └── client.ts           # fetch wrapper, initialized with token
│   │   ├── machines/
│   │   │   └── playerMachine.ts    # XState or useReducer state machine
│   │   ├── queries/
│   │   │   ├── usePlayerQuery.ts   # check paired status
│   │   │   ├── useManifestQuery.ts # fetch + cache manifest (TanStack Query)
│   │   │   └── useHeartbeat.ts     # mutation with interval, content version
│   │   ├── channels/
│   │   │   ├── useConsumer.ts      # ActionCable lifecycle + reconnection
│   │   │   ├── usePairingChannel.ts
│   │   │   └── useScreenChannel.ts
│   │   ├── context/
│   │   │   └── AuthContext.tsx     # token + publicId only
│   │   ├── components/
│   │   │   ├── PlayerShell.tsx     # error boundary + state machine router
│   │   │   ├── PairingScreen.tsx
│   │   │   ├── Slideshow.tsx
│   │   │   ├── Experience.tsx
│   │   │   ├── IdleScreen.tsx
│   │   │   └── ErrorScreen.tsx
│   │   └── types/
│   │       └── index.ts            # Player, Screen, Playlist, Ad, etc.
│   ├── public/
│   ├── index.html
│   ├── package.json
│   ├── tsconfig.json
│   ├── vite.config.ts
│   └── wrangler.toml               # Cloudflare Pages config
├── app/                            # Rails (unchanged)
└── ...
```

### Auth — bearer tokens, no cookies

Two values persisted in localStorage, hydrated into React state:
- `player_public_id` — device identity
- `player_token` — bearer token from registration

`AuthContext` is narrow — token and publicId only. The API client
is a module initialized with the token, not a React context value.
The ActionCable consumer is created once via `useMemo`/`useRef`,
not recreated on state changes.

```typescript
// context/AuthContext.tsx — thin, focused
interface AuthState {
  token: string | null
  publicId: string | null
  register: (data: RegistrationResponse) => void
  clear: () => void
}
```

```typescript
// api/client.ts — plain module, not context
let authToken: string | null = null

export function setToken(token: string | null) {
  authToken = token
}

export async function api<T>(path: string, options: RequestInit = {}): Promise<T> {
  const res = await fetch(path, {
    ...options,
    headers: {
      ...options.headers,
      ...(authToken && { "Authorization": `Bearer ${authToken}` }),
      "Content-Type": "application/json",
    },
  })
  if (!res.ok) throw new ApiError(res.status, await res.text())
  return res.json()
}
```

The API client is initialized once when `AuthContext` hydrates
the token. No context subscription, no re-renders, no
unnecessary consumer teardowns.

### Player state machine

Explicit finite states — impossible states are unrepresentable:

```typescript
type PlayerState =
  | { status: "loading" }
  | { status: "registering" }
  | { status: "pairing"; code: string; expiresAt: Date }
  | { status: "playing"; manifest: Manifest }
  | { status: "idle" }
  | { status: "unpaired" }
  | { status: "error"; error: string; lastGoodState?: PlayerState }

type PlayerEvent =
  | { type: "REGISTERED"; token: string; publicId: string; code: string; expiresAt: Date }
  | { type: "PAIRED" }
  | { type: "MANIFEST_LOADED"; manifest: Manifest }
  | { type: "CONTENT_CHANGED" }
  | { type: "UNPAIRED" }
  | { type: "AUTH_FAILED" }
  | { type: "ERROR"; error: string }
  | { type: "CODE_EXPIRED"; code: string; expiresAt: Date }
```

Transitions:

```
LOADING
  → token in localStorage? check paired status
    → 401         → clear auth → REGISTERING
    → paired:false → PAIRING
    → paired:true  → fetch manifest → PLAYING | IDLE
  → no token      → REGISTERING

REGISTERING
  → POST /api/v1/players → store token → PAIRING

PAIRING
  → PairingChannel receives { paired: true } → fetch manifest → PLAYING | IDLE
  → code expires → refresh code → stay PAIRING

PLAYING
  → content_changed event → refetch manifest → re-render in place
  → unpaired event → UNPAIRED → PAIRING
  → heartbeat version mismatch → refetch manifest

IDLE (no content assigned)
  → content_changed event → refetch manifest → PLAYING

ERROR
  → retains lastGoodState for display (kiosk can't go blank)
  → automatic retry after interval
```

`PlayerShell` reads the state machine and renders the
corresponding component. No conditional chains — each state
maps to exactly one component.

### Error boundaries

A kiosk device can never show a blank screen. Error handling
strategy:

- **React Error Boundary** wraps content components. On crash,
  renders `ErrorScreen` with the last known good content if
  available.
- **API errors** transition to the `error` state which retains
  `lastGoodState`. The Slideshow/Experience keeps rendering
  stale content while the error is surfaced subtly (e.g., small
  icon in the corner).
- **Network loss** — the app continues rendering cached manifest
  data. TanStack Query's `staleTime: Infinity` keeps data in
  memory. Service Worker (Phase 2) persists across restarts.

### Data fetching with TanStack Query

No manual `fetch` + `useState` + `setInterval`. TanStack Query
handles caching, refetch intervals, stale-while-revalidate,
error retry, and background updates:

```typescript
// queries/useManifestQuery.ts
export function useManifestQuery() {
  return useQuery({
    queryKey: ["manifest"],
    queryFn: () => api("/api/v1/player/manifest"),
    staleTime: Infinity,        // never refetch on mount — push or heartbeat triggers it
    refetchOnWindowFocus: false, // kiosk devices don't switch tabs
  })
}
```

```typescript
// queries/useHeartbeat.ts
export function useHeartbeat(currentVersion: number | null) {
  const queryClient = useQueryClient()

  return useQuery({
    queryKey: ["heartbeat"],
    queryFn: () => api("/api/v1/player/heartbeat", { method: "POST" }),
    refetchInterval: 30_000,
    refetchIntervalInBackground: true,
    onSuccess: (data) => {
      if (currentVersion && data.content_version !== currentVersion) {
        queryClient.invalidateQueries({ queryKey: ["manifest"] })
      }
    },
  })
}
```

The heartbeat polls every 30s. When the server's content version
differs from what the app has, it invalidates the manifest query.
TanStack Query refetches automatically. React re-renders. No
manual state management.

### ActionCable connection

Consumer created once with the token, managed via `useRef` to
avoid recreation on re-renders:

```typescript
// channels/useConsumer.ts
import { createConsumer } from "@rails/actioncable"

export function useConsumer(token: string | null) {
  const consumerRef = useRef<ActionCable.Consumer | null>(null)

  useEffect(() => {
    if (!token) return

    const wsUrl = `wss://${location.host}/cable?token=${encodeURIComponent(token)}`
    consumerRef.current = createConsumer(wsUrl)

    return () => {
      consumerRef.current?.disconnect()
      consumerRef.current = null
    }
  }, [token])

  return consumerRef
}
```

**Reconnection strategy:** `@rails/actioncable` auto-reconnects
and resubscribes. On reconnect, the `useScreenChannel` hook
invalidates the manifest query to catch any broadcasts missed
during the gap:

```typescript
// channels/useScreenChannel.ts
connected() {
  // Reconnected — refetch manifest in case we missed a broadcast
  queryClient.invalidateQueries({ queryKey: ["manifest"] })
},
received({ event }) {
  if (event === "content_changed") {
    queryClient.invalidateQueries({ queryKey: ["manifest"] })
  }
  if (event === "unpaired") {
    dispatch({ type: "UNPAIRED" })
  }
}
```

**Rails-side change required:** `ApplicationCable::Connection`
must authenticate players via bearer token in the query string,
not just cookies:

```ruby
# app/channels/application_cable/connection.rb
def find_verified_player
  # Existing cookie path (HTML player)
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

### Image preloading

The Slideshow cycles through ads with images. Without preloading,
the first rotation shows blank frames while images download.

When the manifest loads, preload all image URLs before
transitioning to the `playing` state:

```typescript
async function preloadImages(manifest: Manifest): Promise<void> {
  const urls = manifest.playlist_ads
    .map(pa => pa.ad.image_url)
    .filter(Boolean)

  await Promise.all(
    urls.map(url => new Promise<void>((resolve) => {
      const img = new Image()
      img.onload = img.onerror = () => resolve()
      img.src = url
    }))
  )
}
```

The state machine transitions `LOADING_MANIFEST → PRELOADING →
PLAYING`, so the screen shows nothing until all images are ready.

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

**Touch chain** ensures `updated_at` cascades:
- `PlaylistAd` → touches `Playlist`
- `Playlist` → touches `ScreenContent` (via after_save callback)
- `ScreenContent#updated_at` becomes the authoritative version

### Content rendering

The manifest response contains everything the player needs.
React components render directly from the manifest data:

- **Slideshow** — cycles through `playlist_ads` with timed
  transitions. Fires `content.impressed` analytics events via
  the API.
- **Experience** — renders listing details, agent card, photos.
  Touch interactions for kiosk mode.
- **IdleScreen** — "No content assigned" state.

Content switching (playlist → experience or vice versa) is a
React component swap driven by the state machine — no DOM
teardown, no flicker, no page reload.

### Analytics — server-side via API

Events fire through the API, not client-side Ahoy JS. This
avoids Ahoy cookie dependency and keeps event creation
server-authoritative:

- `POST /api/v1/player/events` — new endpoint
- Accepts governed event name + properties
- Server-side creates the Ahoy event with the player's visit
- Bearer auth identifies the player

```typescript
// In Slideshow, on ad transition:
api.post("/api/v1/player/events", {
  name: "content.impressed",
  properties: {
    ad_pid: ad.public_id,
    screen_pid: screen.public_id,
    screen_content_pid: screenContent.public_id,
    playlist_pid: playlist.public_id,
    position,
    duration,
  }
})
```

### CORS (Rails side)

The React app on Cloudflare Pages and the API on Render share
the same domain (`play.replaytv.co`). Cloudflare routes:

- Static assets (`/`, `/assets/*`) → Cloudflare Pages
- API traffic (`/api/*`, `/cable`) → Render backend

Same origin, no CORS needed. This is configured via Cloudflare
Workers or Page Rules.

If direct CORS is needed as a fallback:

```ruby
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins /https:\/\/.*\.replaytv\.co/
    resource "/api/v1/*", headers: :any, methods: [:get, :post, :patch], credentials: false
    resource "/cable", headers: :any, methods: [:get], credentials: false
  end
end
```

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
- `VITE_API_BASE` — API base URL (same origin if proxied)

## Rails-side changes summary

| Change | File | Notes |
|--------|------|-------|
| ActionCable bearer auth | `application_cable/connection.rb` | Token from query params |
| Cloudflare proxy or CORS | Cloudflare Workers or `cors.rb` | API access from Pages origin |
| Heartbeat content version | `heartbeats_controller.rb` | Return `content_version` |
| Touch chain | `playlist_ad.rb`, `screen_content.rb` | Cascade `updated_at` |
| Events API | New controller | Server-side analytics event creation |

Existing API endpoints, channels, services, and models are
unchanged. The React app consumes the same API the Stimulus
controllers use.

## Execution

### Phase 1 — Scaffold + auth + registration
```
1. npm create vite@latest player-app -- --template react-ts
   Install Tailwind, TanStack Query, @rails/actioncable
   COMMIT

2. AuthContext — token + publicId, localStorage hydration
   API client module — initialized with token, not context
   COMMIT

3. Player state machine (useReducer or XState)
   PlayerShell — routes state to components
   COMMIT

4. Registration flow — usePlayerQuery, PairingScreen
   usePairingChannel hook
   Test against local Rails API
   COMMIT
```

### Phase 2 — Content rendering
```
5. useManifestQuery (TanStack Query) — fetch + cache
   Image preloading before transition to playing
   COMMIT

6. Slideshow component — playlist ad rotation with timers
   Impression tracking via events API
   COMMIT

7. Experience component — listing kiosk with touch interactions
   COMMIT

8. IdleScreen + ErrorScreen components
   React Error Boundary wrapping content
   COMMIT
```

### Phase 3 — Real-time + heartbeat
```
9. useConsumer hook — ActionCable lifecycle with useRef
   useScreenChannel — content_changed invalidates manifest query
   Reconnection: refetch manifest on reconnect
   COMMIT

10. useHeartbeat — TanStack Query mutation, 30s interval
    content_version comparison, invalidates manifest on mismatch
    COMMIT

11. Rails: ActionCable bearer auth in Connection
    Rails: heartbeat content_version response
    Rails: touch chain on PlaylistAd → Playlist → ScreenContent
    Rails: POST /api/v1/player/events endpoint
    COMMIT
```

### Phase 4 — Deploy
```
12. Cloudflare Pages project setup
    wrangler.toml, build config, preview deploys
    COMMIT

13. Cloudflare proxy rules — /api/* and /cable to Render
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
18. Deprecate HTML player templates
```

## Out of scope

- Native app (iOS/Android/Fire TV) — separate initiative
- Server-side rendering — SPA is appropriate for a device player
- Multi-language support — player has no user-facing text
- Player admin UI — stays in the Rails app

## Risks

- **Device compatibility** — Fire TV Silk, Raspberry Pi Chromium
  must support React 18+ and modern JS. Vite's `build.target`
  can be configured for older browsers if needed.
- **Cloudflare proxy complexity** — routing `/api/*` through
  Cloudflare to Render adds a layer. Direct CORS is the fallback.
- **Two players in parallel** — during migration, both HTML and
  React players exist. DNS determines which one serves. No code
  conflicts, but two things to maintain temporarily.
- **TanStack Query + ActionCable coordination** — both can
  trigger manifest refetches. TanStack Query deduplicates
  concurrent requests automatically, so double-triggers are
  harmless.

## Verification

1. Register a new device — shows pairing code
2. Pair from the app — transitions to content without reload
3. Change content type (playlist → experience) — swaps in place
4. Change playlist ads — slideshow updates without flicker
5. Unplug network — player keeps showing last content (Phase 5)
6. Reconnect — player picks up changes automatically
7. Heartbeat visible in admin — device shows as online
8. Analytics events fire on impressions
9. Error in a component — ErrorScreen with last good content
10. Kill the API — player keeps rendering cached manifest
