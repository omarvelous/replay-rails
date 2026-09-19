# Analysis: Draft Plan Grooming

## Current Drafts (13)

### Critical — Do Before Production

| Plan | Status | What Changed | Action |
|------|--------|-------------|--------|
| `player-auth-hardening` | Partially done | API now versioned under v1, services extracted. But token broadcast in pairing, cookie expiry, channel validation, token rotation still not done. | **Complete — 1 day** |

### Launch Sprint 1 — Polish & Branding

| Plan | Status | What Changed | Action |
|------|--------|-------------|--------|
| `nyc-product-gaps` | Active roadmap | Gap #2 (Experiences) shipped. Gaps 1, 6 remain for Sprint 1. | **Keep as roadmap** |
| `go-experience` | Partially done | Go::ExperiencesController exists, renders player template. May need its own view. | **Verify — if done, archive** |

### Launch Sprint 2 — Lead Capture Channels

| Plan | Status | What Changed | Action |
|------|--------|-------------|--------|
| `sms-lead-capture` | Valid | No changes. QrCode now has creative/screen_content polymorphic which helps attribution. | **Keep — 2-3 days** |
| `nfc-tap` | Valid | No changes. Small lift on existing QR infrastructure. | **Keep — 1-2 days** |

### Stale — Need Update

| Plan | Status | What Changed | Action |
|------|--------|-------------|--------|
| `ahoy-account-simplification` | Stale | Analytics events renamed to `_pid`. Current.account_user exists now. Ahoy Store already injects account_id. | **Update or split** — decide if full migration is worth it or just add `account_pid` enrichment |
| `day-parting-scheduling` | Stale | References `screen_playlists` which became `screen_contents`. AssignScreenContent service exists now. | **Update references** if pursuing |
| `live-preview` | Stale | Plan says "blocked on 4 type controllers" — Ads::BaseController now exists with all 4 types working. Blocker is resolved. | **Unblock — ready for polish sprint** |

### Valid — Future Work

| Plan | Status | What Changed | Action |
|------|--------|-------------|--------|
| `custom-player-app` | Valid | No codebase changes needed to start. | **Keep** |
| `device-telemetry` | Valid | Depends on custom player app Phase 2. ParseDeviceInfo service exists for UA parsing. | **Keep** |
| `screen-detection` | Valid | No changes. Post-launch observability. | **Keep — defer** |
| `local-network` | Valid | Dev infrastructure, not code. | **Implement in 15 min when hardware testing starts** |

### Archive

| Plan | Status | Why | Action |
|------|--------|-----|--------|
| `listing-import` | Deferred | NYC doesn't need it, fragile scraping, legal risk. Manual entry works. | **Archive** |

---

## Recommended Order

```
1. player-auth-hardening     (security — before production)
2. go-experience             (verify/complete — small)
3. nyc-product-gaps Sprint 1 (agent branding + go page polish)
4. sms-lead-capture          (Sprint 2 — lead capture)
5. nfc-tap                   (Sprint 2 — lead capture)
6. live-preview              (unblocked — polish)
7. ahoy-account-simplification (tech debt — when convenient)
8. custom-player-app         (Phase 2 — hardware)
```

---

## Plans to Clean Up

Remove `listing-import` from drafts → archive or delete.
Update `day-parting-scheduling` references if pursuing later.
Update `live-preview` to remove "blocked" status.
Update `ahoy-account-simplification` to reflect _pid naming.
