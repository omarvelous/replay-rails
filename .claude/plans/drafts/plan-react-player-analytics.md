# Plan: React Player Analytics (Ahoy.js)

**Created:** 2026-10-02
**Status:** Draft
**Branch:** TBD

## Problem

The React player app has no analytics. Ads rotate without
tracking impressions. Content loads without recording events.
The HTML player tracked all of this via the governed Analytics
wrapper around Ahoy.js — the React player needs the same.

## Current state

### Rails side (unchanged, already working)

- `Ahoy.api = true` — exposes `POST /ahoy/visits` and
  `POST /ahoy/events` endpoints
- `Ahoy.cookie_domain = :all` — cookies shared across subdomains
- Governed event POROs in `app/models/analytics/events/`
- Ahoy JS library pinned in importmap (`pin "ahoy", to: "ahoy.js"`)

### JS side (existing HTML player)

- `app/javascript/analytics/index.js` — `Analytics.create(name, props)`
  wrapper with validation
- `app/javascript/analytics/catalog.js` — governed event schemas
  with required properties
- Events: `content.impressed`, `content.loaded`, `device.connected`,
  `interaction.*` (experience interactions)

### React player (missing)

- No Ahoy.js
- No event tracking
- Slideshow rotates silently
- No `content.impressed` on ad transitions
- No `device.connected` on playback start
- No `content.loaded` on manifest load

## Design

### Install Ahoy.js as npm package

The Rails app uses Ahoy via importmap (`ahoy.js`). The React
app needs the npm package:

```bash
cd player-app && npm install ahoy.js
```

### Analytics module (mirrors the Rails JS wrapper)

Port the governed Analytics wrapper and event catalog to
TypeScript:

```typescript
// player-app/src/analytics/catalog.ts
export const EVENTS = {
  "content.impressed": {
    properties: {
      ad_pid:             { required: true },
      screen_pid:         { required: true },
      screen_content_pid: { required: true },
      playlist_pid:       { required: true },
      account_pid:        { required: true },
      position:           { required: true },
      duration:           { required: true },
    }
  },
  "content.loaded": {
    properties: {
      screen_pid:         { required: true },
      screen_content_pid: { required: true },
      account_pid:        { required: true },
      content_type:       { required: true },
      content_pid:        { required: true },
    }
  },
  "device.connected": {
    properties: {
      screen_pid:    { required: true },
      player_pid:    { required: true },
      account_pid:   { required: true },
    }
  },
} as const
```

```typescript
// player-app/src/analytics/index.ts
import ahoy from "ahoy.js"
import { EVENTS } from "./catalog"

ahoy.configure({
  visitsUrl: "/ahoy/visits",
  eventsUrl: "/ahoy/events",
  cookieDomain: null,  // use default (current domain)
})

export function track(eventName: string, properties: Record<string, unknown>) {
  const schema = EVENTS[eventName as keyof typeof EVENTS]
  if (!schema) {
    console.error(`[Analytics] Unknown event: "${eventName}"`)
    return
  }

  const errors: string[] = []
  for (const [key, config] of Object.entries(schema.properties)) {
    if (config.required && !(key in properties)) {
      errors.push(`${eventName}: "${key}" is required`)
    }
  }

  if (errors.length > 0) {
    console.error("[Analytics]", ...errors)
    return
  }

  ahoy.track(eventName, properties)
}
```

### Ahoy endpoint routing

Ahoy.js posts to `/ahoy/visits` and `/ahoy/events`. The
Cloudflare Pages middleware needs to proxy these to Render:

```typescript
// functions/_middleware.ts
const PROXY_PREFIXES = ["/api/", "/cable", "/rails/active_storage/", "/ahoy/"]
```

One line change.

### Where events fire

**Slideshow — `content.impressed`**

On each ad transition (when the timer advances to the next ad):

```typescript
// In Slideshow component, inside the advance callback:
track("content.impressed", {
  ad_pid: currentAd.pid,
  screen_pid: manifest.screen_content?.pid,  // need screen pid from manifest
  screen_content_pid: manifest.screen_content?.pid,
  playlist_pid: (manifest.contentable as ManifestPlaylist).pid,
  account_pid: ???,  // need account_pid in manifest
  position: currentAd.position,
  duration: currentAd.duration,
})
```

**Problem:** The manifest doesn't include `account_pid` or
`screen_pid` (the screen's pid, separate from screen_content).
These are needed for event properties.

**Fix:** Add `account_pid` and `screen_pid` to the manifest
response. The manifest already has `screen_content.pid` but
that's the ScreenContent record, not the Screen itself.

```ruby
# app/views/api/v1/players/manifests/show.json.jbuilder
json.deploy ENV.fetch("REVISION", "dev")
json.account_pid current_player.screen&.site&.account&.public_id
json.screen_pid current_player.screen&.public_id
# ... rest unchanged
```

**PlayerShell — `content.loaded`**

When manifest loads and transitions to playing:

```typescript
track("content.loaded", {
  screen_pid: manifest.screen_pid,
  screen_content_pid: manifest.screen_content?.pid,
  account_pid: manifest.account_pid,
  content_type: manifest.contentable?.type,
  content_pid: manifest.contentable?.pid,
})
```

**PlayerShell — `device.connected`**

When the player enters the playing state (after pairing or
page load with content):

```typescript
track("device.connected", {
  screen_pid: manifest.screen_pid,
  player_pid: publicId,  // from AuthContext
  account_pid: manifest.account_pid,
})
```

### Manifest changes needed

Add `account_pid` and `screen_pid` to the top-level manifest:

```ruby
# show.json.jbuilder
json.deploy ENV.fetch("REVISION", "dev")
json.account_pid current_player.screen&.site&.account&.public_id
json.screen_pid current_player.screen&.public_id

if @screen_content
  # ... existing code
end
```

Update the `ManifestResponse` TypeScript type:

```typescript
export interface ManifestResponse {
  deploy: string
  account_pid: string | null
  screen_pid: string | null
  screen_content: { pid: string; updated_at: number } | null
  contentable: ManifestPlaylist | ManifestExperience | null
}
```

## Execution

```
1. npm install ahoy.js in player-app
   COMMIT

2. Port analytics catalog + wrapper to TypeScript
   player-app/src/analytics/catalog.ts
   player-app/src/analytics/index.ts
   COMMIT

3. Add /ahoy/ to middleware proxy prefixes
   COMMIT

4. Add account_pid + screen_pid to manifest response
   Update ManifestResponse type
   COMMIT

5. Fire content.impressed in Slideshow on ad transition
   COMMIT

6. Fire content.loaded in PlayerShell on manifest load
   COMMIT

7. Fire device.connected in PlayerShell on playing state
   COMMIT

8. Test: verify events appear in Ahoy::Event table
   COMMIT
```

## Out of scope

- Experience interaction events (`interaction.*`) — add when
  Experience component gets touch interactions
- Page view tracking (`ahoy.trackView()`) — not meaningful
  for a single-page player
- Visit attribution — the player doesn't have user-facing URLs
  with UTM params

## Verification

1. Pair a device, content loads → `device.connected` event in DB
2. Slideshow advances → `content.impressed` event per ad
3. Content changes → new `content.loaded` event
4. Check Ahoy visits table → visit created with correct domain
5. Dashboard analytics still work (same event names/properties)
