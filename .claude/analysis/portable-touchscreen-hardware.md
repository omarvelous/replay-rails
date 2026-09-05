# Analysis: Portable Touchscreen Hardware for Open Houses

## Context

The existing player hardware analysis (`.claude/analysis/player-hardware.md`)
covers headless HDMI sticks (Fire TV, Pi) for **passive storefront signage**.
This analysis covers a different category: **portable touchscreen displays**
for **interactive open house experiences**.

The NYC go-to-market strategy identifies two product motions:

1. **Storefront windows** — passive slideshow (HDMI sticks work fine)
2. **Portable open house signage** — interactive kiosk (needs a screen
   with touch, battery, and portability)

This second motion requires hardware that doesn't exist in our current
inventory. An agent needs to wheel a screen into a listing, power it on,
and have visitors interact with it — browse photos, view details, submit
lead forms, scan QR codes.

### What the hardware must do

| Requirement | Why |
|-------------|-----|
| **Touchscreen** | Experiences v2 interactive mode: swipe photos, tap forms, navigate sections |
| **Android OS** | Run the RePlay player app (WebView + native telemetry) |
| **Battery** | Open houses don't guarantee outlet access near the display spot |
| **Portable** | Agent transports it to the listing, sets up in < 2 minutes |
| **WiFi** | ActionCable for live updates, API for heartbeat/impressions |
| **32" range** | Large enough to be a showpiece, small enough to transport |
| **Capacitive touch** | Responsive multi-touch for swipe gestures (not resistive) |

### What the hardware should ideally do

| Nice-to-have | Why |
|--------------|-----|
| Wheels/stand included | Zero setup friction — roll in and go |
| 500+ nit brightness | Sun-filled apartments won't wash out the display |
| Google Play Services | FCM push notifications, up-to-date WebView via Play Store |
| HDMI input | Double as a storefront display with a Fire TV Stick plugged in |
| 6+ hour battery | Covers a full open house plus buffer |

---

## The Trigger: ApoloSign 32" Gen2

**ApoloSign 32 Inch 4K UHD Smart Portable TV on Wheels (Gen2)**

| Spec | Detail |
|------|--------|
| Price | ~$819 (4K/256GB), ~$719 (FHD/128GB) |
| Screen | 32" VA LCD, 4K or 1080p |
| Brightness | 300 nits |
| Touch | 10-point capacitive |
| OS | Android 16, Google EDLA certified |
| RAM / Storage | 8GB (4+4 virtual) / 256GB (4K) or 128GB (FHD) |
| Battery | 15,000mAh, ~6 hours claimed |
| Mobility | 5 omnidirectional silent wheels, swivel, height/tilt adjustable |
| Camera | 8MP built-in |
| WiFi | Yes |
| Speakers | Built-in |

### Why it's interesting

This is essentially the open house demo device described in the NYC
strategy — a touchscreen on wheels with a battery that runs Android.
It checks every box:

- **EDLA certified** = full Google Play, modern WebView, standard
  Android APIs. Our custom player APK installs directly.
- **Touch events flow through WebView** — swipe galleries, tap lead
  forms, interactive kiosk mode all work without native-layer changes.
- **Battery + wheels** = truly portable. No outlet hunting, no tripod,
  no external stand. Agent rolls it in, powers on, it's live.
- **Android 16** = `BatteryManager` API for telemetry (critical for
  portable devices: "your screen has 3 hours left").

### Concerns

- **300 nits is dim.** Fine for interior rooms, but sun-filled
  penthouses and south-facing apartments will wash it out. Commercial
  signage panels run 500-2000+ nits.
- **Consumer-grade panel.** Not rated for 24/7. Fine for 2-4 hour open
  houses, not for permanent storefront windows.
- **No bulk/OEM pricing.** Sold retail only. $719-819/unit doesn't
  scale to a fleet.
- **Battery life under load.** 6 hours claimed may be 3-4 hours real
  with a bright WebView + touch + WiFi running continuously. Needs
  testing on actual hardware.
- **No VESA mount.** Can't wall-mount for dual-use as storefront
  signage. Wheels-only form factor.

### Verdict

**Buy one as the demo/sales unit.** At $719 (FHD), it's ready to use
out of the box. Install the player app, load it with a listing, and
bring it to broker opens. This is the device that closes the first 5
deals. Don't optimize for cost at this stage — optimize for "does this
make agents say yes?"

The FHD model at $719 is sufficient. Our ad layouts use container
queries (`cqw` units) that scale to any resolution, and at 32" the
difference between 1080p and 4K is negligible for signage content
viewed from 3-6 feet.

---

## Alternative Options Evaluated

### Tier 1: Ready-to-Deploy (Buy on Amazon, Use Immediately)

#### OptiSigns OptiKiosk 32"

| Spec | Detail |
|------|--------|
| Price | ~$900 (with stand + battery) |
| Screen | 32" FHD |
| Brightness | Not specified (likely 300-350 nits) |
| Touch | 10-point capacitive |
| OS | Android (OptiSigns CMS pre-loaded) |
| RAM / Storage | 8GB / 128GB |
| Battery | Built-in, up to 8 hours (best-in-class) |
| WiFi | WiFi 6, Bluetooth 5.3 |
| Mobility | Floor stand (no wheels) |

**Pros:** Best battery life (8 hours). WiFi 6. Commercial signage
brand with support.

**Cons:** Locked into OptiSigns CMS (subscription required). Need to
verify sideloading our app is possible. No wheels — would need a
separate rolling cart. More expensive than ApoloSign for less
portability.

**Verdict:** Skip. The OptiSigns CMS lock-in fights our architecture,
and no wheels defeats the portability purpose.

#### ApoloSign 24" Portable TV

| Spec | Detail |
|------|--------|
| Price | ~$499-599 |
| Screen | 24" |
| Battery | 5,300mAh (~5 hours) |
| Everything else | Same platform as 32" Gen2 |

**Verdict:** Consider as a budget option or for smaller spaces, but
32" has more visual impact for open house demos. The smaller battery
is also a concern.

#### 360SPB 32" Portable Indoor Signage

| Spec | Detail |
|------|--------|
| Price | ~$400-600 |
| Screen | 32" 2K, 700 nits |
| Touch | 10-point capacitive (touch variant) |
| OS | Android 11 |
| RAM / Storage | 2GB / 32GB |
| Battery | None |
| Mobility | Built-in handle + wheels |

**Pros:** 700 nits — over 2x brighter than ApoloSign. Much cheaper.
Has wheels.

**Cons:** No battery (must plug in). Android 11 with only 2GB RAM
is borderline for a WebView app — may lag with image-heavy content.
32GB storage is tight if we add offline caching later.

**Verdict:** Interesting as a budget storefront unit where power is
available. Not viable for open houses (no battery). The brightness
advantage is real though — worth noting for bright environments.

### Tier 2: Commercial/Enterprise (Higher Cost, Higher Quality)

#### Elo Touch 3204L + Android Backpack

| Spec | Detail |
|------|--------|
| Price | ~$2,500+ (display + Android compute module) |
| Screen | 32" FHD, 500 nits |
| Touch | 40-point PCAP (gold standard) |
| OS | Android via Elo Backpack module |
| Battery | None |
| Mobility | None (requires stand/mount) |
| Rated | 24/7 commercial |

**Pros:** Best-in-class touch accuracy. 500 nits. Commercial rated.
Elo is the industry standard for interactive kiosks.

**Cons:** 3-4x the cost. No battery. No portability. Requires
separate compute module, stand, and power.

**Verdict:** Overkill for open houses. Consider for permanent
lobby installations if a customer wants a premium fixed kiosk.

#### Displays2Go 32" Kiosk

| Spec | Detail |
|------|--------|
| Price | ~$1,200-1,800 |
| Screen | 32" FHD |
| Touch | 10-point PCAP |
| OS | Android 14, Google Play |
| Battery | None on 32" (43" has battery option) |
| Camera | 5MP |

**Verdict:** Overpriced for what it offers vs. ApoloSign. No battery
on the 32" model is a dealbreaker for open houses.

#### 360SPB Outdoor Portable Signage

| Spec | Detail |
|------|--------|
| Price | ~$2,000-3,500 |
| Screen | 32" FHD, 1800-2000 nits |
| Touch | Capacitive with tempered glass |
| OS | Android 14 |
| Battery | 1,200Wh, 10-15 hours |
| Durability | IP65 waterproof |
| Mobility | Wheels included |

**Pros:** Insane battery life. Sunlight readable. Waterproof. Could
literally put it on the sidewalk outside the listing.

**Cons:** 3-5x the cost of ApoloSign. Massive overkill for indoor
open houses.

**Verdict:** Only relevant if we ever do outdoor/sidewalk signage
(building entrances, street-facing events). File for later.

### Tier 3: OEM / White-Label (Bulk — Long-Term Play)

This is where the economics change dramatically at scale. Chinese
manufacturers sell essentially the same hardware as the ApoloSign
at 30-40% of the retail price.

#### FVASEE (Shenzhen)

| Spec | Detail |
|------|--------|
| Factory price | ~$220-275/unit |
| MOQ | 50-100 units |
| Sizes | 21.5", 24", 27", 32" |
| Customization | Pre-install app, custom boot logo, kiosk lockdown, branding |
| Lead time | 2-3 day quote, 30-45 day production |
| Track record | 20+ years manufacturing |

**This is the most interesting long-term option.** At ~$250/unit for
a 32" Android touchscreen with battery and wheels (configured to
spec), the math changes completely:

- 50 units OEM: ~$12,500
- 50 units ApoloSign: ~$36,000
- Savings: $23,500 (65% less)

Custom ROM means the device boots straight into the RePlay player
app. No setup, no sideloading, no app store. Power on → content plays.

#### Shenzhen Qunmao

| Spec | Detail |
|------|--------|
| Factory price | ~$200-300/unit |
| MOQ | 1-50 units (lower barrier) |
| Sizes | 27", 32" |
| Features | Android, battery, capacitive touch, wheels |

Lower MOQ than FVASEE — could order 10-20 units as a test batch.

#### Generic Alibaba Listings

Dozens of manufacturers offer similar products at $220-375/unit,
MOQ 1-100. Quality varies wildly. Risk of bad panels, weak batteries,
outdated Android versions, and poor after-sales support.

**OEM risk mitigation:**
- Order 2-3 samples before committing to MOQ
- Verify Android version, WebView compatibility, touch responsiveness
- Test battery life under realistic load (WebView + WiFi + max brightness)
- Get factory certifications (FCC, UL) for US sale
- Negotiate warranty terms (dead pixels, battery defects)

---

## Recommendation: Three-Phase Hardware Strategy

### Phase 1: Demo Unit (Now — First 5 Deals)

**Buy 1x ApoloSign 32" FHD Gen2 ($719)**

This is the sales tool, not the product. It's the screen you wheel
into a broker open and demo RePlay live. The goal is closing deals,
not optimizing unit economics.

- Install the custom player APK
- Load with a compelling demo listing (great photos, full details)
- Bring to broker opens and in-person demos
- Learn what agents react to, what questions they ask, what breaks

After 5-10 demos, you'll know:
- Do agents care about screen size? (Maybe 24" is fine)
- Do they notice brightness? (Maybe 300 nits is a problem)
- How long do open houses actually run? (Battery life requirement)
- Do they want to buy the hardware or rent it?
- Do they even want a screen, or do they want tablets?

**Don't buy more than 1-2 units at retail.** Every insight from
real demos will change the spec for the production unit.

### Phase 2: Early Customer Fleet (5-20 Customers)

**Buy 5-10x ApoloSign or order OEM samples**

Once you have paying customers, you need hardware to deploy. Two paths:

**Path A — Continue with ApoloSign ($719/unit)**
- Predictable quality, immediate availability
- Order 5-10 units from Amazon
- Total: $3,600-7,200
- Pro: Fast. Con: Expensive at scale.

**Path B — Order OEM samples ($250-300/unit + shipping)**
- Contact FVASEE and Qunmao, order 2-3 samples each
- Test side-by-side with ApoloSign: build quality, touch accuracy,
  battery life, Android version, WebView compatibility
- Takes 4-6 weeks for samples to arrive
- If samples pass: order 10-20 units at OEM price
- Total for 10 units: ~$2,500-3,000 + shipping/duties

**Recommendation:** Do both in parallel. Use ApoloSign units for
immediate deployments while OEM samples are in transit. This keeps
momentum with customers while building the cost-effective supply chain.

### Phase 3: Scale (50+ Units)

**OEM partnership with custom ROM**

Once the product-market fit is proven and you need 50+ units:

- Finalize spec with chosen OEM (FVASEE or Qunmao)
- Custom ROM: boots directly into RePlay player app
- Custom branding: "RePlay" on boot screen, on device casing (optional)
- Kiosk lockdown: no home button, no settings access, no app store
- Pre-configured WiFi setup flow (captive portal or QR-based)
- OTA update channel built into the ROM

At $250/unit × 50 = $12,500 for a fleet of branded, pre-configured,
ready-to-deploy kiosk displays.

**Hardware rental pricing model:**

| Model | Monthly | Includes |
|-------|---------|----------|
| Screen rental | $29-49/mo | Hardware, warranty, replacement |
| Software only (BYOD) | $49-99/mo | Agent provides their own screen |
| Bundle (screen + software) | $79-129/mo | Everything |

At $250 cost per unit and $29-49/mo rental, hardware breaks even in
5-9 months. After that, it's margin.

---

## Compatibility with RePlay Software Stack

### Custom Player App (plan-custom-player-app.md)

The same APK built for Fire TV Sticks works on all these devices.
The app is a WebView wrapper — it loads `play.replaytv.co` and adds
native telemetry. Key compatibility notes:

| Feature | Fire TV Stick | ApoloSign / OEM Android |
|---------|---------------|------------------------|
| Google Play Services | No (Fire OS) | Yes (EDLA) |
| FCM Push | No | Yes |
| WebView updates | Amazon-controlled | Play Store (current) |
| Touch events | N/A (no screen) | Native pass-through to WebView |
| BatteryManager API | N/A | Yes — report charge level |
| Kiosk lock task mode | Supported | Supported |
| Boot receiver | Supported | Supported |

For battery-powered portable displays, the player app should add:
- Battery level in telemetry heartbeat
- Low battery warning overlay (< 15%)
- "Charging" indicator in admin dashboard

### Experiences v2 (plan-experiences-v2.md)

The touch + Android combination enables the full Experience feature:

- **Touch detection**: `"ontouchstart" in window` → interactive mode
- **Swipe gestures**: Native touch → WebView touch events → Stimulus
- **On-screen keyboard**: Android soft keyboard appears for lead forms
  (unlike Fire TV which has no keyboard)
- **Idle/attract mode**: Touch timeout → auto-cycle photos
- **QR handoff**: Visitors scan the 32" screen's QR with their phone

No code changes needed for touch — the WebView handles it. The
Stimulus controllers in the Experiences plan detect touch capability
and adapt the UI automatically.

### Player Layout

The existing `player.html.erb` layout is a full-black, no-chrome
layout. It works on any screen size. The ad layouts use container
queries (`cqw` units) that scale proportionally to the container
width — whether that's a 32" TV or a 55" storefront display.

---

## Brightness: The One Real Concern

Most consumer portable displays are 300-350 nits. This matters
because open houses happen in real apartments with real windows:

| Environment | Nits needed |
|------------|-------------|
| Interior room, curtains drawn | 200-300 (fine) |
| Living room, indirect daylight | 300-500 (borderline) |
| Sun-filled room, south-facing | 500-700 (need brighter) |
| Outdoor / direct sunlight | 1000+ (consumer panels fail) |

**Mitigation strategies:**
1. Position the screen away from windows (most effective)
2. Use high-contrast ad themes (dark theme with white text)
3. Set display brightness to maximum via Android settings
4. For bright rooms: consider the 360SPB 700-nit indoor panel
   ($500, no battery) with a portable battery pack

This is something to test during real demos. If brightness is
consistently a problem, the OEM spec should require 500+ nits.

---

## Decision Summary

| Stage | Hardware | Cost/Unit | Qty | Total |
|-------|----------|-----------|-----|-------|
| **Now** | ApoloSign 32" FHD Gen2 | $719 | 1 | $719 |
| **5-20 customers** | ApoloSign + OEM samples | $250-719 | 10-15 | $4,000-8,000 |
| **50+ units** | OEM custom (FVASEE/Qunmao) | $250 | 50 | $12,500 |

The ApoloSign gets you to market. OEM gets you to margin.

---

## Open Questions

1. **Tablets as an alternative?** A 15" iPad Pro on a stand is a
   known quantity ($1,200) but locks you into Safari WebView (no
   custom Android app). Samsung Galaxy Tab S9 Ultra (14.6") with
   DeX mode is another option. Both are smaller than 32" but more
   portable. Worth testing if agents prefer a smaller, lighter device.

2. **Hardware rental vs. sale?** Do agents want to own the screen
   or rent it? Rental creates recurring revenue and simplifies
   support (swap out defective units). Sale is simpler but creates
   support obligations without ongoing revenue.

3. **Dual-use?** Can one device serve both storefront (passive) and
   open house (interactive) use cases? The ApoloSign on wheels isn't
   ideal for a storefront window (needs wall/window mount). Two
   different form factors may be needed.

4. **Insurance/liability?** If we rent hardware to agents and it
   gets damaged at an open house, who pays? Need clear terms.

5. **Shipping logistics.** Shipping a 32" display to a customer is
   expensive and fragile. Local delivery/setup may be necessary for
   NYC (which is fine — it's a sales touchpoint). For expansion
   beyond NYC, need a shipping solution.
