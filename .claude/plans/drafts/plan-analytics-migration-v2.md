# Plan: Analytics with Ahoy + Governed Events

## Problem

Analytics is fragmented across isolated models (Impression, QrScan)
with no unified event system, no session tracking, no visitor
identification, and no coverage for Experiences, marketing pages,
or email engagement. Adding new metrics requires a new model,
migration, controller, and views each time.

## Solution

Adopt Ahoy as a unified event tracking system with governed event
definitions enforced by ActiveModel-backed POROs. Events are
first-class objects — created like any other Ruby object with
validations. Add ahoy-email for email engagement and rollup for
time-series aggregation.

### Gems

- **ahoy_matey** — core visit + event tracking (server + client)
- **ahoy-email** — email open/click tracking for mailers
- **rollup** — time-series aggregation for dashboards

---

## Architecture

### Governed Events as Objects

Events are POROs that include `ActiveModel::Model` and
`ActiveModel::Validations`. They're created like any other
object — `Analytics::Events::ContentImpressed.create(...)` —
with validations that enforce the event catalog at the code
level.

```ruby
# Creating a governed event
Analytics::Events::ContentImpressed.create(
  ad_id: ad.id,
  screen_id: screen.id,
  playlist_id: playlist.id,
  position: 1,
  duration: 10,
  request: request
)
```

If validations fail, the event is not emitted and errors are
available on the object — same pattern as ActiveRecord.

### Event Base Class

```ruby
# app/analytics/events/base.rb
module Analytics
  module Events
    class Base
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModel::Validations

      class_attribute :event_name, instance_writer: false
      class_attribute :event_context, instance_writer: false

      # Not persisted as attributes — used for tracking context
      attr_accessor :request, :user, :account

      def create
        return false unless valid?
        emit
        true
      end

      def create!
        raise ActiveModel::ValidationError, self unless valid?
        emit
        true
      end

      def self.create(attributes = {})
        event = new(attributes)
        event.create
        event
      end

      def self.create!(attributes = {})
        event = new(attributes)
        event.create!
        event
      end

      private

      def emit
        tracker = if request
                    controller = request.env["action_controller.instance"]
                    controller&.ahoy || Ahoy::Tracker.new(request: request)
                  else
                    Ahoy::Tracker.new
                  end

        tracker.track(self.class.event_name, properties)
      end

      def properties
        self.class.attribute_names
            .index_with { |attr| send(attr) }
            .compact
            .symbolize_keys
      end
    end
  end
end
```

### Event Definition Example

```ruby
# app/analytics/events/content_impressed.rb
module Analytics
  module Events
    class ContentImpressed < Base
      self.event_name = "content.impressed"
      self.event_context = :player

      attribute :ad_id, :integer
      attribute :screen_id, :integer
      attribute :playlist_id, :integer
      attribute :position, :integer
      attribute :duration, :integer

      validates :ad_id, :screen_id, :playlist_id, :position,
                :duration, presence: true
    end
  end
end
```

Clean, declarative, validates like any Rails model. The event
catalog in `app/analytics/events/` IS the governed list — no
separate documentation to keep in sync.

---

## JS-Side Governed Events

Mirror the Ruby pattern in JavaScript. Events go through typed
factory functions that validate before calling `ahoy.track()`.

```javascript
// app/javascript/analytics/index.js
import ahoy from "ahoy"
import { EVENTS } from "analytics/catalog"

class AnalyticsEvent {
  constructor(name, schema, properties) {
    this.name = name
    this.schema = schema
    this.properties = properties
    this.errors = []
  }

  get valid() {
    this.errors = []
    for (const [key, config] of Object.entries(this.schema)) {
      if (config.required && !(key in this.properties)) {
        this.errors.push(`${this.name}: "${key}" is required`)
      }
    }
    return this.errors.length === 0
  }

  create() {
    if (!this.valid) {
      console.error("[Analytics]", ...this.errors)
      return false
    }
    ahoy.track(this.name, this.properties)
    return true
  }
}

const Analytics = {
  create(eventName, properties = {}) {
    const schema = EVENTS[eventName]
    if (!schema) {
      console.error(`[Analytics] Unknown event: "${eventName}"`)
      return null
    }
    const event = new AnalyticsEvent(eventName, schema.properties, properties)
    event.create()
    return event
  }
}

export default Analytics
```

```javascript
// app/javascript/analytics/catalog.js
export const EVENTS = {
  "content.impressed": {
    context: "player",
    properties: {
      ad_id:       { required: true },
      screen_id:   { required: true },
      playlist_id: { required: true },
      position:    { required: true },
      duration:    { required: true },
    }
  },
  "content.loaded": {
    context: "player",
    properties: {
      screen_id:    { required: true },
      content_type: { required: true },
      content_id:   { required: true },
    }
  },
  "interaction.started": {
    context: "kiosk",
    properties: {
      experience_id: { required: true },
      screen_id:     { required: true },
      session_id:    { required: true },
    }
  },
  "interaction.ended": {
    context: "kiosk",
    properties: {
      experience_id: { required: true },
      screen_id:     { required: true },
      session_id:    { required: true },
      duration:      { required: true },
    }
  },
  "interaction.navigated": {
    context: "kiosk",
    properties: {
      experience_id: { required: true },
      session_id:    { required: true },
      direction:     { required: true },
      photo_index:   { required: true },
    }
  },
  "interaction.opened": {
    context: "kiosk",
    properties: {
      experience_id: { required: true },
      session_id:    { required: true },
      target:        { required: true },
    }
  },
  "interaction.closed": {
    context: "kiosk",
    properties: {
      experience_id: { required: true },
      session_id:    { required: true },
      target:        { required: true },
      view_duration: { required: true },
    }
  },
  "redirect.followed": {
    context: "server",
    properties: {
      source:          { required: true },
      token:           { required: true },
      destination_url: { required: true },
    }
  },
  "form.submitted": {
    context: "server",
    properties: {
      form_type: { required: true },
      source:    { required: true },
    }
  },
  "device.connected": {
    context: "player",
    properties: {
      screen_id:    { required: true },
      player_token: { required: true },
    }
  }
}
```

### Usage in Stimulus Controllers

```javascript
// In device_playback_controller.js
import Analytics from "analytics"

// Instead of: fetch(`${host}/players/${token}/impressions`, ...)
Analytics.create("content.impressed", {
  ad_id: adId,
  screen_id: screenId,
  playlist_id: playlistId,
  position: position,
  duration: duration
})

// In experience_controller.js
Analytics.create("interaction.started", {
  experience_id: this.experienceIdValue,
  screen_id: this.screenIdValue,
  session_id: this.sessionId
})
```

---

## Account Scoping via Ahoy::Store

Ahoy provides the `Ahoy::Store` class for enriching visits and
events with additional data before persistence. This is the
documented pattern for adding custom columns like `account_id`.

```ruby
# app/models/ahoy/store.rb
class Ahoy::Store < Ahoy::DatabaseStore
  def track_visit(data)
    data[:account_id] = account_id_from_context
    super(data)
  end

  def track_event(data)
    data[:account_id] = account_id_from_context
    super(data)
  end

  private

  def account_id_from_context
    # From Current (app controllers)
    Current.account&.id ||
      # From event properties (player/kiosk events may include it)
      data.dig(:properties, :account_id) ||
      # From the visit's user (if authenticated)
      user&.account_users&.first&.account_id
  end
end
```

### Migration columns

Add `account_id` to both tables in the Ahoy generator migration:

```ruby
# ahoy_visits
t.bigint :account_id
t.index :account_id

# ahoy_events
t.bigint :account_id
t.index :account_id
```

This enables direct `where(account_id: ...)` filtering without
joining through properties or visits.

---

## Ahoy Configuration

```ruby
# config/initializers/ahoy.rb
class Ahoy::Store < Ahoy::DatabaseStore
  def track_visit(data)
    data[:account_id] = Current.account&.id
    super(data)
  end

  def track_event(data)
    data[:account_id] = Current.account&.id
    super(data)
  end
end

Ahoy.api = true               # Enable /ahoy/ JS API endpoints
Ahoy.visit_duration = 4.hours
Ahoy.cookie_domain = :all     # Share across subdomains
Ahoy.track_visits_immediately = true
Ahoy.server_side_visits = :when_needed
Ahoy.mask_ips = true
Ahoy.geocode = false
```

---

## Ahoy Email

Track opens and clicks on transactional emails.

```ruby
# config/initializers/ahoy_email.rb
AhoyEmail.api = true
AhoyEmail.default_options[:open] = true
AhoyEmail.default_options[:click] = true
```

```ruby
# Mailers — add to each
class LeadMailer < ApplicationMailer
  has_tracked_emails
end

class InviteMailer < ApplicationMailer
  has_tracked_emails
end

class InquiryMailer < ApplicationMailer
  has_tracked_emails
end
```

**What this tracks:**
- Email opened (pixel tracking)
- Link clicked (redirect tracking)
- Time between sent and opened

---

## Rollup (Time-Series Aggregation)

Replace raw `group_by_day` queries with pre-computed rollups.

```ruby
# app/jobs/analytics_rollup_job.rb
class AnalyticsRollupJob < ApplicationJob
  queue_as :default

  def perform
    Ahoy::Event.where(name: "content.impressed")
      .rollup("Impressions", interval: :day)

    Ahoy::Event.where(name: "interaction.started")
      .rollup("Kiosk Sessions", interval: :day)

    Ahoy::Event.where(name: "redirect.followed")
      .rollup("Redirects", interval: :day)

    Ahoy::Event.where(name: "form.submitted")
      .rollup("Conversions", interval: :day)

    Ahoy::Event.where(name: "page.viewed")
      .rollup("Page Views", interval: :day)
  end
end
```

Dashboard charts query rollups instead of scanning raw events.

---

## Event Definitions (Full Catalog)

### File Structure

```
app/analytics/
├── events/
│   ├── base.rb
│   ├── page_viewed.rb
│   ├── redirect_followed.rb
│   ├── content_impressed.rb
│   ├── content_loaded.rb
│   ├── interaction_started.rb
│   ├── interaction_ended.rb
│   ├── interaction_navigated.rb
│   ├── interaction_opened.rb
│   ├── interaction_closed.rb
│   ├── form_submitted.rb
│   ├── device_connected.rb
│   └── device_disconnected.rb
```

```
app/javascript/analytics/
├── index.js        # Analytics.create() wrapper
├── catalog.js      # Event schemas (mirrors Ruby definitions)
```

12 event definitions. Ruby classes with ActiveModel validations.
JS catalog with required property enforcement.

---

## Where Events Are Emitted

### Server-side (Ruby)

| Event | Where emitted |
|-------|--------------|
| `redirect.followed` | `ScansController#show` |
| `form.submitted` | `Go::LeadsController#create`, `Marketing::InquiriesController#create` |
| `device.disconnected` | Background job detecting missed heartbeats |

### Client-side (JS via ahoy.js)

| Event | Where emitted |
|-------|--------------|
| `page.viewed` | Automatic via ahoy.js on every page load |
| `content.impressed` | `device_playback_controller.js` (replaces POST to impressions API) |
| `content.loaded` | `device_playback_controller.js` on initial render |
| `interaction.started` | `experience_controller.js` when idle breaks |
| `interaction.ended` | `experience_controller.js` when idle resumes |
| `interaction.navigated` | `experience_controller.js` on photo swipe |
| `interaction.opened` | `experience_controller.js` on floor plan open |
| `interaction.closed` | `experience_controller.js` on floor plan close |
| `device.connected` | `device_playback_controller.js` on connect |

---

## Build Order

### Phase 1: Foundation
1. Add gems (ahoy_matey, ahoy-email, rollup) + bundle
2. Run Ahoy install generator
3. Customize migration: add `account_id` to visits + events
4. Run migration
5. Ahoy initializer with Store (account_id enrichment)
6. Create `app/analytics/events/base.rb` with ActiveModel
7. Create all 12 event definition POROs
8. Specs: event validation (create, create!, invalid properties)

### Phase 2: JS Analytics
9. Install ahoy.js via importmap
10. Create `app/javascript/analytics/catalog.js`
11. Create `app/javascript/analytics/index.js` (Analytics.create)
12. Wire ahoy.js into marketing, app, and player layouts

### Phase 3: Instrument Server Events
13. `ScansController` — emit `redirect.followed`
14. `Go::LeadsController` — emit `form.submitted`
15. `Marketing::InquiriesController` — emit `form.submitted`
16. Background job — emit `device.disconnected`

### Phase 4: Instrument JS Events
17. `device_playback_controller.js` — emit `content.impressed`,
    `content.loaded`, `device.connected` via Analytics.create
18. `experience_controller.js` — emit all `interaction.*` events
    via Analytics.create
19. Remove old impressions API endpoint (POST /api/players/:token/impressions)

### Phase 5: Email Tracking
20. Configure ahoy-email initializer
21. Run ahoy-email migration (ahoy_messages table)
22. Add `has_tracked_emails` to LeadMailer, InviteMailer,
    InquiryMailer

### Phase 6: Rollups + Dashboard
23. Configure rollup gem
24. Create AnalyticsRollupJob
25. Schedule job via Solid Queue (daily)
26. Update dashboard controller to query rollups
27. Add experience engagement metrics to dashboard

---

## Open Questions

1. **Ahoy visit duration for players** — 4 hours default means
   ~6 visits per day per device. Acceptable? Or extend to 24h?

2. **Event volume** — 10 screens × 6 ads × 10s loops = ~86K
   impression events/day. Rollups handle dashboard queries.
   Retention policy for raw events?

3. **Testing governed events** — Should specs enforce that no
   code calls `ahoy.track` directly? A grep-based test or
   RuboCop custom cop?

4. **page.viewed auto-tracking** — ahoy.js tracks page views
   automatically. Should we also create a `PageViewed` PORO,
   or let ahoy.js handle it without governance since it has
   no custom properties?

5. **Impressions API removal timeline** — Phase 4 removes the
   old API endpoint. Player devices need to be updated first.
   Coordinate with player deployment.
