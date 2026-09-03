# Plan: Device Telemetry (Draft)

## Problem

We know almost nothing about the physical installation. The heartbeat
currently reports only `last_heartbeat_at`, `ip_address`, and
`user_agent`. With devices deployed in storefront windows we can't
see, we need as much context as possible to diagnose issues, optimize
content, and understand the installation environment.

## Goal

Capture everything the browser can tell us about the device and its
display environment. Report it in the heartbeat payload. Store it on
the Player model. Surface it in the admin dashboard.

## What the browser can tell us

### Display / Screen

| Property | API | What it tells us |
|----------|-----|-----------------|
| Screen width | `screen.width` | Physical display resolution (not viewport) |
| Screen height | `screen.height` | Physical display resolution |
| Available width | `screen.availWidth` | Usable area (minus OS chrome) |
| Available height | `screen.availHeight` | Usable area |
| Device pixel ratio | `window.devicePixelRatio` | Retina/HiDPI scaling factor |
| Color depth | `screen.colorDepth` | Bits per pixel (24 = standard, 30 = HDR) |
| Orientation | `screen.orientation.type` | `landscape-primary`, `portrait-primary`, etc. |
| Orientation angle | `screen.orientation.angle` | 0, 90, 180, 270 |
| Page visible | `document.visibilityState` | Is the page actively displayed? |
| Fullscreen | `document.fullscreenElement` | Is the browser in fullscreen mode? |

### Viewport / Content

| Property | API | What it tells us |
|----------|-----|-----------------|
| Viewport width | `window.innerWidth` | Actual rendering width (CSS pixels) |
| Viewport height | `window.innerHeight` | Actual rendering height |
| Scroll position | `window.scrollY` | Should always be 0 for signage |
| Zoom level | `window.outerWidth / window.innerWidth` | Browser zoom factor |

### Network

| Property | API | What it tells us |
|----------|-----|-----------------|
| Connection type | `navigator.connection?.effectiveType` | `4g`, `3g`, `2g`, `slow-2g` |
| Downlink speed | `navigator.connection?.downlink` | Estimated Mbps |
| RTT | `navigator.connection?.rtt` | Round-trip time in ms |
| Save data | `navigator.connection?.saveData` | Data saver mode on? |
| Online status | `navigator.onLine` | Currently connected? |

### Device / Hardware

| Property | API | What it tells us |
|----------|-----|-----------------|
| User agent | `navigator.userAgent` | Browser, OS, device model |
| Platform | `navigator.platform` | OS platform string |
| Hardware concurrency | `navigator.hardwareConcurrency` | Number of CPU cores |
| Device memory | `navigator.deviceMemory` | Approximate RAM in GB |
| Language | `navigator.language` | Device language setting |
| Touch support | `navigator.maxTouchPoints` | 0 = no touch (expected for signage) |

### Performance / Health

| Property | API | What it tells us |
|----------|-----|-----------------|
| JS heap used | `performance.memory?.usedJSHeapSize` | Current memory usage (Chrome only) |
| JS heap total | `performance.memory?.totalJSHeapSize` | Total allocated (Chrome only) |
| JS heap limit | `performance.memory?.jsHeapSizeLimit` | Max available (Chrome only) |
| Page load time | `performance.timing` | How long the page took to load |
| FPS (approx) | `requestAnimationFrame` loop | Are animations smooth? |
| Uptime | `performance.now()` | How long since last page load (ms) |

### Storage

| Property | API | What it tells us |
|----------|-----|-----------------|
| localStorage available | `try { localStorage.setItem(...) }` | Is storage working? |
| Storage estimate | `navigator.storage?.estimate()` | Used/available disk space |

### Media

| Property | API | What it tells us |
|----------|-----|-----------------|
| Video decode support | `MediaCapabilities.decodingInfo()` | Can the device decode H.264/H.265? |
| WebGL support | `document.createElement('canvas').getContext('webgl')` | GPU rendering available? |
| WebGL renderer | `WEBGL_debug_renderer_info` extension | GPU model string |

### ActionCable / WebSocket

| Property | Source | What it tells us |
|----------|--------|-----------------|
| Cable connected | `consumer.connection.isOpen()` | Is the WebSocket alive? |
| Cable disconnects | Count in JS | How often does the connection drop? |
| Last cable message | Timestamp in JS | How stale is the subscription? |

## What we can't get from JS alone

| Info | Why | Alternative |
|------|-----|------------|
| TV make/model | HDMI-CEC only, not browser API | User enters during setup |
| TV power state | CEC or Visibility API (partial) | See screen-detection plan |
| HDMI input active | No browser API | CEC on Raspberry Pi |
| Ambient light level | Requires hardware sensor | Out of scope |
| Physical location | GPS not available on TVs | Associated with Site in the app |
| WiFi signal strength | Not exposed in browser | OS-level on Pi (`iwconfig`) |
| CPU temperature | Not exposed in browser | OS-level on Pi (`vcgencmd`) |

## Implementation

### Phase 1 — Extend heartbeat payload

Collect everything on the JS side and send with each heartbeat:

```javascript
async collectTelemetry() {
  const conn = navigator.connection || {}
  const mem = performance.memory || {}
  const storage = await navigator.storage?.estimate() || {}

  return {
    // Display
    screen_width: screen.width,
    screen_height: screen.height,
    device_pixel_ratio: window.devicePixelRatio,
    color_depth: screen.colorDepth,
    orientation: screen.orientation?.type,
    viewport_width: window.innerWidth,
    viewport_height: window.innerHeight,
    display_visible: document.visibilityState === "visible",
    fullscreen: !!document.fullscreenElement,

    // Network
    connection_type: conn.effectiveType,
    downlink_mbps: conn.downlink,
    rtt_ms: conn.rtt,

    // Device
    hardware_concurrency: navigator.hardwareConcurrency,
    device_memory_gb: navigator.deviceMemory,
    platform: navigator.platform,
    language: navigator.language,

    // Performance
    js_heap_used_mb: mem.usedJSHeapSize ? Math.round(mem.usedJSHeapSize / 1048576) : null,
    js_heap_limit_mb: mem.jsHeapSizeLimit ? Math.round(mem.jsHeapSizeLimit / 1048576) : null,
    uptime_seconds: Math.round(performance.now() / 1000),

    // Storage
    storage_used_mb: storage.usage ? Math.round(storage.usage / 1048576) : null,
    storage_available_mb: storage.quota ? Math.round(storage.quota / 1048576) : null
  }
}
```

### Phase 2 — Store on Player model

Add a `telemetry` jsonb column to Player. Updated on each heartbeat.
No need for separate columns — jsonb keeps it flexible as we add
more fields.

```ruby
# Migration
add_column :players, :telemetry, :jsonb, default: {}

# HeartbeatsController
@player.update!(
  last_heartbeat_at: Time.current,
  ip_address: request.remote_ip,
  user_agent: request.user_agent,
  telemetry: params[:telemetry] || {}
)
```

### Phase 3 — Surface in dashboard

Show telemetry on the screen detail page and admin player view:

- **Display**: 1920×1080 @ 1x, landscape, color depth 24
- **Network**: 4G, 25 Mbps down, 12ms RTT
- **Device**: 4 cores, 2 GB RAM, armv7l
- **Health**: Heap 124/512 MB, uptime 4h 23m
- **Visibility**: Display on / Display off

### Phase 4 — Alerts and analytics

- Alert when `display_visible` is false for extended periods
- Alert when `js_heap_used_mb` approaches `js_heap_limit_mb` (memory leak)
- Alert when `connection_type` degrades to `2g` or `slow-2g`
- Track uptime distribution across fleet
- Detect devices that reboot frequently (low uptime values)

## Considerations

- **Payload size** — all this data is ~500 bytes JSON, sent every
  30 seconds. Negligible bandwidth.
- **Privacy** — no PII in telemetry. IP address is already stored.
- **Browser support** — many of these APIs are Chrome-only
  (`performance.memory`, `navigator.connection`). Fire TV Stick
  (Silk/Chromium-based) and Raspberry Pi (Chromium) both support
  them. Return null for unsupported fields.
- **paper_trail** — add `telemetry` to the Player ignore list.
  Telemetry changes every heartbeat, no audit value.
- **Data retention** — only store the latest telemetry per player
  (overwrite on each heartbeat). Historical telemetry would require
  a separate time-series table — defer to when needed.
