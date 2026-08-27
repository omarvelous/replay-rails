# Plan: Internal Admin v2 (`admin.replay.com`) — executed

_Final version. Supersedes `plan-admin.md` in tmp/._

## Status: Phases 1-2 complete

427 specs, 0 failures. 95.05% line coverage, 81.01% branch coverage.

---

## What was built

### Administrate integration (changed from custom)

The v2 plan originally recommended custom controllers. During execution,
we switched to Administrate — it provides search, pagination, sorting,
show pages with associations, and edit forms out of the box. The admin
is internal-only, so Administrate's default UI is acceptable.

### Dashboards (21 total)

Every model has an Administrate dashboard:

| Dashboard | Key fields shown |
|-----------|-----------------|
| Account | users, sites, listings, ads, qr_codes |
| User | name, email, admin flag, account |
| Site | name, address, photo, screens |
| Player | token, IP, heartbeat, firmware, pairing history |
| Screen | name, orientation, site, playlists, players |
| Listing | address, price, beds/baths/sqft, status, photos, agents |
| Agent | name, email, phone, photo, listings |
| Ad | headline, adable type, layout, theme, image |
| ListingAd | listing, badge, event fields |
| AgentAd | agent |
| BrandAd | (minimal) |
| CollectionAd | collection_title, member ads |
| CollectionAdAd | collection_ad, ad, position |
| Playlist | name, status, ads |
| PlaylistAd | playlist, ad, position, duration |
| QrCode | token, account, destination, active, scans |
| QrScan | qr_code, account, ad, screen, IP |
| ScreenPlaylist | screen, playlist, active |
| ScreenPlayer | screen, player, active, paired_by |
| Session | user |

### ActiveStorage support

`administrate-field-active_storage` gem renders image thumbnails in
admin index/show pages and upload fields on edit forms. Used on:
Listing (photos), Ad (image), Agent (photo), Site (photo).

### Auth

- `admin` boolean on User (migration, default false)
- `Admin::ApplicationController < Administrate::ApplicationController`
  with `include Authentication` + `before_action :require_admin!`
- Login happens at `app.replay.com` — session cookie shared via `domain: :all`
- Non-admin users redirected to app root with `allow_other_host: true`

### Custom dashboard

`Admin::DashboardController` (custom, not Administrate) at the admin root
showing platform stats: accounts, players online, screens, QR codes,
qualified scans, scans today.

### Routes

```ruby
constraints subdomain: "admin" do
  scope module: "admin", as: "admin" do
    root "dashboard#show", as: :root
    resources :accounts
    resources :users
    resources :sites
    resources :players
    resources :screens
    resources :listings
    resources :agents
    resources :ads
    resources :playlists
    resources :qr_codes
    resources :qr_scans
  end
end
```

Full CRUD for all resources. Administrate handles the views.

---

## Key implementation details

### Session cookie cross-subdomain

The `session_id` signed cookie is set with `domain: :all`:
```ruby
cookies.signed.permanent[:session_id] = {
  value: session.id, httponly: true, same_site: :lax, domain: :all
}
```

Without this, the cookie is scoped to `app.replay.localhost` and the
admin subdomain can't read it.

### Post-login redirect

`sessions#create` uses `allow_other_host: true` on the redirect. When
a user navigates to `admin.replay.localhost` unauthenticated, they're
redirected to login at `app.replay.localhost`. After login, the
`return_to_after_authenticating` URL points back to the admin subdomain —
a cross-host redirect that needs `allow_other_host: true`.

### Test helper

The `sign_in` helper creates a session and sets the signed cookie
directly (bypasses the login POST). This works across subdomain
boundaries in Rack::Test, which isolates cookies per host.

```ruby
def sign_in(user)
  session = user.sessions.create!(user_agent: "RSpec", ip_address: "127.0.0.1")
  jar = ActionDispatch::Request.new(Rails.application.env_config.deep_dup).cookie_jar
  jar.signed[:session_id] = { value: session.id, httponly: true }
  cookies[:session_id] = jar[:session_id]
end
```

Admin specs use `host! "admin.replay.localhost"`.

---

## What's remaining

### Phase 3 — Filters + polish
- Player filters: online / offline / unpaired in Administrate
- Custom Administrate fields for status badges
- Account search by user email
- Pagination tuning (default items per page)

### Phase 4 — Dependencies (as they ship)
- Leads dashboard (after lead capture plan)
- Marketing Inquiries dashboard (after marketing plan Phase 7)
- Impressions on dashboard (after metrics plan Phase 1)

### Phase 5 — Advanced (deferred)
- User impersonation (security review first)
- Feature flags per account (Flipper gem)
- Billing / subscription management (Stripe)
- Audit log (paper_trail gem)
- CSV/PDF export
- Bulk operations
