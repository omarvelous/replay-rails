# Event Catalog

## Source of Truth

The governed event POROs in `app/models/analytics/events/` are
the canonical definition. Each event class declares its name,
required properties, and validations. This document provides
context and usage guidance.

## Governed Events (10)

### 9 ActiveModel POROs

| Event | Class | Context | Emitted by |
|-------|-------|---------|------------|
| `qr.scanned` | `QrScanned` | Server | `ScansController` |
| `content.impressed` | `ContentImpressed` | Player JS | `device_playback_controller.js` |
| `content.loaded` | `ContentLoaded` | Player JS | `device_playback_controller.js` |
| `interaction.started` | `InteractionStarted` | Kiosk JS | `experience_controller.js` |
| `interaction.ended` | `InteractionEnded` | Kiosk JS | `experience_controller.js` |
| `interaction.navigated` | `InteractionNavigated` | Kiosk JS | `experience_controller.js` |
| `interaction.opened` | `InteractionOpened` | Kiosk JS | `experience_controller.js` |
| `interaction.closed` | `InteractionClosed` | Kiosk JS | `experience_controller.js` |
| `device.connected` | `DeviceConnected` | Player JS | `device_playback_controller.js` |

### 1 Ahoy Built-in

| Event | Emitted by |
|-------|------------|
| `$view` (page view) | `ahoy.trackView()` in `application.js` on load + `turbo:load` |

## Event Properties

All player and experience events include `account_id` and
`screen_content_id` to correlate events with the exact content
assignment and account.

| Event | Properties |
|-------|------------|
| `qr.scanned` | `qr_code_id` (required), `destination_url` (required), `screen_content_id`, `ad_id`, `screen_id` |
| `content.impressed` | `ad_id`, `screen_id`, `screen_content_id`, `playlist_id`, `position`, `duration`, `account_id` — all required |
| `content.loaded` | `screen_id`, `screen_content_id`, `content_type`, `content_id` — all required |
| `interaction.started` | `experience_id`, `screen_id`, `screen_content_id` — all required. Also includes `account_id`. |
| `interaction.ended` | Same as started + `duration` (required) |
| `interaction.navigated` | `experience_id`, `screen_content_id`, `direction`, `photo_index` — all required. Also includes `account_id`. |
| `interaction.opened` | `experience_id`, `screen_content_id`, `target` — all required. Also includes `account_id`. |
| `interaction.closed` | Same as opened + `view_duration` (required). Also includes `account_id`. |
| `device.connected` | `screen_id`, `player_token` — all required. Also includes `account_id`. |

## Creating Events

### Ruby (server-side)

```ruby
Analytics::Events::QrScanned.create(
  qr_code_id: qr.id,
  destination_url: destination,
  screen_content_id: params[:sc]&.to_i,
  request: request
)
```

Invalid events return false from `.create` or raise
`ActiveModel::ValidationError` from `.create!`. Errors are
available on the event object.

### JavaScript (client-side)

```javascript
import Analytics from "analytics"

Analytics.create("content.impressed", {
  ad_id: 1,
  screen_id: 2,
  screen_content_id: 3,
  playlist_id: 4,
  position: 1,
  duration: 10,
  account_id: 5
})
```

Unknown events or missing required properties log errors to
the console and are not emitted.

The JS catalog at `app/javascript/analytics/catalog.js` mirrors
the Ruby event definitions.

## Kiosk Sessions

Kiosk interaction sessions use Ahoy visits directly. When idle
breaks (someone touches the screen), `ahoy.reset()` creates a
new visit. All events until idle resumes share that visit. No
custom session_id — Ahoy visits ARE the sessions.

## Account Association

- **App subdomain** — `current_account` resolves account from
  session cookie via `resume_session`. Set on visits and events
  by `Ahoy::Store`.
- **Player subdomain** — No authenticated session. `account_id`
  passed as event property from the template, promoted to the
  column by the Store.
- **Admin subdomain** — Excluded from tracking via
  `Ahoy.exclude_method`.

## Visit Attribution

`Lead`, `Inquiry`, and `QrScan` use `visitable :ahoy_visit`.
Ahoy auto-sets `ahoy_visit_id` on create, linking the record
to the visit that created it. No separate `form.submitted`
event needed.

## Rollups

`AnalyticsRollupJob` runs daily (3am via Solid Queue). Aggregates:
- Impressions per account per day
- Kiosk sessions per account per day
- QR scans per account per day
- Leads per account per day

Dashboard queries rollups for charts instead of scanning raw events.

## Testing

Event POROs are tested via `spec/analytics/events/` — validations,
required properties, create/create! behavior. Ahoy event
persistence is not tested in request specs due to Ahoy's visit
cookie requirements in test. Trust the POROs validate structure,
trust Ahoy persists.

## Adding a New Event

1. Create `app/models/analytics/events/my_event.rb` inheriting
   from `Base` with attributes and validations
2. Add spec to `spec/analytics/events/governed_events_spec.rb`
3. Add to JS catalog at `app/javascript/analytics/catalog.js`
4. Emit from the appropriate controller or Stimulus controller
5. Add rollup to `AnalyticsRollupJob` if needed
