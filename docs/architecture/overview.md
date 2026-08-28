# Architecture Overview

RePlay is a Rails 8.1 multi-tenant application for real estate digital signage. Brokerages manage property listings, create ads, build playlists, and display them on screens in storefront windows. QR codes on the ads capture leads from passersby.

## Tech stack

| Layer | Technology |
|-------|-----------|
| Framework | Rails 8.1 |
| Database | PostgreSQL |
| Frontend | Hotwire (Turbo + Stimulus), Tailwind CSS v4, DaisyUI v5 |
| Background jobs | Solid Queue (DB-backed) |
| Caching | Solid Cache (DB-backed) |
| WebSockets | Solid Cable (DB-backed, ActionCable) |
| Auth | Rails 8 built-in authentication |
| Authorization | Action Policy |
| Admin | Administrate |
| Testing | RSpec, FactoryBot, SimpleCov |
| Deployment | Kamal, Docker |

No Redis. All infrastructure is DB-backed via the Solid trifecta.

## Multi-tenancy

Every resource belongs to an `Account`. The `Current` object provides request-scoped context:

```ruby
Current.user     # The authenticated user
Current.account  # The tenant (falls back to user's first account)
```

All queries must scope through the account:

```ruby
Current.account.listings  # Correct
Listing.all               # Wrong — leaks data across tenants
```

Authorization policies enforce this via `authorized_scope` in controllers.

## Core domain loop

```
Listing → Ad → Playlist → Screen → Player → Display
                                         ↓
                              QR Code → Scan → Lead → Agent
```

1. **Listings** — property records with photos, address, price
2. **Ads** — visual representations via 4 delegated types (listing, collection, agent, brand)
3. **Playlists** — ordered sequences of ads with duration per slide
4. **Screens** — logical representations of TVs at office sites
5. **Players** — physical devices paired to screens via 6-character codes
6. **QR codes** — on each ad, linking to listing/agent landing pages
7. **Scans** — recorded when someone scans a QR code, with full attribution
8. **Leads** — contact form submissions from scan landing pages
9. **Agents** — real estate agents assigned to listings and leads

## Subdomain architecture

The app uses 5 subdomains to separate concerns:

| Subdomain | Module | Purpose |
|-----------|--------|---------|
| _(root)_ | `Marketing` | Public marketing site, Go:: landing pages |
| `app` | `App` | Main application (authenticated) |
| `admin` | `Admin` | Internal admin panel (Administrate) |
| `play` | `Play` | HTML playback for screen devices |
| `api` | `Api` | JSON API for device communication |

See [subdomains.md](subdomains.md) for routing details.

## Authorization

Action Policy with two authorization contexts:

```ruby
# app/controllers/app/base_controller.rb
authorize :user, through: :current_user
authorize :account, through: :current_account
```

Policies check roles via the `Authorizable` concern on `User`:

- `user.owner_of?(account)` — full access
- `user.can_manage?(account)` — CRUD resources, invite agents
- `user.agent_on?(account)` — scoped to own listings/leads

The `AccountUser` join model carries the role (owner, manager, agent) and supports multiple roles per user per account.

## Key patterns

- **Delegated types** — Ads use `delegated_type :adable` for 4 ad variants, each with their own layouts and validations
- **Container query CSS** — Signage renders at any resolution using `cqw` units, no media queries
- **ActionCable for device push** — Playlist changes broadcast to paired players in real-time
- **paper_trail** — Audit trail on 16 models with tenant-scoped `account_id` on versions
- **Pagy** — Pagination on all index pages

## Further reading

- [Domain model](domain-model.md) — every model and relationship
- [Subdomains](subdomains.md) — routing architecture
- [Ad templates](ad-templates.md) — delegated types, layouts, themes
- [Lead capture](lead-capture.md) — QR-to-lead pipeline
- [Player pairing](player-pairing.md) — device lifecycle
- [Signage CSS](signage-css.md) — container queries and scaling
