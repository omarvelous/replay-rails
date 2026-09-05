# Analytics Strategy: Unified Event Tracking Across RePlay

## Current State

Analytics is fragmented across multiple models, each tracking one
thing in isolation:

| Model | What it tracks | How it's recorded |
|-------|---------------|-------------------|
| `Impression` | An ad was shown on a screen | Player JS → API POST |
| `QrScan` | A QR code was scanned | Redirect controller on scan |
| `Lead` | A contact form was submitted | Go controller on submit |
| `MetricSnapshot` | Daily rollup of impressions | Background job |

Each model has its own table, its own API endpoint, its own
controller, and its own display logic. Adding a new metric
(like experience interactions) means building another model,
another endpoint, another set of views.

### Problems with the current approach

1. **No unified event model** — can't answer cross-cutting
   questions like "what happened on this screen today?" without
   querying 3+ tables
2. **No session concept** — impressions are isolated events, no
   way to group "this person saw 4 ads then scanned a QR code"
3. **No visitor/device tracking** — can't distinguish 100 views
   by 100 people from 100 views by 1 person
4. **No funnel analysis** — can't trace impression → scan → lead
   as a connected journey
5. **Experiences have no tracking at all** — the newest content
   type generates zero analytics
6. **Adding new events is expensive** — each requires a model,
   migration, controller, views

---

## What We Want to Track

### Screen & Player Events

| Event | Description | Current tracking |
|-------|-------------|-----------------|
| Screen loaded | Player boots and renders content | Not tracked |
| Ad impression | An ad was displayed for its full duration | `Impression` model |
| Ad skipped | An ad was displayed but not for full duration | Not tracked |
| Content changed | Screen switched playlist/experience | Not tracked |
| Player online | Heartbeat received | `Player.last_heartbeat_at` |
| Player offline | Heartbeat missed | Inferred, not recorded |

### Experience Events (Kiosk)

| Event | Description | Current tracking |
|-------|-------------|-----------------|
| Session start | Someone touched the idle screen | Not tracked |
| Session end | Idle timeout resumed | Not tracked |
| Photo viewed | Swiped to a specific photo | Not tracked |
| Floor plan opened | Tapped floor plan button | Not tracked |
| Details scrolled | Scrolled property details | Not tracked |

### Engagement Events

| Event | Description | Current tracking |
|-------|-------------|-----------------|
| QR scanned | Someone scanned a QR code | `QrScan` model |
| Lead submitted | Contact form filled out | `Lead` model |
| Listing viewed | Go listing page loaded | Not tracked |
| Agent viewed | Go agent page loaded | Not tracked |
| Experience shared | Go experience URL opened | Not tracked |

### Marketing Events (Website)

| Event | Description | Current tracking |
|-------|-------------|-----------------|
| Page viewed | Marketing page loaded | Not tracked |
| Demo requested | Inquiry form submitted | `Inquiry` model |
| Contact submitted | Contact form submitted | `Inquiry` model |
| CTA clicked | Book a demo button clicked | Not tracked |

### App Events (Internal)

| Event | Description | Current tracking |
|-------|-------------|-----------------|
| Listing created | User created a listing | PaperTrail |
| Ad created | User created an ad | PaperTrail |
| Experience created | User created an experience | PaperTrail |
| Screen paired | Player paired to screen | `ScreenPlayer` |
| Invite sent | Team member invited | `Invite` |
| Lead status changed | Lead moved through pipeline | PaperTrail |

---

## Approaches

### Option A: Homegrown Unified Events Table

Build a single `events` table that replaces Impression, QrScan
(partially), and handles all new tracking.

```ruby
class Event < ApplicationRecord
  acts_as_tenant :account

  belongs_to :eventable, polymorphic: true, optional: true
  # eventable = Screen, Experience, Listing, Ad, etc.

  # name: "ad.impression", "experience.session_start",
  #        "qr.scanned", "listing.viewed"
  # properties: { ad_id: 1, duration: 10, photo_index: 3 }
  # session_id: UUID for grouping
end
```

**Columns:** `account_id`, `name` (string), `properties` (jsonb),
`session_id` (string, nullable), `eventable_type`, `eventable_id`,
`visitor_id` (string, nullable — device fingerprint or cookie),
`ip_address`, `user_agent`, `created_at`

**Pros:**
- Full control over schema and queries
- No external dependency
- Data stays in your database
- Simple to add new event types (just a new `name` string)
- Can fold in existing impressions via migration

**Cons:**
- Build everything: ingestion, storage, aggregation, dashboards
- Performance at scale (millions of events)
- No pre-built funnel analysis, cohorts, retention charts
- Session management is DIY
- Visitor identification is DIY

**Effort:** Medium (model + API is easy, dashboards are the work)

### Option B: Ahoy (Rails Gem)

Ahoy is a Ruby gem purpose-built for tracking visits and events
in Rails apps. It provides `Visit` (session) and `Event` models
out of the box.

```ruby
# Gemfile
gem "ahoy_matey"

# Tracking (server-side)
ahoy.track "Ad impression", ad_id: ad.id, screen_id: screen.id

# Tracking (client-side via ahoy.js)
ahoy.track("Photo swiped", { photo_index: 3 })
```

**What Ahoy provides:**
- `Visit` model with visitor token, IP, user agent, referrer,
  UTM params, device type, OS, browser
- `Ahoy::Event` model with `name`, `properties` (jsonb), linked
  to visit
- Automatic visit tracking (first-party cookies)
- Client-side JS library (`ahoy.js`) for browser events
- Geocoding support (optional)
- Works with ActiveRecord (PostgreSQL jsonb)

**What Ahoy does NOT provide:**
- Dashboards or visualization (you build those)
- Funnel analysis
- Real-time event streams

**Player devices are browsers too.** The RePlay player is a
browser in fullscreen — Chrome on Fire Stick, Chromium on
Raspberry Pi, Safari on iPad. It has cookies, localStorage,
and full JS. This means Ahoy works across the entire product:

- **Marketing site** — page views, CTA clicks, UTM tracking
- **App** — feature usage, user behavior
- **Go pages** — listing/agent/experience views
- **Player devices** — impressions, content changes
- **Kiosk interactions** — touch sessions, swipes, engagement

**How the visit/session model maps to kiosk:**

An Ahoy `Visit` represents a browser session. For player devices,
a visit is a long-running session (days/weeks of uptime). Ahoy's
default visit duration is 4 hours — configurable.

For kiosk interaction sessions (someone walks up, touches,
walks away), Ahoy's visit model isn't the right abstraction.
Instead, use Ahoy events with a custom `session_id` property:

```ruby
# Kiosk idle timeout triggers session end
ahoy.track "experience.session_end", {
  session_id: "uuid",
  experience_id: 123,
  duration: 45
}
```

The idle timeout in the experience Stimulus controller already
defines when a session ends (no touch for N seconds). This aligns
naturally with ending an interaction session — when idle resumes,
fire a `session_end` event with the duration. No need to override
Ahoy's visit model.

**Summary of session mapping:**

| Context | What defines a "session" | Ahoy mapping |
|---------|-------------------------|--------------|
| Marketing site | Browser visit | Ahoy Visit (default) |
| App | Logged-in session | Ahoy Visit (default) |
| Go pages | Page view | Ahoy Visit (default) |
| Player device | Device uptime | Ahoy Visit (long-lived) |
| Kiosk interaction | Touch → idle timeout | Custom `session_id` in event properties |

**Pros:**
- Battle-tested gem, widely used
- Works across ALL contexts (web, app, player, kiosk)
- Visit/session management built in for web
- Client + server tracking via ahoy.js
- Integrates with existing Rails models
- Privacy-friendly (first-party, no third-party scripts)
- One tracking system for everything

**Cons:**
- Still need to build dashboards
- Kiosk interaction sessions are custom (events with session_id,
  not Ahoy visits)
- Player devices create long-lived visits that may need custom
  visit duration config

**Effort:** Low-medium for everything — Ahoy handles ingestion
and storage, you build the display

### Option C: PostHog (Hosted Analytics)

PostHog is an open-source product analytics platform. Can be
self-hosted or cloud-hosted. Provides event tracking, funnels,
session recordings, feature flags, and more.

```javascript
// Client-side
posthog.capture('ad_impression', { ad_id: 1, screen_id: 5 })
posthog.capture('photo_swiped', { photo_index: 3 })

// Server-side (Ruby SDK)
PostHog::Client.new.capture(
  distinct_id: "screen_5",
  event: "ad_impression",
  properties: { ad_id: 1 }
)
```

**What PostHog provides:**
- Event ingestion (client + server SDKs)
- Automatic session tracking
- Funnel analysis
- Retention analysis
- User paths
- Dashboards and visualizations
- Session recordings (web only)
- Feature flags
- A/B testing
- SQL access to raw events

**Pricing:**
- Free tier: 1M events/month, 1 project
- Paid: $0.00031 per event after free tier
- Self-hosted: free, but you run the infrastructure

**Challenge for RePlay:** PostHog is designed for product analytics
(user behavior in apps). Using it for screen/kiosk events means
treating each screen as a "user" which is a stretch of the model.
Also, event data lives outside your database — can't join with
your models easily for things like "show me impressions for this
listing's ads."

**Pros:**
- No dashboard work — funnels, retention, paths are built in
- Session tracking, visitor identification handled
- Scales to millions of events
- Feature flags and A/B testing included
- Self-hostable for data control

**Cons:**
- Data lives outside your database (or needs sync)
- Can't easily join events with your Rails models
- Another service to manage (if self-hosted)
- Player/kiosk devices are not typical PostHog "users"
- Monthly cost scales with events
- External dependency for core analytics

**Effort:** Low for integration, zero for dashboards, but high
for custom reporting that joins with your data

### Option D: Ahoy for Everything

Since player devices are browsers, Ahoy can serve as the single
tracking system across the entire product. No hybrid needed.

**One gem handles:**
- Marketing site: page views, CTA clicks, UTM params
- App: feature usage, user journeys
- Go pages: listing views, agent views, experience views
- Player devices: ad impressions, content changes
- Kiosk: interaction sessions (via custom session_id in events)

**Kiosk session alignment with idle timeout:**

The experience Stimulus controller already manages idle state.
When idle timeout fires, it means the interaction session is
over. This is the natural boundary for a kiosk session:

```
Touch breaks idle → ahoy.track("experience.session_start", { session_id })
User swipes → ahoy.track("experience.photo_swipe", { session_id, photo_index })
User opens floor plan → ahoy.track("experience.floor_plan_open", { session_id })
Idle timeout fires → ahoy.track("experience.session_end", { session_id, duration })
```

The idle timeout value (configurable per experience) becomes the
session timeout. No separate session management needed — the
existing touch/idle logic defines sessions.

**Pros:**
- One system for everything
- No hybrid complexity
- Ahoy handles visitor tracking, cookies, user agent parsing
- All events in one table (`ahoy_events`)
- Can query across contexts (web + device)
- Battle-tested, well-maintained

**Cons:**
- Still need to build dashboards
- Long-lived player visits may need visit duration tuning
- Kiosk sessions are a custom concept on top of Ahoy events

---

## Recommendation

**Option D (Ahoy for everything)** is the strongest fit:

- Player devices are browsers — Ahoy's cookie/JS-based tracking
  works across web, app, and player without a hybrid approach
- One `ahoy_events` table replaces the need for a custom events
  model, and existing Impressions can be migrated in
- Kiosk interaction sessions align with the existing idle timeout
  logic — no new session management to build
- Ahoy is a well-maintained Rails gem with server + client SDKs
- All data stays in your database, queryable alongside your models
- Adding new events is just `ahoy.track("event_name", properties)`

**PostHog (Option C)** is worth adding later for dashboards and
funnel analysis once you have real traffic and know what questions
you're asking. It complements Ahoy — Ahoy for ingestion and
storage, PostHog for visualization. Or build dashboards in-app
with Chartkick (already in the stack) querying `ahoy_events`.

**What not to do:** Build a homegrown events table (Option A)
when Ahoy provides the same thing with visit tracking, visitor
identification, and client-side JS built in.

The key insight: don't over-invest in analytics dashboards before
you have users generating data. Get Ahoy tracking events first.
Build views when you know what metrics matter to customers.

---

## Migration Path

If starting with Option A, the migration from current models:

1. Create `events` table
2. Backfill from `impressions` → events with `name: "ad.impression"`
3. Backfill from `qr_scans` → events with `name: "qr.scanned"`
4. Update player JS to post to new events endpoint
5. Update dashboards to query events table
6. Keep Impression/QrScan models as read-only during transition
7. Drop old models after verification

This is a significant refactor — only worth doing when the
current model actively blocks features (like experience tracking).

---

## What to Track First (if building now)

Priority order based on what answers the most valuable questions:

1. **Experience sessions** — "did anyone engage with the kiosk?"
2. **Go page views** — "are QR scans leading to page views?"
3. **Marketing page views** — "is anyone visiting the website?"
4. **App feature usage** — "what features do customers use?"

Everything else can wait until there's customer demand for it.
