# Plan: Local Network Dev Environment (Draft)

## Problem

Testing on physical devices (Fire TV Sticks, Raspberry Pis) requires
a real URL — `localhost` doesn't resolve from other devices on the
network. Currently we deploy to staging for every change we want to
test on hardware. This slows down the feedback loop significantly.

We need `play.replay.localhost` (and all other subdomains) to resolve
to the dev machine's IP from any device on the local network.

## Requirements

- `*.replay.localhost` resolves to the dev Mac's local IP (e.g., 192.168.1.100)
- Works from Fire TV Sticks, Raspberry Pis, phones — any device on the LAN
- Wildcard support (not one entry per subdomain)
- No public DNS exposure
- Works with the existing Rails subdomain routing (no `tld_length` changes)
- Minimal setup — ideally a one-time config

## Options

### Option A: UniFi local DNS entries (no wildcard)

UniFi routers support static DNS entries but may not support wildcards.

**Setup:**
1. UniFi Console → Settings → Networks → DNS (or Gateway → DNS)
2. Add entries:
   - `replay.localhost → 192.168.1.100`
   - `app.replay.localhost → 192.168.1.100`
   - `play.replay.localhost → 192.168.1.100`
   - `api.replay.localhost → 192.168.1.100`
   - `admin.replay.localhost → 192.168.1.100`

**Pros:** No software to install, works for all devices on the network
**Cons:** No wildcard — must add each subdomain manually. If you add
a new subdomain, you have to update the router.

### Option B: dnsmasq on the dev Mac (wildcard)

Run a local DNS server that handles `*.replay.localhost` with a
single wildcard rule.

**Setup:**
```bash
brew install dnsmasq

# Configure wildcard
echo "address=/replay.localhost/192.168.1.100" >> /opt/homebrew/etc/dnsmasq.conf

# Start the service
sudo brew services start dnsmasq
```

Then point devices to use the Mac as their DNS server:
- **Option B1:** Set per-device (Fire TV WiFi settings → DNS → manual → Mac's IP)
- **Option B2:** Set network-wide in UniFi DHCP settings → DNS server → Mac's IP
  (all devices on the network use Mac as primary DNS, with a fallback
  to the router or 1.1.1.1 for everything else)

**Pros:** True wildcard, one rule handles all subdomains
**Cons:** Requires dnsmasq running on the Mac. If Mac sleeps or shuts
down, DNS breaks for devices using it. Option B2 affects all devices
on the network.

### Option C: Pi-hole or AdGuard Home (wildcard, dedicated)

Run a DNS server on a Raspberry Pi or Docker container that handles
the wildcard and also serves as the network's DNS.

**Setup:**
1. Install Pi-hole or AdGuard Home on a Pi or Docker
2. Add DNS rewrite: `*.replay.localhost → 192.168.1.100`
3. Set as network DNS in UniFi DHCP settings

**Pros:** Dedicated, always-on, wildcard support, also gives you
ad blocking and DNS analytics
**Cons:** Another device/container to manage. Overkill if only
needed for dev testing.

### Option D: Use a real domain with local IP (split DNS)

Register a dev subdomain (e.g., `*.local.replaytv.co`) and point
it to your local IP in Cloudflare DNS.

**Setup:**
1. Cloudflare DNS: `*.local.replaytv.co → 192.168.1.100` (DNS only, not proxied)
2. Rails dev config: use `local.replaytv.co` as the domain

**Pros:** No local DNS setup, works immediately on all devices
**Cons:** Your local IP is in public DNS (low risk but not ideal).
Only works on your specific network. IP changes require DNS update.

### Option E: nip.io (no setup, no wildcard routing)

Use `play.192.168.1.100.nip.io:3000` — resolves to the IP
automatically.

**Pros:** Zero setup
**Cons:** Rails `tld_length` needs to be overridden (same problem
as staging subdomain). Long ugly URLs. Already evaluated and rejected
for this reason.

## Recommendation

**Option A (UniFi entries) for now, Option B (dnsmasq) if you need
wildcard.** 

UniFi entries are the fastest — 5 entries, done in 2 minutes, works
for all devices immediately. You only have 5 subdomains and they
rarely change. If you later need wildcard (e.g., per-tenant subdomains
in dev), switch to dnsmasq.

**Also needed:** Ensure Rails binds to `0.0.0.0` (not `127.0.0.1`)
so the app is accessible from other devices on the network. Docker
Compose likely already does this, but verify.

## Considerations

- **Mac IP stability** — use a DHCP reservation in UniFi for the
  dev Mac so the IP doesn't change
- **HTTPS** — local dev is HTTP. Fire TV Stick / Fully Kiosk may
  warn about insecure connections. Fully Kiosk has a setting to
  allow HTTP.
- **Port** — devices need to hit `:3000` (or whatever port Rails
  runs on). Include the port in URLs.
- **Multiple developers** — each dev needs their own DNS entries
  or their own dnsmasq. Option D (real domain) avoids this but
  has the public DNS tradeoff.
