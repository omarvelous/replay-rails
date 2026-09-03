# Plan: Fully Cloud EMM Integration (Draft)

## Problem

As the device fleet grows, we need visibility into device health
beyond what our heartbeat provides. Questions we can't answer today:

- Is the TV physically on or in standby?
- What does the screen actually look like right now?
- Is the device about to run out of storage?
- Why did a device go offline — crash, power loss, or WiFi?
- How do we set up a new device in 2 minutes instead of 15?

Building all of this ourselves is weeks of work. Fully Cloud EMM
provides it out of the box for ~$1.30/device/month.

## Strategy

Two layers, complementary:

| Layer | Tool | Handles |
|-------|------|---------|
| **Signage** | RePlay (ActionCable) | Content delivery, pairing, playlists, impressions, analytics |
| **Ops** | Fully Cloud EMM | Device health, screenshots, provisioning, alerts, hardware telemetry |

Phase 1 uses Fully Cloud standalone (dashboard only). Phase 2
integrates Fully's telemetry into the RePlay dashboard via MQTT.

---

## Phase 1 — Fully Cloud standalone

Use the Fully Cloud dashboard directly for device ops. No code
changes to RePlay.

### Setup per device

1. Create a Fully Cloud account at `cloud.fully-kiosk.com`
2. On each device, in Fully Kiosk settings:
   - **Remote Admin → Enable Remote Admin from Fully Cloud** → ON
   - **Remote Admin → Fully Cloud EMM Token** → paste your cloud token
3. Device appears in the Fully Cloud dashboard within 60 seconds

### Provisioning profile

1. Configure one device fully (URL, kiosk settings, remote admin, cloud)
2. In Fully Cloud → **Configurations** → export settings from that device
3. For new devices: sideload Fully Kiosk, push the saved config → done
4. Cuts setup from 15 minutes to ~2 minutes per device

### Device groups

Organize by account or site:

```
RePlay Fleet
├── Acme Realty - Main Office
│   ├── Front Window
│   └── Lobby Display
├── Acme Realty - Downtown
│   └── Gallery Entrance
└── Beta Properties
    └── Window Display
```

### What you get immediately

- **Dashboard**: All devices with online/offline status, last seen
- **Screenshots on demand**: See exactly what's displaying
- **Alerts**: Email when a device goes offline
- **Remote commands**: Reload URL, restart app, clear cache
- **Bulk operations**: Push URL change to all devices at once

### Cost

- ~$7 one-time PLUS license per device (enables cloud features)
- ~$1.30/device/month for Fully Cloud subscription
- First month free per device

---

## Phase 2 — MQTT integration with RePlay

Connect Fully's MQTT telemetry to the Rails app. Device health
data flows into RePlay's dashboard alongside signage data.

### Architecture

```
Fire TV Stick (Fully Kiosk)
  │
  ├── MQTT → Your MQTT broker → Rails subscriber → Player.telemetry
  │         (Fully device events: screen state, battery, network)
  │
  └── HTTPS → RePlay API → Player heartbeat/impressions
              (Signage events: heartbeat, impressions, pairing)
```

### MQTT broker options

| Option | Pros | Cons |
|--------|------|------|
| **Mosquitto (self-hosted)** | Free, lightweight, Docker | Another service to manage |
| **HiveMQ Cloud (free tier)** | Managed, 100 connections free | Vendor dependency |
| **CloudMQTT** | Managed, simple | Cost at scale |
| **Render background worker** | Runs alongside the app | Custom code |

For a small fleet, HiveMQ Cloud free tier (100 connections) is the
fastest path. Self-host Mosquitto when you outgrow it.

### Fully Kiosk MQTT config

On each device (or via provisioning profile):

- **MQTT Broker URL**: `mqtt://broker.hivemq.com:1883` (or your broker)
- **MQTT Username/Password**: your broker credentials
- **Device Info Topic**: `replaytv/devices/{deviceId}/info`
- **Event Topic**: `replaytv/devices/{deviceId}/events`
- **Publish interval**: 60 seconds (device info)
- **Publish on events**: ON (screen on/off, motion, etc.)

### Rails MQTT subscriber

A background process that subscribes to `replaytv/devices/#` and
updates Player telemetry:

```ruby
# app/services/mqtt_subscriber.rb
class MqttSubscriber
  def start
    client = MQTT::Client.connect(ENV["MQTT_BROKER_URL"])
    client.subscribe("replaytv/devices/+/info")

    client.get do |topic, message|
      device_id = topic.split("/")[2]
      data = JSON.parse(message)

      player = Player.find_by(fully_device_id: device_id)
      next unless player

      player.update!(telemetry: player.telemetry.merge(
        screen_on: data["screenOn"],
        battery_level: data["batteryLevel"],
        is_charging: data["isPlugged"],
        wifi_signal: data["wifiSignalLevel"],
        storage_free_mb: data["internalStorageFreeSpace"],
        fully_version: data["appVersionName"],
        current_url: data["currentPage"]
      ))
    end
  end
end
```

### Data model changes

```ruby
# Migration
add_column :players, :fully_device_id, :string
add_column :players, :telemetry, :jsonb, default: {}
add_index :players, :fully_device_id, unique: true
```

Link Fully device ID to Player record during initial setup or
via a matching step (IP address, or manual entry in admin).

### Unified dashboard

The screen detail page shows both layers:

```
Screen: Front Window
├── Signage Status
│   ├── Player: Online (heartbeat 12s ago)
│   ├── Playlist: Summer Listings (5 ads)
│   └── Impressions today: 342
│
└── Device Health (from Fully Cloud via MQTT)
    ├── Display: ON
    ├── Battery: 100% (plugged in)
    ├── WiFi: -45 dBm (excellent)
    ├── Storage: 2.1 GB free
    ├── Uptime: 4 days 7 hours
    └── Last screenshot: [View]
```

---

## Phase 3 — Fully Cloud API integration

Use the Fully Cloud REST API from Rails for on-demand actions:

### Endpoints to integrate

| Action | API Call | Use case |
|--------|---------|----------|
| Take screenshot | `GET /remote/?cmd=getScreenshot` | "What's on this screen right now?" button in admin |
| Reload page | `POST /remote/?cmd=loadStartUrl` | Force content refresh after deploy |
| Restart app | `POST /remote/?cmd=restartApp` | Recover from stuck state |
| Get device info | `GET /cloud/devices` | Sync fleet status on dashboard load |
| Push URL change | `POST /remote/?cmd=loadUrl` | Override start URL remotely |

### Admin UI additions

- **Screen detail page**: "Take Screenshot" button, "Restart Player" button
- **Fleet dashboard**: bulk "Reload All" after deploy
- **Device health tab**: telemetry from MQTT + Fully Cloud API

### API credentials

Store in Rails credentials:

```yaml
fully_cloud:
  api_email: ops@replaytv.co
  api_key: <fully-cloud-api-key>
```

---

## Phase 4 — Provisioning at scale

### Goal: plug in → auto-configured → paired → playing

1. **Pre-flash**: SD card / USB with Fully Kiosk APK + provisioning profile
2. **First boot**: Fully Kiosk auto-starts with RePlay URL + cloud config
3. **Auto-register**: Device appears in Fully Cloud dashboard
4. **Pairing**: TV shows QR code → staff scans → paired in 30 seconds
5. **Content plays**: Total time from unboxing to live: ~3 minutes

### Provisioning profile contents

- Start URL: `https://play.replaytv.co`
- Kiosk mode: ON (all settings)
- Fully Cloud: enabled with account token
- Remote admin: ON with password
- Screen timeout: never
- All settings from Phase 1 config export

### For Fire TV Sticks

Provisioning profiles can be pushed via ADB script:

```bash
#!/bin/bash
# provision-firetv.sh — run once per new stick
adb connect $1:5555
adb install FullyKiosk.apk
adb push fully-settings.json /sdcard/fully-settings.json
adb shell am start -n de.ozerov.fully/.MainActivity \
  -e loadSettings /sdcard/fully-settings.json
adb shell pm disable-user com.amazon.tv.launcher
adb shell settings put secure screensaver_enabled 0
echo "Done. Reboot the stick."
```

---

## Cost projection

| Fleet size | PLUS license (one-time) | Cloud EMM (monthly) | Total monthly |
|-----------|------------------------|--------------------:|-------------:|
| 10 devices | $70 | $13 | $13 |
| 50 devices | $350 | $65 | $65 |
| 100 devices | $700 | $130 | $130 |
| 500 devices | $3,500 | $650 | $650 |

Compare to building equivalent ops tooling in-house: estimated
4-6 weeks of engineering time ($20-40K equivalent).

---

## What's deferred

- **Android Enterprise / zero-touch**: Requires Google Play Services,
  which Fire TV Sticks don't have natively. Investigate for Raspberry
  Pi or standard Android devices later.
- **MQTT command channel**: Fully only publishes to MQTT, doesn't
  accept commands via MQTT. Commands go through the REST API.
- **Custom Fully Kiosk builds**: Fully offers white-label/OEM builds
  for larger fleets. Evaluate at 100+ devices.
- **Raspberry Pi integration**: Fully Kiosk doesn't run on Pi.
  Pi fleet management would use Tailscale + custom scripts or
  balenaCloud. Separate plan.
