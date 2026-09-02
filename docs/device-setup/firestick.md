# Fire TV Stick Setup Guide

Turn an Amazon Fire TV Stick into a dedicated RePlay signage player.

## Prerequisites

- Fire TV Stick 4K or 4K Max (2GB RAM models — avoid the Lite/HD 1GB models)
- ADB installed locally (`brew install android-platform-tools` on macOS)
- Fire TV Stick plugged into a TV, powered on, connected to WiFi
- Fully Kiosk Browser APK downloaded from [fullyKiosk.com](https://www.fully-kiosk.com/en/#get-fully-kiosk-browser)

## Step 1: Enable Developer Options

1. On the Fire TV, go to **Settings → My Fire TV → About**
2. Scroll to **Fire TV Stick** (the device name row)
3. Click it **7 times** — you'll see "You are now a developer"
4. Press back — **Developer Options** now appears under My Fire TV

## Step 2: Enable ADB and Unknown Sources

1. Go to **Settings → My Fire TV → Developer Options**
2. Turn on **ADB Debugging**
3. Turn on **Apps from Unknown Sources** (or "Install unknown apps" depending on OS version)
4. If prompted about network discovery, select **ON**

## Step 3: Find the Fire TV's IP address

1. Go to **Settings → My Fire TV → About → Network**
2. Note the IP address (e.g., `192.168.1.42`)

## Step 4: Connect via ADB

```bash
adb connect 192.168.1.42:5555
```

If prompted on the TV screen to allow USB debugging, select **Always allow from this computer** and click **OK**.

Verify the connection:

```bash
adb devices
# Should show: 192.168.1.42:5555    device
```

## Step 5: Install Fully Kiosk Browser

```bash
adb install /path/to/FullyKioskBrowser.apk
```

Wait for `Success` output.

## Step 6: Launch Fully Kiosk Browser

```bash
adb shell am start -n de.ozerov.fully/.MainActivity
```

Fully Kiosk Browser opens on the TV.

## Step 7: Configure Fully Kiosk

Using the Fire TV remote, configure these settings in Fully Kiosk:

### Start URL

Set to the play subdomain root — the landing page auto-detects whether the device needs to pair or resume playback:

```
https://play.replaytv.co
```

For staging:

```
https://play.staging.replaytv.co
```

For local development, set up local DNS resolution (see `docs/` local network plan) or use nip.io with your Mac's local IP:

```
http://play.<your-mac-ip>.nip.io:3000
```

### Web Content Settings

- **Autoplay Videos** → ON
- **Enable JavaScript** → ON
- **WebSocket Support** → ON (should be on by default)

### Kiosk Mode

- **Enable Kiosk Mode** → ON
- **Fullscreen Mode** → ON
- **Hide System Bars** → ON
- **Hide Navigation Bar** → ON
- **Disable Status Bar** → ON
- **Disable Home Button** → ON
- **Disable Back Button** → ON
- **Disable Volume Buttons** → OFF (useful for debugging)

### Device Management

- **Start Fully on Boot** → ON
- **Restart on Crash** → ON
- **Restart on Internet Reconnect** → ON
- **Keep Screen On** → ON
- **Screen Brightness** → 255 (max)

### Remote Admin (optional but recommended)

- **Enable Remote Admin** → ON
- **Remote Admin Password** → set a strong password
- Note the remote admin URL shown (e.g., `http://192.168.1.42:2323`)

This gives you a web dashboard to reload the page, change the URL, take screenshots, and restart the device remotely.

## Step 8: Disable Fire TV Screensaver

```bash
adb shell settings put secure screensaver_enabled 0
adb shell settings put system screen_off_timeout 2147483647
```

## Step 9: Disable Fire TV OTA Updates

This prevents Amazon from pushing updates that restart the device or change settings:

```bash
adb shell pm disable-user com.amazon.device.software.ota
adb shell pm disable-user com.amazon.device.software.ota.override
```

To re-enable later if needed:

```bash
adb shell pm enable com.amazon.device.software.ota
```

## Step 10: Set Fully Kiosk as Default Launcher

This makes Fully Kiosk the home screen, preventing the Fire TV home from appearing on boot:

```bash
adb shell pm disable-user com.amazon.tv.launcher
```

To restore the Fire TV launcher:

```bash
adb shell pm enable com.amazon.tv.launcher
```

## Step 11: Reboot and Verify

```bash
adb reboot
```

After reboot, the stick should:

1. Boot directly into Fully Kiosk Browser
2. Load the RePlay landing page
3. If previously paired → resume playback automatically
4. If not paired → display a 6-character pairing code and a QR code

## Step 12: Pair in RePlay

**Option A — Scan the QR code (recommended):**

1. Scan the QR code on the TV with your phone
2. Log into RePlay if prompted
3. Select the screen to pair with
4. Tap **Pair Device** — content starts playing within seconds

**Option B — Enter the code manually:**

1. Log into RePlay at `app.replaytv.co`
2. Go to **Screens → your screen → Pair a player**
3. Enter the 6-character code from the TV
4. Content starts playing within seconds

## Verification checklist

After setup, verify:

- [ ] Stick boots directly to Fully Kiosk (no Fire TV home screen)
- [ ] Pairing page loads with a 6-character code and QR code
- [ ] QR code scans and opens the pairing page in the app
- [ ] Pairing completes and content plays
- [ ] Slide transitions are smooth (no jank on crossfades)
- [ ] QR codes on ads are sharp and scannable
- [ ] Playlist changes push in real-time (change playlist in app, TV updates)
- [ ] Unpair from app → device redirects to pairing screen automatically
- [ ] Re-pair → same player record reused (check code on screen matches previous device)
- [ ] Power cycle: unplug, wait 10 seconds, replug — content resumes automatically
- [ ] Heartbeat: device shows as "online" in RePlay after 30 seconds

## Troubleshooting

### ADB can't connect

- Ensure Fire TV and laptop are on the same WiFi network
- Restart ADB: `adb kill-server && adb start-server`
- Re-enable ADB debugging on the Fire TV

### Fully Kiosk won't start on boot

- Verify "Start Fully on Boot" is ON in Fully Kiosk settings
- Verify the Fire TV launcher is disabled (Step 10)
- Some Fire TV OS versions require a reboot after changing the launcher

### Content not loading

- Check that the Fire TV has internet access (try opening Silk Browser)
- Verify the URL is correct in Fully Kiosk settings
- Check for SSL certificate issues if using a custom domain

### Stick runs hot

- Use the included HDMI extender cable (don't plug directly into TV)
- Ensure airflow around the stick
- The 4K Max runs cooler than older models

### WebSocket disconnects

- Fully Kiosk's "Restart on Internet Reconnect" should handle this
- Your RePlay player JS should auto-reconnect (ActionCable does this by default)
- Check Fully Kiosk Remote Admin for error logs

## Quick reference: ADB commands

```bash
# Connect
adb connect <ip>:5555

# Install an APK
adb install /path/to/app.apk

# Launch Fully Kiosk
adb shell am start -n de.ozerov.fully/.MainActivity

# Reboot
adb reboot

# Screenshot (for debugging)
adb shell screencap /sdcard/screen.png && adb pull /sdcard/screen.png

# Check running apps
adb shell pm list packages | grep fully

# Disable an app
adb shell pm disable-user <package.name>

# Re-enable an app
adb shell pm enable <package.name>

# Open a URL in Fully Kiosk remotely
curl "http://<ip>:2323/?cmd=loadURL&url=https://play.replaytv.co/players/new&password=<your-password>"
```

## Fully Kiosk Remote Admin API

If Remote Admin is enabled, you can control the device over HTTP:

```bash
# Reload current page
curl "http://<ip>:2323/?cmd=loadStartURL&password=<pw>"

# Load a specific URL
curl "http://<ip>:2323/?cmd=loadURL&url=<url>&password=<pw>"

# Take a screenshot
curl "http://<ip>:2323/?cmd=getScreenshot&password=<pw>" > screenshot.png

# Get device info
curl "http://<ip>:2323/?cmd=deviceInfo&password=<pw>"

# Restart Fully Kiosk
curl "http://<ip>:2323/?cmd=restartApp&password=<pw>"
```
