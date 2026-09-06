# Plan: Analytics with Ahoy + Governed Events (v3)

## Problem

Analytics is fragmented across isolated models (Impression, QrScan)
with no unified event system, no session tracking, no visitor
identification, and no coverage for Experiences, marketing pages,
or email engagement.

## Solution

Adopt Ahoy as a unified event tracking system with governed event
definitions enforced by ActiveModel-backed POROs. Events are
first-class objects created with `.create()`. Use ahoy-email for
email engagement and rollup for time-series aggregation with
per-account dimensions.

### Gems

- **ahoy_matey** — core visit + event tracking
- **ahoy-email** — email open/click tracking
- **rollup** — time-series aggregation

---

## Governed Events

### 10 Events

| # | Event | Context | Emitted by |
|---|-------|---------|------------|
| 1 | `redirect.followed` | Server | `ActiveSupport::Notifications` subscriber on `redirect_to.action_controller` |
| 2 | `content.impressed` | Player JS | `device_playback_controller.js` |
| 3 | `content.loaded` | Player JS | `device_playback_controller.js` |
| 4 | `interaction.started` | Kiosk JS | `experience_controller.js` (after `ahoy.reset()`) |
| 5 | `interaction.ended` | Kiosk JS | `experience_controller.js` (idle timeout) |
| 6 | `interaction.navigated` | Kiosk JS | `experience_controller.js` |
| 7 | `interaction.opened` | Kiosk JS | `experience_controller.js` |
| 8 | `interaction.closed` | Kiosk JS | `experience_controller.js` |
| 9 | `device.connected` | Player JS | `device_playback_controller.js` |
| 10 | `device.disconnected` | Server | Background job on heartbeat timeout |

**Plus:** `ahoy.trackView()` for page views — handled by ahoy.js,
no governed PORO needed.

**Removed from earlier versions:**
- `page.viewed` — use `ahoy.trackView()` instead
- `form.submitted` — use `visitable` on Lead/Inquiry instead

### Event Properties

All player and experience events include `screen_content_id` to
correlate events with the exact content assignment at that moment.
Since content can change on a screen, the `screen_content_id`
captures what was active when the event fired.

| Event | Properties |
|-------|------------|
| `redirect.followed` | `source`, `destination_url`, `status` |
| `content.impressed` | `ad_id`, `screen_id`, `screen_content_id`, `playlist_id`, `position`, `duration` |
| `content.loaded` | `screen_id`, `screen_content_id`, `content_type`, `content_id` |
| `interaction.started` | `experience_id`, `screen_id`, `screen_content_id` |
| `interaction.ended` | `experience_id`, `screen_id`, `screen_content_id`, `duration` |
| `interaction.navigated` | `experience_id`, `screen_content_id`, `direction`, `photo_index` |
| `interaction.opened` | `experience_id`, `screen_content_id`, `target` |
| `interaction.closed` | `experience_id`, `screen_content_id`, `target`, `view_duration` |
| `device.connected` | `screen_id`, `player_token` |
| `device.disconnected` | `screen_id`, `player_token`, `last_seen_at` |

---

## Event POROs (Ruby)

Events include `ActiveModel::Model` and `ActiveModel::Validations`.
Created like any other Ruby object.

### Base Class

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

### Example Definition

```ruby
# app/analytics/events/content_impressed.rb
module Analytics
  module Events
    class ContentImpressed < Base
      self.event_name = "content.impressed"
      self.event_context = :player

      attribute :ad_id, :integer
      attribute :screen_id, :integer
      attribute :screen_content_id, :integer
      attribute :playlist_id, :integer
      attribute :position, :integer
      attribute :duration, :integer

      validates :ad_id, :screen_id, :screen_content_id,
                :playlist_id, :position, :duration,
                presence: true
    end
  end
end
```

### File Structure

```
app/analytics/
└── events/
    ├── base.rb
    ├── redirect_followed.rb
    ├── content_impressed.rb
    ├── content_loaded.rb
    ├── interaction_started.rb
    ├── interaction_ended.rb
    ├── interaction_navigated.rb
    ├── interaction_opened.rb
    ├── interaction_closed.rb
    ├── device_connected.rb
    └── device_disconnected.rb
```

---

## Event Wrapper (JS)

Mirror the Ruby pattern. `Analytics.create()` validates before
calling `ahoy.track()`.

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

### JS Catalog

```javascript
// app/javascript/analytics/catalog.js
export const EVENTS = {
  "content.impressed": {
    properties: {
      ad_id:             { required: true },
      screen_id:         { required: true },
      screen_content_id: { required: true },
      playlist_id:       { required: true },
      position:          { required: true },
      duration:          { required: true },
    }
  },
  "content.loaded": {
    properties: {
      screen_id:         { required: true },
      screen_content_id: { required: true },
      content_type:      { required: true },
      content_id:        { required: true },
    }
  },
  "interaction.started": {
    properties: {
      experience_id:     { required: true },
      screen_id:         { required: true },
      screen_content_id: { required: true },
    }
  },
  "interaction.ended": {
    properties: {
      experience_id:     { required: true },
      screen_id:         { required: true },
      screen_content_id: { required: true },
      duration:          { required: true },
    }
  },
  "interaction.navigated": {
    properties: {
      experience_id:     { required: true },
      screen_content_id: { required: true },
      direction:         { required: true },
      photo_index:       { required: true },
    }
  },
  "interaction.opened": {
    properties: {
      experience_id:     { required: true },
      screen_content_id: { required: true },
      target:            { required: true },
    }
  },
  "interaction.closed": {
    properties: {
      experience_id:     { required: true },
      screen_content_id: { required: true },
      target:            { required: true },
      view_duration:     { required: true },
    }
  },
  "device.connected": {
    properties: {
      screen_id:    { required: true },
      player_token: { required: true },
    }
  }
}
```

---

## Kiosk Sessions via Ahoy Visits

Kiosk interaction sessions use Ahoy visits directly — no custom
`session_id`. When idle breaks on a kiosk (someone touches the
screen), `ahoy.reset()` creates a new visit. All events until
idle resumes share that visit. When idle fires, the visit
naturally expires from inactivity.

```javascript
// experience_controller.js
resetIdleTimer() {
  if (this.idle) {
    // Session starts — new Ahoy visit
    ahoy.reset()
    Analytics.create("interaction.started", { ... })
    this.idle = false
  }
  // ...
}

enterIdleMode() {
  Analytics.create("interaction.ended", { ..., duration: elapsed })
  this.idle = true
  // Visit expires naturally from inactivity
}
```

**Derived metrics from visits:**
- Session count = `Ahoy::Visit` count for kiosk screens
- Avg session duration = avg visit duration
- Visits with `interaction.navigated` events = engaged sessions
- Visits with `interaction.opened` (target: floor_plan) = floor
  plan view rate

---

## Visitable Associations

Instead of a `form.submitted` event, associate models directly
with the Ahoy visit that created them. Ahoy auto-sets the
`ahoy_visit_id` on create.

```ruby
class Lead < ApplicationRecord
  visitable :ahoy_visit
end

class Inquiry < ApplicationRecord
  visitable :ahoy_visit
end

class QrScan < ApplicationRecord
  visitable :ahoy_visit
end
```

**Migrations:** Add `ahoy_visit_id` (bigint, nullable) to
`leads`, `inquiries`, and `qr_scans` tables.

**What this enables:**
- `Lead.joins(:ahoy_visit).group(:referring_domain).count`
- "This lead came from a visitor who viewed 3 pages before
  submitting"
- Attribution without duplicate events

---

## Redirect Tracking via Notifications

Subscribe to Rails' built-in `redirect_to.action_controller`
notification. Filter to only track meaningful redirects (not
internal form→show redirects).

```ruby
# config/initializers/analytics_subscribers.rb
ActiveSupport::Notifications.subscribe("redirect_to.action_controller") do |*, payload|
  request = payload[:request]
  location = payload[:location]

  # Only track outbound/public redirects
  if trackable_redirect?(location)
    Analytics::Events::RedirectFollowed.create(
      source: infer_source(request),
      destination_url: location,
      status: payload[:status],
      request: request
    )
  end
end

def trackable_redirect?(url)
  # Track redirects from /s/ (QR scans) and /go/ paths
  url.include?("/go/") || url.include?("/s/")
end

def infer_source(request)
  return "qr" if request.path.start_with?("/s/")
  "internal"
end
```

---

## Account Scoping via Ahoy::Store

Use the documented `Ahoy::Store` pattern to enrich visits and
events with `account_id` before persistence.

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
```

Add `account_id` (bigint, nullable, indexed) to both
`ahoy_visits` and `ahoy_events` tables.

---

## Rollups with Account Dimensions

Rollups must be scoped per account for dashboard queries. Use
the `dimensions` option to store `account_id` on each rollup row.

```ruby
# app/jobs/analytics_rollup_job.rb
class AnalyticsRollupJob < ApplicationJob
  queue_as :default

  def perform
    Account.find_each do |account|
      dimensions = { account_id: account.id }
      scope = Ahoy::Event.where(account_id: account.id)

      scope.where(name: "content.impressed")
        .rollup("Impressions", interval: :day, dimensions: dimensions)

      scope.where(name: "interaction.started")
        .rollup("Kiosk Sessions", interval: :day, dimensions: dimensions)

      scope.where(name: "redirect.followed")
        .rollup("Redirects", interval: :day, dimensions: dimensions)
    end

    # Global rollups (internal metrics, no account filter)
    Ahoy::Event.where(name: "content.impressed")
      .rollup("Impressions (Global)", interval: :day)

    Ahoy::Event.where(name: "page.viewed")
      .rollup("Page Views (Global)", interval: :day)
  end
end
```

### Dashboard queries

```ruby
# Per-account (customer dashboard)
Rollup.where(name: "Impressions", dimensions: { account_id: Current.account.id })
  .where("time > ?", 30.days.ago)
  .order(:time).pluck(:time, :value).to_h

# Global (admin dashboard)
Rollup.where(name: "Impressions (Global)")
  .where("time > ?", 30.days.ago)
  .sum(:value)
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

Add `has_tracked_emails` to:
- `LeadMailer`
- `InviteMailer`
- `InquiryMailer`

---

## Ahoy Configuration

```ruby
# config/initializers/ahoy.rb
Ahoy.api = true
Ahoy.visit_duration = 4.hours
Ahoy.cookie_domain = :all
Ahoy.track_visits_immediately = true
Ahoy.server_side_visits = :when_needed
Ahoy.mask_ips = true
Ahoy.geocode = false
```

---

## Build Order (TDD)

### Phase 1: Ahoy Foundation

**1.1 Gems + migration**
- Add ahoy_matey, ahoy-email, rollup to Gemfile
- `make build` to rebuild Docker image
- Run `rails generate ahoy:install`
- Customize migration: add `account_id` (bigint, indexed) to
  `ahoy_visits` and `ahoy_events`
- Run migration
- Commit: infrastructure

**1.2 Ahoy configuration**
- Create `config/initializers/ahoy.rb` with Store class
  (account_id enrichment), visit duration, cookie domain
- Commit: configuration

**1.3 Analytics::Events::Base (TDD)**
- RED: Spec for Base class — `.create` with valid attrs returns
  true, `.create` with invalid attrs returns false with errors,
  `.create!` with invalid attrs raises ValidationError,
  `#properties` returns attribute hash
- GREEN: `app/analytics/events/base.rb` with ActiveModel
- Commit: RED then GREEN

**1.4 Event definitions (TDD)**
- RED: Spec for each event — validates required properties,
  rejects missing properties, rejects unknown properties
- GREEN: All 10 event definition POROs
- Commit: RED then GREEN

### Phase 2: JS Analytics

**2.1 ahoy.js setup**
- Add ahoy.js to importmap
- Wire into marketing, app, and player layouts
- Enable `ahoy.trackView()` in each layout
- Commit: setup

**2.2 JS analytics wrapper (TDD)**
- RED: JS test — Analytics.create with valid event returns true,
  unknown event logs error, missing required property logs error
- GREEN: `app/javascript/analytics/index.js` and
  `app/javascript/analytics/catalog.js`
- Commit: RED then GREEN

### Phase 3: Visitable Associations

**3.1 Add ahoy_visit_id to models (TDD)**
- RED: Lead spec — `is_expected.to belong_to(:ahoy_visit).optional`
- RED: Inquiry spec — same
- RED: QrScan spec — same
- GREEN: Migrations adding `ahoy_visit_id` to leads, inquiries,
  qr_scans. Add `visitable :ahoy_visit` to each model.
- Commit: RED then GREEN

### Phase 4: Instrument Server Events

**4.1 Redirect tracking (TDD)**
- RED: Spec — scanning a QR code creates a `redirect.followed`
  Ahoy event with source and destination
- GREEN: `ActiveSupport::Notifications` subscriber for
  `redirect_to.action_controller` with filter
- Commit: RED then GREEN

**4.2 Device disconnected (TDD)**
- RED: Spec — missed heartbeat creates `device.disconnected` event
- GREEN: Background job or heartbeat check emits event
- Commit: RED then GREEN

### Phase 5: Instrument JS Events

**5.1 Player events**
- Update `device_playback_controller.js`:
  - `content.impressed` via `Analytics.create` (replaces POST
    to impressions API)
  - `content.loaded` on initial render
  - `device.connected` on connect
- Pass `screen_content_id` as data attribute from player template
- Commit: player instrumentation

**5.2 Experience events**
- Update `experience_controller.js`:
  - `ahoy.reset()` on idle break
  - `interaction.started` on idle break
  - `interaction.ended` on idle timeout
  - `interaction.navigated` on photo swipe
  - `interaction.opened` / `interaction.closed` on floor plan
- Pass `experience_id` and `screen_content_id` as data attributes
- Commit: experience instrumentation

**5.3 Remove old impressions API**
- Remove `POST /api/players/:token/impressions` route
- Remove `Api::Players::ImpressionsController`
- Remove impression recording from `device_playback_controller.js`
- Commit: cleanup

### Phase 6: Email Tracking

**6.1 ahoy-email setup**
- Run ahoy-email generator (creates ahoy_messages table)
- Run migration
- Configure initializer
- Add `has_tracked_emails` to LeadMailer, InviteMailer,
  InquiryMailer
- Commit: email tracking

### Phase 7: Rollups + Dashboard

**7.1 Rollup configuration (TDD)**
- RED: Spec — AnalyticsRollupJob creates rollup entries with
  account_id dimensions
- GREEN: Job with per-account and global rollups
- Commit: RED then GREEN

**7.2 Schedule rollup job**
- Add recurring job to Solid Queue config (daily)
- Commit: scheduling

**7.3 Dashboard migration**
- Update dashboard controller to query rollups instead of
  Impression model
- Update screen show to query Ahoy events for analytics
- Add experience engagement section
- Commit: dashboard updates

---

## Data Retention

Keep raw events forever for now. Revisit when volume warrants:
- Phase 1: Delete raw events older than 90 days, keep rollups
- Phase 2: Move to a more fitting data store with partitioning

---

## Open Questions

1. **`device.disconnected` detection** — currently no background
   job detects missed heartbeats. Need to build one, or defer
   this event?

2. **`screen_content_id` on player templates** — needs to be
   passed as a data attribute. The player controller has access
   to `@screen.active_screen_content&.id`. Wire through the
   template to JS via `data-screen-content-id-value`.
