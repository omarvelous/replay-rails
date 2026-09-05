# Event Catalog: Governed Event List

## Principles

1. **One event per distinct user/system action.** Don't track the
   same thing twice under different names.
2. **Attribution is a property, not an event.** A page view from
   a QR scan is a page view with `source: "qr"`, not a separate
   "qr_scanned" event.
3. **Events are verb-based.** `page.viewed`, `form.submitted`,
   not `page_view`, `form_submission`.
4. **Properties are consistent.** If multiple events reference a
   listing, they all use `listing_id`, not sometimes `listing`
   and sometimes `property_id`.
5. **Don't track what you can derive.** Session duration = last
   event time - first event time. Don't fire a separate event
   for it unless there's additional data to capture.

---

## Event List

### Page Events

Tracked automatically by Ahoy on every page load. One event type
covers marketing, app, go pages, and experience views.

| Event | When | Properties |
|-------|------|------------|
| `page.viewed` | Any page loads | `url`, `title`, `source` (nullable: `qr`, `share`, `direct`), `referrer` |

**What this replaces:**
- Current QR scan tracking — a scan is `page.viewed` with
  `source: "qr"` and `url: "/go/listings/:id"`
- Go listing page views — currently untracked
- Marketing page views — currently untracked
- Experience public URL views — currently untracked

**Source attribution:**
- `source: "qr"` — visitor came through `/s/:token` redirect
- `source: "share"` — visitor came through a shared link
  (future: UTM params)
- `source: null` — direct visit or unknown

**Note:** The `/s/:token` redirect controller sets the source
before redirecting to the go page. Ahoy picks up the page view
on the destination. No separate scan event needed.

---

### Content Events

Tracked by the player device. These are passive — no user action
initiated them. The screen displayed content to whoever is nearby.

| Event | When | Properties |
|-------|------|------------|
| `content.impressed` | Ad displayed for full duration on a screen | `ad_id`, `screen_id`, `playlist_id`, `position`, `duration` |
| `content.loaded` | Screen rendered new content (playlist or experience) | `screen_id`, `content_type` (`playlist` or `experience`), `content_id` |

**What this replaces:**
- Current `Impression` model — `content.impressed` with the same
  properties

**What we're NOT tracking:**
- Ad skipped (partial impression) — adds complexity, unclear
  value. Defer until there's a use case.

---

### Interaction Events

Tracked by the experience Stimulus controller on kiosk devices.
These are active — a person touched the screen.

| Event | When | Properties |
|-------|------|------------|
| `interaction.started` | Touch breaks idle mode | `experience_id`, `screen_id`, `session_id` |
| `interaction.ended` | Idle timeout fires after inactivity | `experience_id`, `screen_id`, `session_id`, `duration` |
| `interaction.navigated` | Photo swipe or tap to next/prev | `experience_id`, `session_id`, `direction` (`next` or `prev`), `photo_index` |
| `interaction.opened` | Overlay or section opened | `experience_id`, `session_id`, `target` (`floor_plan`) |
| `interaction.closed` | Overlay or section closed | `experience_id`, `session_id`, `target` (`floor_plan`), `view_duration` |

**Session management:**
- `session_id` is a UUID generated client-side when idle breaks
- All events between `interaction.started` and `interaction.ended`
  share the same `session_id`
- `duration` on `interaction.ended` is total session length
- Idle timeout value (from experience config) defines when a
  session ends

**Derived metrics (no dedicated events needed):**
- Sessions count = count of `interaction.started`
- Avg session duration = avg `duration` on `interaction.ended`
- Photos viewed per session = count of `interaction.navigated`
  grouped by `session_id`
- Floor plan view rate = sessions with `interaction.opened`
  (target: floor_plan) / total sessions
- Bounce rate = sessions where `duration` < 5 seconds

**What we're NOT tracking:**
- Every touch event (too noisy)
- Scroll depth on property details (low value for v1)
- Pinch-to-zoom on floor plans (low value for v1)

---

### Conversion Events

Tracked server-side when a form is submitted. These represent a
visitor converting from anonymous to known.

| Event | When | Properties |
|-------|------|------------|
| `form.submitted` | Any public form submitted | `form_type` (`lead`, `inquiry`), `source` (`go_listing`, `go_experience`, `demo`, `contact`), `listing_id` (nullable), `experience_id` (nullable) |

**What this replaces:**
- Lead creation tracking — `form.submitted` with
  `form_type: "lead"`, `source: "go_listing"`
- Inquiry creation tracking — `form.submitted` with
  `form_type: "inquiry"`, `source: "demo"`

**Why one event, not two:**
Both lead and inquiry forms are a visitor submitting contact info.
The `form_type` and `source` properties distinguish them. One
event makes funnel analysis simpler: `page.viewed` → `form.submitted`.

**What we're NOT tracking as events:**
- Lead status changes (internal workflow, tracked by PaperTrail)
- Inquiry responses (internal, tracked by `responded_at`)

---

### Device Events

Tracked by the player device for operational monitoring. These
are system events, not user actions.

| Event | When | Properties |
|-------|------|------------|
| `device.connected` | Player first loads and connects | `screen_id`, `player_token` |
| `device.disconnected` | Player goes offline (detected server-side after missed heartbeats) | `screen_id`, `player_token`, `last_seen_at` |

**What we're NOT tracking as events:**
- Individual heartbeats (too frequent, use `last_heartbeat_at`)
- Pairing/unpairing (already tracked by `ScreenPlayer` model
  with PaperTrail)

---

## Full Event List (Summary)

| # | Event | Context | Trigger |
|---|-------|---------|---------|
| 1 | `page.viewed` | All | Page load (automatic) |
| 2 | `content.impressed` | Player | Ad shown for full duration |
| 3 | `content.loaded` | Player | Screen renders content |
| 4 | `interaction.started` | Kiosk | Touch breaks idle |
| 5 | `interaction.ended` | Kiosk | Idle timeout fires |
| 6 | `interaction.navigated` | Kiosk | Photo swipe/tap |
| 7 | `interaction.opened` | Kiosk | Overlay opened |
| 8 | `interaction.closed` | Kiosk | Overlay closed |
| 9 | `form.submitted` | Web | Form submitted |
| 10 | `device.connected` | Player | Player boots |
| 11 | `device.disconnected` | Server | Heartbeat missed |

11 events total. Covers everything in the analytics strategy
analysis with zero redundancy.

---

## Events We Considered and Removed

| Dropped event | Why | Covered by |
|---------------|-----|------------|
| `qr.scanned` | A scan is just a page view with source attribution | `page.viewed` with `source: "qr"` |
| `listing.viewed` | A listing view is just a page view | `page.viewed` with `url: "/go/listings/:id"` |
| `experience.viewed` | Same | `page.viewed` with `url: "/go/experiences/:id"` |
| `lead.created` | A lead is a form submission | `form.submitted` with `form_type: "lead"` |
| `inquiry.created` | Same | `form.submitted` with `form_type: "inquiry"` |
| `session.started` / `session.ended` | Redundant with interaction events | `interaction.started` / `interaction.ended` |
| `ad.skipped` | Unclear value, adds complexity | Defer |
| `device.heartbeat` | Too frequent for events table | `Player.last_heartbeat_at` |
| `screen.paired` / `screen.unpaired` | Operational, not analytics | `ScreenPlayer` model + PaperTrail |
| `cta.clicked` | A click that leads to a page view | `page.viewed` with referrer |

---

## Standard Properties

Properties that appear across multiple events should use
consistent naming:

| Property | Type | Used by | Description |
|----------|------|---------|-------------|
| `screen_id` | integer | content, interaction, device | Which screen |
| `experience_id` | integer | interaction | Which experience |
| `ad_id` | integer | content | Which ad |
| `playlist_id` | integer | content | Which playlist |
| `listing_id` | integer | form | Which listing (if applicable) |
| `session_id` | string (UUID) | interaction | Groups events in one kiosk session |
| `source` | string | page, form | Attribution: `qr`, `share`, `direct` |
| `form_type` | string | form | `lead` or `inquiry` |
| `duration` | integer (seconds) | content, interaction | How long |
| `target` | string | interaction | What was opened/closed |
| `direction` | string | interaction | `next` or `prev` |
| `photo_index` | integer | interaction | Which photo |
| `content_type` | string | content | `playlist` or `experience` |
| `content_id` | integer | content | ID of playlist or experience |
| `player_token` | string | device | Player identifier |

---

## Funnel Examples

With this event list, these funnels become queryable:

**QR to Lead:**
```
page.viewed (source: "qr", url: "/go/listings/123")
  → form.submitted (form_type: "lead", listing_id: 123)
```

**Kiosk to Lead (via QR handoff):**
```
interaction.started (experience_id: 5)
  → interaction.navigated (photo swipes)
  → interaction.ended (duration: 45s)
  → page.viewed (source: "qr", url: "/go/listings/123")
  → form.submitted (form_type: "lead", listing_id: 123)
```

**Marketing to Demo:**
```
page.viewed (url: "/")
  → page.viewed (url: "/features")
  → page.viewed (url: "/demo")
  → form.submitted (form_type: "inquiry", source: "demo")
```

**Impression to Scan:**
```
content.impressed (ad_id: 10, screen_id: 3)
  → page.viewed (source: "qr", url: "/go/listings/123")
```
