# Plan: Internal Admin v2 (`admin.replay.com`)

_Supersedes `plan-admin.md`. Updated for subdomain architecture,
current model state, and dependencies._

## Purpose

The RePlay team needs to manage accounts, players, and the platform.
This is the operations panel — not customer-facing.

**What we need:**
- View and manage all accounts (brokerages)
- Provision and track player devices (fleet management)
- Monitor screen health (online/offline across all accounts)
- View platform-wide analytics (scans, leads, impressions)
- View and manage QR codes across accounts
- Manage marketing inquiries (RePlay's own lead pipeline)
- Impersonate users for support (future)
- Billing / subscriptions (future)

---

## Prerequisites (not yet built)

| Dependency | Plan | Status |
|------------|------|--------|
| `Lead` model | `plan-lead-capture.md` | Not built |
| `Marketing::Inquiry` model | `plan-marketing-site-v3.md` Phase 7 | Not built |
| `Impression` model | `plan-metrics.md` Phase 1 | Not built |

The admin can be built incrementally — start with what exists (Account,
Player, Screen, QrCode, QrScan), add Lead/Inquiry/Impression dashboards
as those features ship.

---

## Subdomain infrastructure (already in place)

The subdomain routing, session cookie sharing (`domain: :all`), TLD
config, and host authorization are all implemented. Adding the admin
subdomain is just uncommenting the constraint block in `routes.rb`
and adding the controllers.

```ruby
# config/routes.rb — already has the pattern, just add:
constraints subdomain: "admin" do
  scope module: "admin" do
    root "dashboard#show", as: :admin_root
    # ...
  end
end
```

Test specs use `host! "admin.replay.localhost"`.

Cross-subdomain links use `_url` helpers:
```erb
<%= link_to "← App", app_root_url(subdomain: "app") %>
```

---

## Auth: admin users

Add an `admin` boolean to `User`:

```ruby
# migration
add_column :users, :admin, :boolean, null: false, default: false
```

Admin users log in at `app.replay.com` (normal login flow). The session
cookie is shared across subdomains. When they navigate to
`admin.replay.com`, the `Admin::BaseController` checks `Current.user.admin?`.

```ruby
module Admin
  class BaseController < ApplicationController
    before_action :require_admin!

    layout "admin"

    private

      def require_admin!
        unless Current.user&.admin?
          redirect_to app_root_url(subdomain: "app"), alert: "Not authorized.", allow_other_host: true
        end
      end
  end
end
```

No separate admin login. No separate admin user model. Just a boolean
on the existing User.

---

## Build vs gem

### Recommendation: Custom for v1

After evaluating Administrate, Avo, Madmin, and Motor Admin against
our architecture:

- **Administrate** generates its own view layer and controller namespace.
  With our `App::` module structure and subdomain constraints, integrating
  it under `constraints subdomain: "admin"` requires overriding its
  routing and controller inheritance. More glue code than value for
  the 6-8 resources we need.

- **Avo** is the most capable but paid for dashboards and custom tools —
  the features we'd actually use on the admin.

- **Custom admin** is straightforward. We already have the patterns:
  controllers with `pagy` for pagination, Tailwind tables for index
  views, show pages with detail cards. The admin is internal — it
  doesn't need to be beautiful, it needs to be functional.

For v1: custom controllers and views. The admin is 6-8 index + show
pages with filters. We've built 10+ of those in the app already.
If the admin grows to need complex dashboards, charts, or bulk
operations, reconsider Avo Pro.

---

## What the admin manages

### Dashboard (platform health)

```
┌──────────┬──────────┬──────────┬──────────┐
│  12      │  8/10    │  342     │  27      │
│  Accounts│  Players │  Scans   │  Leads   │
│          │  online  │  today   │  this wk │
└──────────┴──────────┴──────────┴──────────┘
```

```ruby
module Admin
  class DashboardController < BaseController
    def show
      @total_accounts = Account.count
      @total_players = Player.count
      @players_online = Player.where("last_heartbeat_at > ?", 2.minutes.ago).count
      @players_offline = Player.joins(:screen_players)
                               .merge(ScreenPlayer.active)
                               .where("last_heartbeat_at <= ? OR last_heartbeat_at IS NULL", 2.minutes.ago)
                               .count
      @total_scans = QrScan.qualified.count
      @scans_today = QrScan.qualified.where("created_at > ?", Date.current.beginning_of_day).count
      @total_qr_codes = QrCode.count
    end
  end
end
```

### Accounts

| Column | Source |
|--------|--------|
| ID | `account.id` |
| Users | `account.users.count` |
| Sites | `account.sites.count` |
| Screens | `account.screens.count` |
| Ads | `account.ads.count` |
| QR Codes | `account.qr_codes.count` |
| Scans (qualified) | `QrScan.qualified.where(account: account).count` |
| Created | `account.created_at` |

**Actions:** View details (show page with all associations).

### Players (fleet management)

The key admin view. Tracks the physical device inventory.

| Column | Source |
|--------|--------|
| ID | `player.id` |
| Token | Masked (`player.token.first(8)...`) |
| Status | Online / Offline / Unpaired |
| Paired to | Screen name + Account name (via ScreenPlayer) |
| Last heartbeat | `player.last_heartbeat_at` |
| IP | `player.ip_address` |
| Firmware | `player.firmware_version` |
| Created | `player.created_at` |

**Filters:** Online / Offline / Unpaired / All

**Actions:** View details (pairing history via `screen_players`),
decommission (future).

### Screens (cross-account)

| Column | Source |
|--------|--------|
| Name | `screen.name` |
| Account | `screen.site.account` |
| Site | `screen.site.name` |
| Player | Online / Offline / Unpaired |
| Playlist | Active playlist name or "None" |
| Orientation | `screen.orientation` |

### QR Codes (cross-account)

| Column | Source |
|--------|--------|
| Token | `qr_code.token` |
| Account | `qr_code.account` |
| Destination | Listing address / Agent name / URL |
| Scans (qualified) | `qr_code.scans.qualified.count` |
| Active | `qr_code.active?` |
| Created | `qr_code.created_at` |

### QR Scans

| Column | Source |
|--------|--------|
| QR Code | Token |
| Account | `qr_scan.account` |
| Ad | `qr_scan.ad&.headline` |
| Screen | `qr_scan.screen&.name` |
| Qualified | Yes/No |
| IP | `qr_scan.ip_address` |
| Scanned at | `qr_scan.created_at` |

### Leads (when built)

| Column | Source |
|--------|--------|
| Name | `lead.name` |
| Account | `lead.account` |
| Listing | `lead.listing&.address` |
| Type | `lead.lead_type` |
| Status | `lead.status` |
| Created | `lead.created_at` |

### Marketing Inquiries (when built)

| Column | Source |
|--------|--------|
| Name | `inquiry.name` |
| Email | `inquiry.email` |
| Company | `inquiry.company` |
| Type | `inquiry.inquiry_type` |
| Created | `inquiry.created_at` |

**Actions:** Update status (new → responded → converted).

---

## Admin layout

```erb
<%# app/views/layouts/admin.html.erb %>
<body class="bg-gray-50 min-h-screen">
  <nav class="bg-gray-900 text-white px-6 py-3 flex items-center justify-between">
    <div class="flex items-center gap-6">
      <a href="<%= admin_root_url(subdomain: "admin") %>" class="font-bold">
        RePlay <span class="text-xs bg-red-500 px-1.5 py-0.5 rounded ml-1">Admin</span>
      </a>
      <%= link_to "Dashboard", admin_root_path, class: "text-sm text-gray-300 hover:text-white" %>
      <%= link_to "Accounts", admin_accounts_path, class: "text-sm text-gray-300 hover:text-white" %>
      <%= link_to "Players", admin_players_path, class: "text-sm text-gray-300 hover:text-white" %>
      <%= link_to "Screens", admin_screens_path, class: "text-sm text-gray-300 hover:text-white" %>
      <%= link_to "QR Codes", admin_qr_codes_path, class: "text-sm text-gray-300 hover:text-white" %>
      <%= link_to "Scans", admin_qr_scans_path, class: "text-sm text-gray-300 hover:text-white" %>
    </div>
    <div class="flex items-center gap-4">
      <%= link_to "← App", app_root_url(subdomain: "app"), class: "text-sm text-gray-400 hover:text-white" %>
      <span class="text-sm text-gray-400"><%= Current.user&.email_address %></span>
    </div>
  </nav>

  <div class="max-w-7xl mx-auto px-6 py-8">
    <%= yield %>
  </div>
</body>
```

---

## Routes

```ruby
constraints subdomain: "admin" do
  scope module: "admin" do
    root "dashboard#show", as: :admin_root

    resources :accounts, only: %i[ index show ]
    resources :players, only: %i[ index show ]
    resources :screens, only: %i[ index show ]
    resources :qr_codes, only: %i[ index show ]
    resources :qr_scans, only: %i[ index show ]

    # Added when models are built:
    # resources :leads, only: %i[ index show ]
    # resources :marketing_inquiries, only: %i[ index show update ]
  end
end
```

Read-only for most resources. The admin observes and monitors.
Write operations (impersonation, decommissioning, status updates)
are added as needed in later phases.

---

## Player provisioning workflow (updated)

Devices self-register on boot via `play.replay.com/register`.
The admin dashboard tracks the fleet after registration:

1. Device ships to customer with firmware pointing at `play.replay.com`
2. Customer plugs it in → boots → calls `POST play.replay.com/register`
3. Device appears in admin player list as **Unpaired**
4. Customer enters the pairing code in their app → paired to a screen
5. Admin sees it as **Online** with heartbeat

For v1, no pre-provisioning. The admin tracks what exists, doesn't
create player records. Provisioning (create players before shipping)
is a future phase.

---

## Impersonation (deferred)

```ruby
def impersonate
  user = User.find(params[:id])
  session[:admin_user_id] = Current.user.id
  session[:session_id] = user.sessions.create!.id
  redirect_to app_root_url(subdomain: "app"), allow_other_host: true
end

def stop_impersonating
  admin = User.find(session.delete(:admin_user_id))
  session[:session_id] = admin.sessions.create!.id
  redirect_to admin_root_url(subdomain: "admin"), allow_other_host: true
end
```

Requires security review before implementation. Cross-subdomain
redirects need `allow_other_host: true`.

---

## Build order

### Phase 1 — Foundation
1. Add `admin` boolean to `users` (migration, RED/GREEN)
2. `Admin::BaseController` with `require_admin!`
3. Admin layout (`layouts/admin.html.erb`)
4. Dashboard controller + view (platform stats cards)
5. Add `constraints subdomain: "admin"` to routes
6. Seed: set demo user as admin
7. Specs: `host! "admin.replay.localhost"`, admin auth check, dashboard

### Phase 2 — Core CRUD
8. Accounts index + show (cross-account view)
9. Players index + show (fleet status, pairing history)
10. Screens index + show (cross-account, player status)
11. QR Codes index + show
12. QR Scans index + show

### Phase 3 — Filters + search
13. Player filters: online / offline / unpaired
14. Account search by user email
15. QR Scans filter by date range, qualified/unqualified
16. Pagination on all index pages (pagy, already available)

### Phase 4 — Dependencies (as they ship)
17. Leads index + show (after lead capture plan)
18. Marketing Inquiries index + show + status update (after marketing plan Phase 7)
19. Impressions on dashboard (after metrics plan Phase 1)

### Phase 5 — Advanced (deferred)
20. User impersonation (security review first)
21. Feature flags per account (Flipper gem)
22. Billing / subscription management (Stripe)
23. Audit log (paper_trail gem)
24. CSV/PDF export
25. Bulk operations

---

## What's deferred

- **Impersonation** — needs security review + `allow_other_host` on cross-subdomain redirect
- **Feature flags** — per-account toggles (Flipper gem)
- **Billing** — Stripe integration, plan management
- **Audit log** — paper_trail for admin actions
- **Role-based admin** — admin vs super-admin vs support roles
- **Bulk operations** — mass update accounts, players
- **Export** — CSV/PDF of accounts, leads, scans
- **Pre-provisioning** — admin creates player records before shipping hardware
