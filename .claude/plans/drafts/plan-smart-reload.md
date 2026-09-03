# Plan: Smart Player Reload (Draft)

## Problem

When a deploy changes ad templates, CSS, or assets, active players
continue showing stale rendered content until manually refreshed.
With many screens deployed, there's no way to push visual updates
without physically touching each device or triggering a playlist
reassign.

A naive "reload all players on every deploy" works but causes a
visible flash on every deploy — even ones that don't change anything
visual (e.g., a backend-only fix).

## Goal

Players detect when their displayed content is stale and reload
automatically — only when something they're rendering has actually
changed.

## Ideas to explore

### Heartbeat-based version check

The heartbeat fires every 30 seconds. The response could include a
version indicator that the player compares to what it loaded:

```json
// POST /players/:token/heartbeat response
{
  "ok": true,
  "content_version": "abc123"
}
```

The player stores the `content_version` it received at page load.
On each heartbeat, if the version changes, it reloads. The version
could be:

- **Asset fingerprint** — hash of compiled CSS/JS (changes on every
  asset-touching deploy)
- **Deploy SHA** — git commit SHA or deploy timestamp (changes on
  every deploy, not just visual ones)
- **Playlist content hash** — hash of the playlist's ad IDs, order,
  and durations (changes only when the playlist content changes)
- **Template version** — manually bumped version when templates change
  (requires developer discipline)

### ActionCable broadcast on deploy

A Rake task that broadcasts a reload event to all active screen
channels. Could be selective:

- Broadcast to all players (simple)
- Broadcast only to players whose playlist content changed
- Broadcast with a "soft reload" flag — player fetches new HTML
  in the background and swaps it without a visible flash

### Hybrid: heartbeat detects, ActionCable pushes

Use heartbeat as the detection mechanism (poll-based, reliable even
if WebSocket is temporarily disconnected) and ActionCable for
immediate push when available. Belt and suspenders.

## Considerations

- **Flash on reload** — a full page reload causes a visible black
  flash. For signage in a storefront window, this looks broken.
  A seamless update would fetch new slide HTML and swap it without
  interrupting the current slide transition.
- **Staggered rollout** — 100 players all reloading at the same
  instant after a deploy could spike server load. Stagger reloads
  over a window (e.g., each player waits a random 0-60 seconds).
- **Image cache** — even if HTML reloads, images should be cached.
  ActiveStorage URLs with fingerprinted keys handle this.
- **Partial updates vs full reload** — swapping individual slide
  HTML is more complex but avoids the flash. Full reload is simpler
  but visible.
- **Offline players** — players that were offline during the deploy
  should pick up the update on their next heartbeat when they
  reconnect.
