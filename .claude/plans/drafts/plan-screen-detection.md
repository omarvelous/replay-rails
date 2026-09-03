# Plan: Screen/Display Detection (Draft)

## Problem

We can detect when a **player** is off (heartbeat stops, `online?`
returns false after 2 minutes). But we can't detect when a **screen**
(the physical TV/monitor) is off while the player is still running.

Scenarios where this matters:
- TV is turned off by staff at end of day, but player device stays
  powered (plugged into always-on outlet)
- TV goes to sleep/standby but HDMI input stays active
- TV input is switched away from the player's HDMI port
- Screen fails (backlight dies) but player keeps running and
  reporting heartbeats — dashboard says "online" but nothing is
  actually being displayed

In all these cases, the player reports healthy heartbeats and
impressions are counted — but nobody is seeing the content. This
skews analytics and hides display failures.

## Detection approaches

### 1. HDMI-CEC (Consumer Electronics Control)

HDMI-CEC allows devices to communicate over the HDMI cable. The
player can query the TV's power state.

- **Fire TV Stick** — supports CEC. Can detect if TV is on/off.
  Accessible via Android `HdmiControlManager` API but requires
  a native app, not a web browser. Not available from Fully Kiosk.
- **Raspberry Pi** — `cec-client` CLI tool can query TV state:
  ```bash
  echo "pow 0" | cec-client -s -d 1
  # Returns: power status: on / standby / unknown
  ```
  Could run as a background process alongside the browser, reporting
  to the API.
- **Limitation** — CEC is notoriously unreliable across TV brands.
  Some TVs don't support it, some have it disabled by default.

### 2. Ambient light sensor (hardware add-on)

A small light sensor attached to the Pi or placed near the screen
could detect if the display is emitting light.

- **Pro** — works regardless of TV brand, HDMI-CEC support, or
  input switching
- **Con** — requires additional hardware, ambient light can
  cause false positives/negatives
- **Verdict** — too scrappy for v1

### 3. Page Visibility API (browser-based)

The browser's `document.visibilityState` API detects when the page
is hidden (tab switched, app minimized, screen off on some devices).

- **Fire TV Stick** — Silk/Fully Kiosk may fire `visibilitychange`
  when the TV goes to standby, depending on the device
- **Raspberry Pi** — Chromium fires `visibilitychange` when the
  display is powered off via DPMS
- **Limitation** — not all devices fire this event when the physical
  display turns off. HDMI signal may remain "active" even when TV
  is in standby.

**Implementation:**
```javascript
document.addEventListener("visibilitychange", () => {
  // Include in next heartbeat
  this.displayVisible = document.visibilityState === "visible"
})
```

Report `display_visible: true/false` in the heartbeat payload.
Server-side: if a player reports `display_visible: false` for
extended periods, flag the screen as "display off" in the dashboard.

### 4. Heartbeat with display state

Extend the heartbeat to include whatever display info the browser
can provide:

```json
{
  "display_visible": true,
  "screen_width": 1920,
  "screen_height": 1080,
  "color_depth": 24
}
```

If `screen_width` suddenly changes to 0 or `display_visible` goes
false, the display may be off. Store on the Player model and surface
in the admin dashboard.

### 5. Scheduled display hours

Instead of detecting screen state, let the user define when the
screen should be on:

- "This screen runs Monday-Friday, 8am-8pm"
- Outside those hours, player stops sending impressions
- Dashboard shows "Off schedule" instead of "Offline"
- Doesn't detect hardware failures, but solves the "counting
  impressions when the store is closed" problem

This overlaps with the day-parting/scheduling feature (existing
draft plan).

## Recommendation

**Start with option 3 (Page Visibility API) + option 4 (heartbeat
display state).** These are pure software, no hardware needed, and
work across both Fire TV and Raspberry Pi. They won't catch every
case but they catch the common ones:

1. Add `display_visible` to heartbeat payload (JS change)
2. Store on Player model (migration)
3. Surface in dashboard — show "Display off" when player is online
   but `display_visible` is false
4. Stop counting impressions when display is not visible

**Later:** Add scheduled display hours (option 5) as part of the
day-parting feature. Consider CEC for Raspberry Pi deployments
where reliable detection matters.

## What this doesn't solve

- TV input switched to a different HDMI port (player still renders,
  `visibilityState` is still "visible")
- Screen hardware failure with HDMI signal still active
- Storefront window obscured (construction, covered for renovation)

These edge cases require physical verification or camera-based
monitoring — out of scope.
