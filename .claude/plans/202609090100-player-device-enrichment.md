# Plan: Player Device Enrichment + Inventory

## Problem

The Player model has minimal device information — just `token`,
`ip_address`, `user_agent`, and `firmware_version`. We can't
identify device types, distinguish provisioned hardware from
browser players, or manage inventory effectively. Office managers
can't name their devices, and support can't filter by device
type or OS version.

## Solution

Enrich the Player model with structured device fields. Populate
via user agent parsing (server-side, all players) + client-reported
info (resolution, touch capability). Show device info in existing
app views and add a full inventory page in admin.

---

## Two Player Categories

### Provisioned Devices
- Fire TV, Raspberry Pi, Android TV, dedicated kiosk hardware
- Run our app or a locked-down browser
- Send `app_version` and `device_type` at registration
- Presence of `app_version` distinguishes from browser players

### Browser Players
- Any browser opening `play.replaytv.co`
- Laptops, iPads, smart TV browsers, phones
- No `app_version` — identified by user agent parsing
- Still useful: resolution, touch capability, browser/OS info

---

## Data Model

### New columns on Player

```ruby
add_column :players, :device_type, :string
# Values: fire_tv, android_tv, raspberry_pi, ios_app,
#         browser_desktop, browser_mobile, browser_tablet,
#         browser_tv, unknown

add_column :players, :device_name, :string
# User-friendly label: "Lobby Fire Stick", "Omar's iPad"
# Set by admin/user, not auto-detected

add_column :players, :device_model, :string
# "Fire TV Stick 4K", "iPad Pro 12.9", "Chromebook"
# Parsed from user agent or reported by app

add_column :players, :device_manufacturer, :string
# "Amazon", "Apple", "Google", "Samsung"

add_column :players, :os_name, :string
# "Fire OS", "iPadOS", "Chrome OS", "Android TV"

add_column :players, :os_version, :string
# "7.6.3.3", "17.0", "120.0"

add_column :players, :app_version, :string
# "1.0.0" for provisioned devices, null for browser players

add_column :players, :browser_name, :string
# "Chrome", "Safari", "Firefox", "Silk"

add_column :players, :browser_version, :string
# "120.0.0"

add_column :players, :screen_width, :integer
# 1920

add_column :players, :screen_height, :integer
# 1080

add_column :players, :touch_capable, :boolean, default: false
```

### Existing columns retained
- `token` — device identity
- `ip_address` — updated on heartbeat
- `user_agent` — raw string, kept for debugging
- `firmware_version` — legacy, keep for now
- `last_heartbeat_at` — online status

---

## User Agent Parsing

Use the `device_detector` gem (or `browser` gem) to parse
user agent into structured fields server-side.

```ruby
# app/models/player.rb
def parse_user_agent!
  return unless user_agent.present?

  client = DeviceDetector.new(user_agent)
  self.device_model = client.device_name
  self.device_manufacturer = client.device_brand
  self.os_name = client.os_name
  self.os_version = client.os_full_version
  self.browser_name = client.name
  self.browser_version = client.full_version
  self.device_type = infer_device_type(client)
end

private

def infer_device_type(client)
  return "fire_tv" if user_agent.include?("AFT") # Amazon Fire TV
  return "android_tv" if user_agent.include?("Android TV")
  return app_version.present? ? "provisioned" : "browser_#{client.device_type || 'unknown'}"
end
```

Called on:
- `POST /api/players` (registration)
- Heartbeat (if user agent changed — OS/browser update)

---

## Client-Reported Info

The player JS collects info not available in user agent and
sends it at registration and on first heartbeat.

### Registration payload (enhanced)

```javascript
// POST /api/players
{
  user_agent: navigator.userAgent,
  screen_width: screen.width,
  screen_height: screen.height,
  touch_capable: navigator.maxTouchPoints > 0,
  app_version: window.REPLAY_APP_VERSION || null
}
```

### Heartbeat payload (enhanced)

```javascript
// POST /api/players/:token/heartbeat
{
  ip_address: null, // server reads from request
  screen_width: screen.width,
  screen_height: screen.height
}
```

Resolution is sent on heartbeat too in case the display
changes (rotation, external monitor).

---

## App UI Enrichment

### Screen show page

Add device info to the existing Player sidebar card:

```
Player
  Status: Online (heartbeat 30s ago)
  Device: Fire TV Stick 4K        ← new
  OS: Fire OS 7.6.3               ← new
  Browser: Silk 120.0             ← new
  Resolution: 1920 × 1080         ← new
  Touch: No                       ← new
  IP: 192.168.1.100
  Paired: 3 days ago
```

### Screen index cards/table

Add device type icon or badge in the card metadata:

```
Window Display · Main Office · Landscape
🔥 Fire TV Stick 4K               ← new
```

Table view: add Device column.

---

## Admin Inventory Page

Full device inventory across all accounts at
`admin.domain/players`.

### List view

| Player | Device | Account | Screen | Status | Last Seen |
|--------|--------|---------|--------|--------|-----------|
| abc123 | Fire TV Stick 4K | Demo Account | Window Display | Online | 30s ago |
| def456 | iPad Pro (Safari) | Demo Account | — | Offline | 2 days ago |
| ghi789 | Chrome / MacOS | Other Account | Lobby | Online | 1m ago |

### Filters
- Device type (fire_tv, browser_desktop, browser_mobile, etc.)
- Online / Offline
- Account
- Has screen / Unassigned

### Detail view

All fields including raw user agent, device name, resolution,
touch capability, app version, registration date.

---

## Gem Options for User Agent Parsing

| Gem | Stars | Maintained | Accuracy |
|-----|-------|-----------|----------|
| `device_detector` | ~700 | Yes | High (port of Matomo) |
| `browser` | ~2.3K | Yes | Good for browser detection |

`device_detector` is better for hardware identification (model,
brand). `browser` is better for browser detection. Could use
both, but `device_detector` covers most needs.

---

## Build Order (TDD)

### Phase 1: Model enrichment
1. RED: Player spec — new attributes, parse_user_agent! method
2. GREEN: Migration + model methods
3. Update player factory

### Phase 2: Server-side parsing
4. Add device_detector gem
5. Parse user agent on registration (PlayersController#create)
6. Parse on heartbeat if user_agent changed

### Phase 3: Client-reported info
7. Update player registration JS to send screen resolution +
   touch capability
8. Update PlayersController to accept new params
9. Update HeartbeatController to accept resolution

### Phase 4: App UI
10. Screen show — device info in Player card
11. Screen index — device type badge/column

### Phase 5: Admin inventory
12. Update Player Administrate dashboard with new fields
13. Device name editing (admin only)
14. Add filters (device_type, online/offline)

---

## Resolved Questions

1. **device_name editing** — Admin only. Customers identify
   devices by Screen, not Player. The Player is an internal/ops
   concept. ✓

2. **Device type** — Enum with fallback. Validate against known
   types, allow `unknown` as catch-all for new device types. ✓

3. **Registration** — Same `POST /api/players` endpoint with
   optional extra fields. Presence of `app_version` distinguishes
   provisioned devices from browser players. ✓

4. **Gem** — `device_detector` for user agent parsing. Better
   hardware identification (brand, model, device type) than
   `browser` gem. Recognizes Fire TV, smart TVs, etc. ✓
