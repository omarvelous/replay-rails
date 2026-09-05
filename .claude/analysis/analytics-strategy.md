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
- API endpoints for non-browser clients (player devices)

**Challenge for RePlay:** Ahoy is designed for web visitors with
cookies. Player devices (kiosk screens) aren't traditional web
visitors — they don't have cookies in the same way, they're
shared devices, and they communicate via API. Ahoy's visit/visitor
model may not map cleanly to "a person walked up to a kiosk."

Could use Ahoy for:
- Marketing site analytics (page views, demo requests)
- App usage tracking (which features are used)
- Go page tracking (listing views, agent views)

And use a custom solution for:
- Player/screen events (impressions, interactions)
- Kiosk session tracking

**Pros:**
- Battle-tested gem, widely used
- Visit/session management built in
- Client + server tracking
- Integrates with existing Rails models
- Privacy-friendly (first-party, no third-party scripts)

**Cons:**
- Doesn't solve player/kiosk tracking well
- Still need to build dashboards
- May need two tracking systems (Ahoy + custom for devices)
- Visit model assumes browser visitors, not shared kiosk screens

**Effort:** Low for web tracking, medium for player tracking
(still custom)

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

### Option D: Hybrid — Ahoy for Web + Custom for Devices

Use Ahoy for browser-based tracking (marketing site, app usage,
go pages) and a homegrown events table for device/player tracking
(impressions, kiosk interactions).

**Web (Ahoy):**
- Marketing page views, CTA clicks
- App feature usage (which pages, how often)
- Go page views (listing/agent/experience views)
- UTM tracking for marketing attribution

**Devices (Custom Events):**
- Ad impressions (replace current Impression model)
- Experience interactions (sessions, swipes, etc.)
- Screen lifecycle events

This keeps the right tool for each context — Ahoy handles the
web visitor model well, custom handles the device model well.

**Pros:**
- Best fit for each context
- Ahoy handles the hard web stuff (sessions, visitors, UTMs)
- Custom handles the unique device stuff
- Data stays in your database
- Can migrate existing Impressions into the custom events table

**Cons:**
- Two systems to maintain
- Two different query patterns
- Dashboard needs to pull from both

---

## Recommendation

For where RePlay is right now (pre-launch, small scale), **Option
A (homegrown) or D (hybrid)** makes the most sense:

- **If you want simplicity:** Option A — one `events` table for
  everything. Fold Impressions in, add kiosk interactions, add
  web tracking later. You control the schema and can build exactly
  what you need.

- **If you want web analytics soon:** Option D — add Ahoy for the
  marketing site and app (takes an hour), build custom events for
  devices. Gets you web analytics immediately without building
  visit/session management.

- **If you want dashboards without building them:** Option C
  (PostHog) is worth revisiting once you have real traffic and
  know what questions you're asking. Adding it later is easy.

The key insight: don't over-invest in analytics infrastructure
before you have users generating data. The current Impression +
QrScan models work. Add kiosk interactions when experiences ship
to customers. Build dashboards when you know what metrics matter.

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
