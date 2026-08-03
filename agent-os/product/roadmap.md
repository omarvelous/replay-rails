# Product Roadmap

## Phase 1: Skeleton MVP

The simplest end-to-end path: sign up, set up a screen, create a listing, make an ad, build a playlist, assign it to a screen. Basic forms, no polish. Prove the core loop works.

### Critical path (build order)

1. **Sites** — CRUD scoped to Account. Name + address. Basic form.
2. **Screens** — CRUD scoped to Site. Name + orientation. Player assigned manually (no pairing flow).
3. **Listings** — CRUD scoped to Account. Address, price, beds, baths, sqft, status. Manual entry only.
4. **Agents** — CRUD scoped to Account. Name, email, phone. Join model to Listings (ListingAgent with role).
5. **Ads** — CRUD scoped to Account. Headline, body, image upload, optional Listing link. Single layout — no templates, no themes.
6. **Playlists** — CRUD scoped to Account. Ordered list of Ads with per-slide duration. Status: draft → published → archived.
7. **Screen ↔ Playlist assignment** — Assign a published Playlist to a Screen. One active playlist per screen.

### Deferred to Phase 2

- Player pairing flow (enter code from device)
- Layout templates and themes
- QR code generation + passerby landing page
- Photo uploads on Listings (single image on Ad is sufficient for now)
- CSV import for Listings
- Day-parting / scheduling
- Playlist versioning / rollback
- Multi-office dashboard
- QR scan analytics
- Offline resilience
- MLS sync
- Compliance helpers

## Phase 2: UX & Features

Polish the skeleton. Add the features that make it usable by a non-technical office manager.

- Player pairing flow (device shows code, user enters it)
- Ad templates (hero, split, minimal, stat grid) and themes (dark, light, brand)
- QR codes on Ads → mobile property detail page
- Listing photos (multiple, gallery view)
- Drag-and-drop playlist ordering
- Richer screen status (idle / live / offline)

## Phase 3: Scale & Intelligence

- MLS auto-sync (RESO Web API)
- Day-parting / multi-playlist scheduling per screen
- Playlist versioning with rollback
- Multi-office dashboard with map view
- QR scan analytics (per listing, per screen, over time)
- Offline player resilience (cache last playlist)
- Compliance guardrails (Fair Housing, state disclosures)
