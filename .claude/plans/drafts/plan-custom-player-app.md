# Plan: Custom RePlay Player App (Draft)

## Why

We use Fully Kiosk Browser for one thing: a fullscreen WebView that
auto-starts on boot. Everything else — pairing, content delivery,
heartbeat, impressions — is already handled by our own JS and Rails
backend. Fully Kiosk is a $7/device license + $1.30/device/month
middleman for what is essentially a WebView wrapper.

A custom Android app gives us:

1. **Zero per-device cost** — no license, no subscription
2. **Native device access** — telemetry the browser can't provide
3. **Full control** — updates on our schedule, our branding, our UX
4. **Simpler setup** — sideload one APK, done. No Fully Kiosk config
5. **Self-updating** — app checks for updates and installs silently

## What Fully Kiosk does for us today

| Feature | How we use it | Custom app equivalent |
|---------|--------------|----------------------|
| Fullscreen WebView | Loads `play.replaytv.co` | Android WebView, 20 lines of Kotlin |
| Start on boot | `BOOT_COMPLETED` receiver | `BOOT_COMPLETED` BroadcastReceiver |
| Kiosk mode | Locks to single app | Android lock task mode / pinning |
| Restart on crash | Watchdog | Process restart in the app |
| Keep screen on | `FLAG_KEEP_SCREEN_ON` | Same flag, one line |
| Remote admin | HTTP server on device | Not needed — ActionCable handles it |
| Cloud EMM | Dashboard | Not needed — build our own dashboard |

## What a custom app adds (browser can't do this)

| Capability | Android API | Value |
|-----------|------------|-------|
| **HDMI-CEC** | `HdmiControlManager` | Detect TV on/off, turn TV on/off |
| **WiFi signal** | `WifiManager.connectionInfo.rssi` | Signal strength in dBm |
| **Device model** | `Build.MODEL`, `Build.MANUFACTURER` | Auto-identify hardware |
| **Storage** | `StatFs` | Free/total storage |
| **Memory** | `ActivityManager.MemoryInfo` | RAM usage |
| **Battery** | `BatteryManager` | Level, charging state, temperature |
| **CPU temp** | Thermal API (Android 10+) | Overheating detection |
| **Network type** | `ConnectivityManager` | WiFi/Ethernet, speed |
| **Screen state** | `DisplayManager` | Is the display physically on? |
| **App version** | `PackageInfo` | Know which version is deployed |
| **Silent self-update** | Download APK + install | OTA updates without user interaction |
| **Push notifications** | FCM (if Play Services) or WebSocket | Wake device, trigger actions |
| **Background service** | Android Service | Heartbeat runs even if WebView crashes |

## Architecture

```
┌─────────────────────────────────────────────┐
│              RePlay Player App              │
│                                             │
│  ┌───────────────────────────────────────┐  │
│  │            WebView                     │  │
│  │   play.replaytv.co (full signage UI)  │  │
│  │   - Pairing screen                     │  │
│  │   - Slideshow playback                 │  │
│  │   - QR codes, transitions             │  │
│  └───────────────────────────────────────┘  │
│                                             │
│  ┌───────────────┐  ┌──────────────────┐   │
│  │  Heartbeat    │  │  Telemetry       │   │
│  │  Service      │  │  Collector       │   │
│  │  (background) │  │  (native APIs)   │   │
│  └───────┬───────┘  └────────┬─────────┘   │
│          │                   │              │
│          └────────┬──────────┘              │
│                   │                         │
│          POST /heartbeat                    │
│          { telemetry: { ... } }             │
└─────────────────────────────────────────────┘
```

The WebView handles all signage UI (same web app, no changes).
The native layer handles device-level concerns that the browser
can't access.

## What stays in the web app (no change)

- Pairing flow (QR code, countdown, code entry)
- Slideshow playback (transitions, CSS, ad rendering)
- ActionCable subscriptions (playlist changes, unpair events)
- Impression recording
- localStorage for player token

The web app is identical whether loaded in Fully Kiosk, Chrome,
or our custom WebView. The native app is just a smarter container.

## What moves to native

| Current (JS in browser) | Native equivalent | Why move it |
|------------------------|-------------------|-------------|
| Heartbeat fetch every 30s | Background Service | Survives WebView crashes |
| `navigator.connection` | `ConnectivityManager` | More reliable, more detail |
| `performance.memory` | `ActivityManager` | Actual device memory, not JS heap |
| `document.visibilityState` | `DisplayManager` + CEC | Real screen state, not page visibility |
| localStorage token | SharedPreferences | Survives app data clear |

## Minimum viable app (Phase 1)

The simplest version that replaces Fully Kiosk:

```kotlin
class PlayerActivity : Activity() {
    private lateinit var webView: WebView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Fullscreen, keep screen on
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_FULLSCREEN
        )
        
        // WebView with JS enabled
        webView = WebView(this).apply {
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            settings.mediaPlaybackRequiresUserGesture = false
            webViewClient = WebViewClient()
        }
        
        setContentView(webView)
        webView.loadUrl("https://play.replaytv.co")
    }
    
    // Prevent back button from exiting
    override fun onBackPressed() { }
}
```

Plus a boot receiver:

```kotlin
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            context.startActivity(
                Intent(context, PlayerActivity::class.java)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
        }
    }
}
```

That's it — ~50 lines of Kotlin replaces Fully Kiosk for our use case.

## Build order

### Phase 1 — Minimum viable app (replaces Fully Kiosk)

1. Android Studio project setup (Kotlin, min SDK 28 for Fire OS)
2. `PlayerActivity` — fullscreen WebView loading play URL
3. `BootReceiver` — auto-start on device boot
4. Kiosk lock — prevent back/home button escape
5. Keep screen on, disable screen timeout
6. WebView crash recovery — detect and reload
7. Build APK, sideload to Fire TV Stick, verify full flow
8. Setup guide: one `adb install` + disable launcher = done

### Phase 2 — Native telemetry

9. `TelemetryCollector` service — gathers device info:
   - WiFi signal (RSSI), network type, IP
   - Battery level, charging state
   - Storage free/total
   - RAM usage
   - Device model, OS version, app version
   - Screen state (on/off)
10. `HeartbeatService` — background service that:
    - Posts heartbeat every 30s (survives WebView crashes)
    - Includes telemetry payload
    - Continues running even if WebView is reloading
11. JS bridge — expose native telemetry to the WebView:
    ```kotlin
    webView.addJavascriptInterface(TelemetryBridge(), "RePlayNative")
    ```
    ```javascript
    // In the web app
    const telemetry = window.RePlayNative?.getDeviceTelemetry()
    ```
12. Update heartbeat API to accept native telemetry fields

### Phase 3 — HDMI-CEC integration

13. `CecController` — detect TV power state via HDMI-CEC:
    - TV on → play content
    - TV off/standby → pause heartbeat, stop counting impressions
    - Turn TV on/off programmatically (optional)
14. Report `tv_power_state: "on" | "standby" | "unknown"` in telemetry
15. Dashboard: show "TV Off" state distinct from "Player Offline"

### Phase 4 — Self-update mechanism

16. App checks a version endpoint on boot and periodically:
    ```
    GET api.replaytv.co/player-app/version
    → { version: "1.2.0", apk_url: "https://..." }
    ```
17. If newer version available, download APK in background
18. Install silently (requires device owner mode or user prompt)
19. For Fire TV Sticks without device owner: show "Update available"
    overlay, install on next boot via ADB or user confirmation

### Phase 5 — Provisioning

20. First-run wizard (or skip entirely):
    - App generates player token on first launch
    - Stores in SharedPreferences (not localStorage — survives WebView clear)
    - Token passed to WebView via URL param or JS bridge
21. QR code provisioning:
    - Admin generates a provisioning QR code with config:
      `{ play_url: "...", api_url: "...", token: "..." }`
    - New device scans QR at setup → pre-configured
22. Provisioning script for Fire TV:
    ```bash
    adb install RePlayPlayer.apk
    adb shell pm disable-user com.amazon.tv.launcher
    # That's it — app auto-starts on boot
    ```

---

## Tech stack

| Component | Technology |
|-----------|-----------|
| Language | Kotlin |
| Min SDK | 28 (Android 9 — Fire OS 7) |
| WebView | Android WebView (Chromium-based on Fire OS) |
| Build | Gradle + Android Studio |
| CI | GitHub Actions (build APK on release) |
| Distribution | Sideload via ADB, or self-hosted APK download |

## Fire TV Stick considerations

- **No Google Play Services** — can't use FCM for push. Use
  WebSocket (ActionCable) or polling instead.
- **Fire OS is AOSP-based** — standard Android APIs work, but
  some Amazon-specific restrictions apply.
- **WebView version** — Fire OS ships an older Chromium WebView.
  Our CSS (container queries, etc.) has been tested and works.
- **Device Owner mode** — hard to achieve on consumer Fire TV
  Sticks. Silent install won't work without it. Use prompted
  install or ADB-based updates.
- **HDMI-CEC** — Fire TV Sticks support CEC. The `HdmiControlManager`
  API is available but may require system-level permissions.
  Test on actual hardware.

## Build vs Buy comparison

| Factor | Fully Kiosk | Custom app |
|--------|------------|------------|
| **Per-device cost** | $7 + $1.30/mo | $0 |
| **100 devices / year** | $2,260 | $0 |
| **Setup time** | 15 min (Fully config) | 2 min (one APK install) |
| **Native telemetry** | Via MQTT + Cloud EMM | Built-in |
| **Self-update** | No (manual APK update) | Yes (Phase 4) |
| **CEC / TV detection** | No | Yes (Phase 3) |
| **Branding** | Fully Kiosk splash on boot | Your brand |
| **Dev effort (Phase 1)** | Done | ~2-3 days |
| **Dev effort (all phases)** | N/A | ~2-3 weeks |
| **Vendor dependency** | Fully Factory GmbH | None |

**Break-even at ~20 devices / 6 months** — after that, the custom
app is cheaper than Fully Kiosk licenses. Plus you get capabilities
(CEC, self-update, native telemetry) that Fully Kiosk can't provide.

## What's deferred

- **Raspberry Pi version** — Pi doesn't run Android. The Pi player
  would be a different stack (Chromium kiosk + systemd service +
  Python/Go telemetry agent). Separate plan.
- **Amazon Appstore distribution** — submit the app to Amazon's
  store for easier installs. Requires Amazon developer account
  and review process.
- **Remote ADB / remote shell** — advanced ops like OTA OS updates
  or sideloading other apps. Requires Tailscale or similar.
- **Offline content caching** — Service Worker in the WebView or
  native file caching. See smart-reload plan.
