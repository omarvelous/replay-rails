# Analysis: Player Hardware Setup

## Your devices

| Device | Count | Cost/unit | Notes |
|--------|:-----:|-----------|-------|
| Amazon Fire TV Stick (various models) | ~3 | $25-50 | Consumer device, 1 of each model |
| Amazon Fire TV Signage Stick | 1 | ~$50-80 | Purpose-built for signage |
| Raspberry Pi | 2 | ~$55-75 | Full control, custom image |

---

## Device comparison

| Factor | Fire TV Stick | Signage Stick | Raspberry Pi |
|--------|:---:|:---:|:---:|
| **Designed for signage** | No | Yes | No (but widely used) |
| **Kiosk lock** | Sideload Fully Kiosk (~$14) | Built-in managed browser | Chromium `--kiosk` (free) |
| **Auto-boot to content** | Via Fully Kiosk | Native | Via systemd/openbox |
| **Power outage recovery** | Lands on home (needs Fully Kiosk) | Auto-recovers to content | Auto-boots by default |
| **Remote management** | Fully Cloud ($2/mo) or ADB | Amazon Business console | SSH + Tailscale (free) |
| **WiFi only** | Yes | Yes | WiFi or Ethernet |
| **Browser engine** | Silk (Chromium-based, lags 1-2 versions) | Silk | Chromium (current) |
| **Container queries** | Likely supported | Likely supported | Fully supported |
| **WebSockets** | Yes | Yes | Yes |
| **24/7 rated** | No (runs warm, works in practice) | Yes | Yes (with proper PSU) |
| **Setup time (scrappy)** | ~15 min (ADB + Fully Kiosk) | ~5 min (managed portal) | ~30 min (first time), then clone image |
| **Setup time (scaled)** | ~5 min (pre-loaded script) | ~2 min (zero-touch) | ~2 min (flash pre-built image) |
| **Ongoing cost/device** | $14 one-time + $2/mo optional | Included in management | Free (Tailscale free tier) |
| **Fleet management** | Fully Cloud or MDM | Amazon Business | Tailscale + balenaCloud ($15/mo 10+) |

---

## Recommendation: Start with Raspberry Pi, test all three

### Why Pi as the primary player

1. **Full control** — you own the OS, the browser, the update mechanism. No dependency on Amazon's managed services or Fully Kiosk's license
2. **Current Chromium** — guaranteed CSS container query support, WebSocket reliability, and DevTools debugging
3. **Ethernet option** — eliminates WiFi provisioning headaches for initial deployments
4. **Custom image** — flash once, clone forever. A Pi image is your deployment artifact
5. **Free remote access** — Tailscale punches through NAT, no per-device fees up to 100 devices
6. **Cost** — Pi 4 4GB (~$55) + SD card (~$10) + case (~$10) + PSU (~$10) = ~$85 total. No ongoing fees

### Why test the others

- **Fire TV Stick** — cheaper ($35-50 all-in), smaller form factor, easier to ship. If Fully Kiosk + your ActionCable connection is reliable, it's a viable low-cost option
- **Signage Stick** — purpose-built, best out-of-box experience, Amazon manages the device. Test to see if Silk's Chromium version handles your CSS. If it works, it's the easiest for customer self-setup

### Test matrix for your current devices

| Test | What to verify |
|------|---------------|
| Container query rendering | Do `cqw` units render correctly on all devices? |
| WebSocket stability | Does the ActionCable connection stay alive for 24+ hours? |
| Crossfade transitions | Are slide transitions smooth at 1080p? |
| Power cycle recovery | Unplug, replug — does content resume without intervention? |
| Heartbeat reliability | Does the 30-second heartbeat survive network blips? |
| QR code legibility | Are inline SVG QR codes sharp enough to scan from 3 feet? |
| Memory over time | Does RAM usage creep after 24-48 hours? (Check for leaks) |

---

## Setup playbook: Raspberry Pi

### Scrappy (now, your 2 Pis)

1. Flash Raspberry Pi OS Lite 64-bit to SD card
2. Enable SSH, set hostname, configure WiFi via `wpa_supplicant.conf` on boot partition
3. Boot, SSH in
4. Install Chromium kiosk stack:
   ```bash
   sudo apt update && sudo apt install --no-install-recommends \
     xserver-xorg x11-xserver-utils xinit openbox chromium-browser unclutter
   ```
5. Configure openbox autostart for kiosk mode (disable screensaver, hide cursor, launch Chromium `--kiosk` pointing to `play.replay.com/players/new`)
6. Enable auto-login via `raspi-config`
7. Install Tailscale for remote access
8. Test the full flow: boot → pairing code → pair in app → content plays
9. Capture the SD card image with `pishrink.sh` for cloning

### Scaled (shipping to locations)

1. **Pre-ship**: Flash the base image, inject customer WiFi to `/boot/wpa_supplicant.conf`, burn a unique activation token to `/boot/replay.conf`
2. **Customer receives device**: Plug Pi into TV via HDMI, plug in power, connect ethernet (or WiFi auto-connects from pre-loaded config)
3. **Pi boots**: Auto-connects to network → calls `api.replay.com/players` with activation token → server auto-pairs to the customer's screen → content starts playing
4. **Fallback**: If WiFi fails, Pi enters AP mode (RaspAP) → customer connects phone to "RePlay-Setup" network → enters WiFi creds via web form → Pi reboots onto customer network

---

## Setup playbook: Fire TV Stick

### Scrappy (now, your 3 sticks)

1. Complete initial Amazon setup (skip sign-in if possible, or use a shared RePlay Amazon account)
2. Enable Developer Options: Settings → My Fire TV → About → tap "Fire TV Stick" 7 times
3. Enable ADB Debugging + Apps from Unknown Sources
4. From your laptop: `adb connect <stick-ip>:5555`
5. Install Fully Kiosk Browser: `adb install FullyKiosk.apk`
6. Open Fully Kiosk, configure:
   - Start URL: `https://play.replay.com/players/new`
   - Enable: Start on Boot, Fullscreen, Kiosk Mode
   - Disable: Address bar, Navigation, System bars
7. Disable Fire TV screensaver: Settings → Display & Sounds → Display Sleep → Never
8. Disable OTA updates (Settings → My Fire TV → About → uncheck auto-updates)
9. Reboot and verify full cycle

### Scaled (future)

- Write a `provision-firetv.sh` script that runs all ADB commands in sequence
- Consider Fully Cloud for fleet management ($2/device/month)
- Or skip Fully Kiosk entirely and use your ActionCable channel for remote management

---

## Setup playbook: Amazon Signage Stick

### Setup (your 1 stick)

1. Create an Amazon Business account at business.amazon.com (free)
2. Register the Signage Stick to your Business org
3. In the Amazon Signage console, set the managed URL to `https://play.replay.com/players/new`
4. Plug the stick into TV, connect to WiFi
5. Stick auto-connects to Amazon's management layer, loads your URL
6. Verify: pairing code appears, pair in RePlay app, content plays

### Evaluation criteria

- Does Silk's Chromium version support container queries?
- Does the managed browser handle ActionCable WebSocket connections?
- Does the management console let you change URLs without physical access?
- What's the reboot recovery time after power loss?

---

## Provisioning flow (all devices)

The provisioning flow is the same regardless of device:

```
Device boots
  → Connects to network (WiFi or ethernet)
    → Opens play.replay.com/players/new
      → JS calls POST api.replay.com/players
        → Gets pairing_code + token
          → Displays 6-char code on screen
            → User enters code in RePlay app
              → ActionCable broadcasts { paired: true }
                → Device redirects to play.replay.com/players/:token
                  → Content plays
```

This flow already exists in your codebase. The device setup is about getting the browser to that first URL reliably.

### Future: Zero-touch (activation token)

Replace the pairing code step:

1. Pre-assign a token to the device before shipping
2. Burn the token into the device config (SD card, Fully Kiosk start URL params, or Signage Stick managed URL)
3. Start URL becomes `play.replay.com/players/:token` directly
4. Server auto-pairs to the customer's pre-assigned screen
5. Content plays immediately on boot — no code entry needed

This requires a small addition to the Rails app: an activation endpoint that accepts a pre-assigned token and auto-creates the ScreenPlayer pairing. But that's a Phase 2 optimization.

---

## Recommended test plan

### Week 1: Baseline setup

1. Set up 1 Raspberry Pi with the kiosk stack — get the full flow working
2. Set up 1 Fire TV Stick with Fully Kiosk — same flow
3. Set up the Signage Stick via Amazon Business — same flow
4. Run all 3 side by side on the same playlist for comparison

### Week 2: Stress test

5. Run all devices 24/7 for a full week
6. Check: memory leaks, WebSocket disconnects, visual rendering, heartbeat gaps
7. Pull power on each device — verify recovery
8. Change the playlist remotely — verify all devices update

### Week 3: Evaluate

9. Compare: setup time, reliability, rendering quality, remote management
10. Pick the primary device for initial deployments
11. Write the setup docs for the chosen device
12. Create the reproducible image or provisioning script

---

## Decision framework

| If you value... | Choose... |
|----------------|-----------|
| Full control + no vendor lock-in | Raspberry Pi |
| Lowest per-unit cost | Fire TV Stick 4K Max |
| Easiest customer self-setup | Amazon Signage Stick |
| Best rendering quality | Raspberry Pi (latest Chromium) |
| Smallest form factor | Fire TV Stick |
| Managed fleet at scale | Signage Stick (Amazon) or Pi (balenaCloud) |

**For RePlay's current stage**: Start with Raspberry Pi as the reference platform (most control, best browser), keep Fire TV Stick as the budget option, and evaluate the Signage Stick for its self-service potential. All three use the same web app — your play subdomain is device-agnostic.
