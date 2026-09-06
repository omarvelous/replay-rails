# Plan: Analytics Migration to Ahoy

## Problem

Analytics is fragmented across isolated models (Impression, QrScan,
MetricSnapshot) with no unified event system, no session tracking,
no visitor identification, and no coverage for Experiences, marketing
pages, or email engagement. Adding new metrics requires a new model,
migration, controller, and views each time.

## Solution

Migrate to Ahoy as a unified event tracking system with governed
event definitions enforced by POROs. Add ahoy-email for email
engagement and rollup for time-series aggregation.

### Gems

- **ahoy_matey** — core visit + event tracking (server + client)
- **ahoy-email** — email open/click tracking for mailers
- **rollup** — time-series aggregation replacing MetricSnapshot

---

## Architecture

### Governed Events via POROs

Instead of calling `ahoy.track` directly, all events go through
typed PORO classes that validate properties before emitting. This
enforces the event catalog at the code level — typos, missing
properties, and invalid types are caught at emit time, not in
dashboards weeks later.

```ruby
# Emitting a governed event (server-side)
Analytics.track("content.impressed",
  ad_id: ad.id,
  screen_id: screen.id,
  playlist_id: playlist.id,
  position: 1,
  duration: 10
)

# Under the hood:
module Analytics
  def self.track(event_name, properties = {}, request: nil)
    definition = Registry.fetch(event_name)
    definition.validate!(properties)

    if request
      # Server-side with Ahoy visit context
      controller = request.env["action_controller.instance"]
      controller.ahoy.track(event_name, properties)
    else
      # Background/serverless context (no request)
      Ahoy::Tracker.new.track(event_name, properties)
    end
  end
end
```

### Event Definition POROs

```ruby
# app/analytics/events/content_impressed.rb
module Analytics
  module Events
    class ContentImpressed < Base
      event_name "content.impressed"
      context :player  # player, web, server

      property :ad_id,        type: :integer, required: true
      property :screen_id,    type: :integer, required: true
      property :playlist_id,  type: :integer, required: true
      property :position,     type: :integer, required: true
      property :duration,     type: :integer, required: true
    end
  end
end
```

### Base Class

```ruby
# app/analytics/events/base.rb
module Analytics
  module Events
    class Base
      class << self
        attr_reader :registered_event_name, :registered_context

        def event_name(name)
          @registered_event_name = name
          Registry.register(name, self)
        end

        def context(ctx)
          @registered_context = ctx
        end

        def property(name, type:, required: false)
          properties_schema[name] = { type: type, required: required }
        end

        def properties_schema
          @properties_schema ||= {}
        end
      end

      def initialize(properties)
        @properties = properties
      end

      def validate!
        self.class.properties_schema.each do |name, schema|
          value = @properties[name]

          if schema[:required] && value.nil?
            raise ArgumentError, "#{self.class.registered_event_name}: #{name} is required"
          end

          if value && !valid_type?(value, schema[:type])
            raise ArgumentError, "#{self.class.registered_event_name}: #{name} must be #{schema[:type]}, got #{value.class}"
          end
        end

        unknown = @properties.keys - self.class.properties_schema.keys
        if unknown.any?
          raise ArgumentError, "#{self.class.registered_event_name}: unknown properties: #{unknown.join(', ')}"
        end
      end

      private

      def valid_type?(value, type)
        case type
        when :integer then value.is_a?(Integer)
        when :string  then value.is_a?(String)
        when :boolean then [true, false].include?(value)
        else true
        end
      end
    end
  end
end
```

### Registry

```ruby
# app/analytics/registry.rb
module Analytics
  module Registry
    @events = {}

    def self.register(name, klass)
      @events[name] = klass
    end

    def self.fetch(name)
      @events.fetch(name) do
        raise ArgumentError, "Unknown event: #{name}. Check app/analytics/events/"
      end
    end

    def self.all
      @events
    end
  end
end
```

### JS-Side Governed Events

Create a JS wrapper that mirrors the PORO pattern. Client-side
events go through a governed `analytics.track()` function that
validates event names and required properties before calling
`ahoy.track()`.

```javascript
// app/javascript/analytics/index.js
import ahoy from "ahoy"
import { EVENTS } from "analytics/events"

export function track(eventName, properties = {}) {
  const definition = EVENTS[eventName]
  if (!definition) {
    console.error(`[Analytics] Unknown event: ${eventName}`)
    return
  }

  // Validate required properties
  for (const [key, schema] of Object.entries(definition.properties)) {
    if (schema.required && !(key in properties)) {
      console.error(`[Analytics] ${eventName}: missing required property "${key}"`)
      return
    }
  }

  ahoy.track(eventName, properties)
}
```

```javascript
// app/javascript/analytics/events.js
export const EVENTS = {
  "content.impressed": {
    context: "player",
    properties: {
      ad_id:       { type: "integer", required: true },
      screen_id:   { type: "integer", required: true },
      playlist_id: { type: "integer", required: true },
      position:    { type: "integer", required: true },
      duration:    { type: "integer", required: true },
    }
  },
  "content.loaded": {
    context: "player",
    properties: {
      screen_id:    { type: "integer", required: true },
      content_type: { type: "string",  required: true },
      content_id:   { type: "integer", required: true },
    }
  },
  "interaction.started": {
    context: "kiosk",
    properties: {
      experience_id: { type: "integer", required: true },
      screen_id:     { type: "integer", required: true },
      session_id:    { type: "string",  required: true },
    }
  },
  "interaction.ended": {
    context: "kiosk",
    properties: {
      experience_id: { type: "integer", required: true },
      screen_id:     { type: "integer", required: true },
      session_id:    { type: "string",  required: true },
      duration:      { type: "integer", required: true },
    }
  },
  "interaction.navigated": {
    context: "kiosk",
    properties: {
      experience_id: { type: "integer", required: true },
      session_id:    { type: "string",  required: true },
      direction:     { type: "string",  required: true },
      photo_index:   { type: "integer", required: true },
    }
  },
  "interaction.opened": {
    context: "kiosk",
    properties: {
      experience_id: { type: "integer", required: true },
      session_id:    { type: "string",  required: true },
      target:        { type: "string",  required: true },
    }
  },
  "interaction.closed": {
    context: "kiosk",
    properties: {
      experience_id: { type: "integer", required: true },
      session_id:    { type: "string",  required: true },
      target:        { type: "string",  required: true },
      view_duration: { type: "integer", required: true },
    }
  },
  "device.connected": {
    context: "player",
    properties: {
      screen_id:    { type: "integer", required: true },
      player_token: { type: "string",  required: true },
    }
  }
}
```

---

## Ahoy Configuration

### Initializer

```ruby
# config/initializers/ahoy.rb
class Ahoy::Store < Ahoy::DatabaseStore
end

Ahoy.api = true            # Enable JS API endpoint
Ahoy.visit_duration = 4.hours
Ahoy.cookie_domain = :all  # Share across subdomains
Ahoy.track_visits_immediately = true
Ahoy.server_side_visits = :when_needed

# Mask IP for privacy
Ahoy.mask_ips = true
Ahoy.geocode = false
```

### Visit Model

```ruby
class Ahoy::Visit < ApplicationRecord
  self.table_name = "ahoy_visits"

  has_many :events, class_name: "Ahoy::Event"
  belongs_to :user, optional: true
end
```

### Event Model

```ruby
class Ahoy::Event < ApplicationRecord
  self.table_name = "ahoy_events"

  include Ahoy::QueryMethods

  belongs_to :visit
  belongs_to :user, optional: true
end
```

### Player Device Visits

Player devices are long-lived browsers. Ahoy's default 4-hour
visit duration means a player creates ~6 visits per day. This is
fine — visits represent tracking windows, not user sessions.

Kiosk interaction sessions are tracked via `session_id` in event
properties, independent of Ahoy visits.

---

## Ahoy Email

Track opens and clicks on transactional emails.

```ruby
# Gemfile
gem "ahoy_email"

# config/initializers/ahoy_email.rb
AhoyEmail.api = true
AhoyEmail.default_options[:open] = true
AhoyEmail.default_options[:click] = true
```

```ruby
# app/mailers/lead_mailer.rb
class LeadMailer < ApplicationMailer
  has_tracked_emails

  def new_lead(lead)
    # ahoy-email automatically tracks opens and clicks
    mail(to: lead.agents.map(&:email), subject: "New lead: #{lead.name}")
  end
end
```

**What this tracks:**
- Did the agent open the lead notification email?
- Did they click any links in the email?
- Time between email sent and opened

**Mailers to instrument:**
- `LeadMailer` — lead notifications
- `InviteMailer` — team invites
- `InquiryMailer` — demo/contact requests
- `PasswordsMailer` — password resets (clicks only)

---

## Rollup (Time-Series Aggregation)

Replace manual MetricSnapshot queries with automated rollups.

```ruby
# Gemfile
gem "rollup"
```

```ruby
# config/initializers/rollup.rb
# Define rollups that run daily via Solid Queue
```

```ruby
# app/jobs/analytics_rollup_job.rb
class AnalyticsRollupJob < ApplicationJob
  queue_as :default

  def perform
    # Impressions per day
    Ahoy::Event.where(name: "content.impressed")
      .rollup("Impressions", interval: :day)

    # Kiosk sessions per day
    Ahoy::Event.where(name: "interaction.started")
      .rollup("Kiosk Sessions", interval: :day)

    # Redirects (QR scans) per day
    Ahoy::Event.where(name: "redirect.followed")
      .rollup("Redirects", interval: :day)

    # Form submissions per day
    Ahoy::Event.where(name: "form.submitted")
      .rollup("Conversions", interval: :day)

    # Page views per day
    Ahoy::Event.where(name: "page.viewed")
      .rollup("Page Views", interval: :day)
  end
end
```

Rollups power the dashboard charts (currently using Chartkick
with group_by_day on raw tables). After migration, charts query
the rollups table instead of scanning millions of events.

---

## Event Definitions (Full Catalog)

### app/analytics/events/

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
├── registry.rb
└── tracker.rb
```

12 event definitions matching the event catalog. Each is a few
lines — event name, context, and property schema.

---

## Migration from Existing Models

### Impression → content.impressed

1. Backfill `ahoy_events` from `impressions` table:
   ```sql
   INSERT INTO ahoy_events (name, properties, time, ...)
   SELECT 'content.impressed',
          jsonb_build_object(
            'ad_id', ad_id,
            'screen_id', screen_id,
            'playlist_id', playlist_id
          ),
          created_at, ...
   FROM impressions
   ```
2. Update player JS: `device_playback_controller.js` fires
   `analytics.track("content.impressed", ...)` instead of
   `POST /api/players/:token/impressions`
3. Update dashboard queries to read from `ahoy_events`
4. Keep `impressions` table read-only during transition
5. Drop after verification

### QrScan → redirect.followed

1. Backfill `ahoy_events` from `qr_scans` table
2. Update `ScansController#show` to track via `Analytics.track`
   instead of `qr.scans.create!`
3. Keep `QrScan` model for lead attribution (leads belong_to
   qr_scan) — don't drop immediately
4. New scans go to both `ahoy_events` and `qr_scans` during
   transition

### Lead/Inquiry → form.submitted

Server-side tracking added to existing controllers. No model
migration needed — `Lead` and `Inquiry` keep their own tables.
`form.submitted` events are supplementary analytics, not
replacements.

### New events (no migration)

- `page.viewed` — automatic via ahoy.js
- `interaction.*` — new, no existing data
- `content.loaded` — new
- `device.connected` / `device.disconnected` — new

---

## Dashboard Updates

### Current dashboard queries

```ruby
# Dashboard controller
@impressions_month = Impression.where(account: Current.account)
                       .where("created_at > ?", 30.days.ago).count
@chart_impressions = Impression.where(account: Current.account)
                       .where("created_at > ?", 30.days.ago)
                       .group_by_day(:created_at).count
```

### After migration (using rollups)

```ruby
@impressions_month = Rollup.where(name: "Impressions")
                      .where("time > ?", 30.days.ago).sum(:value)
@chart_impressions = Rollup.where(name: "Impressions")
                      .where("time > ?", 30.days.ago)
                      .order(:time).pluck(:time, :value).to_h
```

### New dashboard sections

- **Experience engagement** — sessions, avg duration, photo depth
- **Funnel** — impressions → scans → page views → leads
- **Email engagement** — open rates for lead notifications
- **Marketing** — page views, demo requests (when ready)

---

## Account Scoping

Ahoy events are not tenant-scoped by default. Options:

**A — Add account_id to ahoy_events:**
Add `account_id` column to `ahoy_events` and set it at track
time. Queries filter by account.

**B — Derive from properties:**
Events contain `screen_id`, `experience_id`, `listing_id` etc.
Account can be derived via joins. More flexible but slower queries.

**Recommendation:** Option A — add `account_id` to `ahoy_events`.
Direct filtering is simpler and faster. Set via the tracker:

```ruby
module Analytics
  def self.track(event_name, properties = {}, account: nil, request: nil)
    # ...
    properties[:account_id] = account&.id || Current.account&.id
    # ...
  end
end
```

---

## Build Order

### Phase 1: Foundation
1. Add gems (ahoy_matey, ahoy-email, rollup)
2. Run Ahoy generators (visits + events tables)
3. Add `account_id` to ahoy_events
4. Ahoy initializer configuration
5. Analytics module: Base, Registry, Tracker
6. All 12 event definition POROs
7. JS analytics wrapper + event definitions
8. Specs: event validation, registry, tracker

### Phase 2: Instrument
9. Wire ahoy.js to marketing layout, app layout, player layout
10. Add `page.viewed` tracking (automatic via ahoy.js)
11. Update `device_playback_controller.js` — emit `content.impressed`
    and `content.loaded` via analytics wrapper
12. Update `experience_controller.js` — emit `interaction.*` events
13. Update `ScansController` — emit `redirect.followed`
14. Update lead/inquiry controllers — emit `form.submitted`
15. Add `device.connected` to player show
16. Add `device.disconnected` to heartbeat timeout detection

### Phase 3: Email Tracking
17. Configure ahoy-email
18. Add `has_tracked_emails` to all mailers
19. Migration for ahoy_messages table

### Phase 4: Rollups + Dashboard
20. Configure rollup definitions
21. Create AnalyticsRollupJob (Solid Queue recurring)
22. Update dashboard controller to use rollups
23. Add experience engagement section to dashboard
24. Update screen show analytics to use events

### Phase 5: Migration + Cleanup
25. Backfill impressions → ahoy_events
26. Backfill qr_scans → ahoy_events
27. Dual-write period (both old + new)
28. Verify dashboard parity
29. Remove old impression API endpoint
30. Drop Impression model (keep table for historical reference)
31. Update QrScan model (keep for lead attribution, stop writing)

---

## Open Questions

1. **Ahoy visit duration for players** — 4 hours is default.
   Player devices run 24/7. Shorter (1 hour) means more visits
   but finer-grained analytics. Longer (24 hours) means fewer
   rows but coarser. 4 hours is probably fine.

2. **Event volume** — A screen showing 6 ads on 10-second loops
   generates ~8,640 impression events per day. 10 screens = 86K
   events/day. At what point do we need to aggregate more
   aggressively? Rollups help, but the raw events table grows.

3. **Retention policy** — Keep raw events forever? Aggregate
   after 90 days and delete raw? PostgreSQL partitioning by
   month?

4. **Testing governed events** — Should the spec suite validate
   that all production `Analytics.track` calls match a governed
   event? A RuboCop custom cop or test that greps for raw
   `ahoy.track` calls?

5. **Ahoy cookie on player devices** — Player devices are shared
   screens. The Ahoy visitor token persists per device, which is
   correct (one device = one visitor). But kiosk sessions are
   many visitors on one device. The `session_id` in event
   properties handles this, not Ahoy's visitor concept.
