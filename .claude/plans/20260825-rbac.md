# Plan: RBAC v3 (AccountUser + Pundit)

## Current state

- `User belongs_to :account` — one user, one account, no multi-tenancy flexibility
- `admin` boolean on User — gates internal Administrate panel
- No authorization within the app — any logged-in user can CRUD everything
- `Current.account` delegates through `Current.user.account`
- `Agent belongs_to :user, optional: true` — agents can exist without a login
- 20+ controllers reference `Current.account` for tenant scoping

---

## Goals

1. Users can belong to multiple accounts (via `AccountUser` join model)
2. Three roles per membership: **owner**, **manager**, **agent**
3. Agents can only see their own listings and leads
4. Only owners can manage billing and delete the account
5. Keep the internal `admin` boolean separate — system-level, not tenant-level
6. Use Pundit for per-action and per-record authorization
7. Minimize blast radius — `Current.account` keeps working everywhere

---

## The AccountUser model

The role lives on the join between User and Account, not on the User.
This is the standard pattern for multi-tenant SaaS (GitHub orgs,
Slack workspaces, Linear teams).

```
User ──has_many──▶ AccountUser ◀──has_many── Account
                  (role, joined_at)
```

A user can be an `owner` at one brokerage and an `agent` at another.
The `admin` boolean on User stays separate — a RePlay staff member
can be `admin: true` AND have an `AccountUser` as `manager` in a
demo account.

---

## Roles

| Role | Who | Access |
|------|-----|--------|
| **Owner** | Brokerage principal. One per account (initially). | Everything. Billing, team management, delete account. |
| **Manager** | Office manager, marketing lead. | CRUD all resources. Invite agents. Manage all leads. Cannot access billing or delete account. |
| **Agent** | Individual agent at the brokerage. | View/edit their own listings and leads. View screens, playlists, ads (read-only). Cannot create or delete shared resources. |

### What "their own" means for agents

- **Listings** — listings where the agent has a `ListingAgent` record
- **Leads** — leads where the agent is the `current_agent` (most recent `LeadAgent`)
- **Ads** — ads built from their listings (through `Ads::ListingAd`)
- **Everything else** — read-only (screens, playlists, sites, QR codes)

---

## Schema changes

### AccountUser migration

```ruby
class CreateAccountUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :account_users do |t|
      t.timestamps
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: "agent"
    end
    add_index :account_users, [ :account_id, :user_id ], unique: true
  end
end
```

### Backfill + drop column

```ruby
class BackfillAccountUsersAndDropAccountIdFromUsers < ActiveRecord::Migration[8.1]
  def up
    # Backfill: create AccountUser for every existing User
    User.find_each do |user|
      AccountUser.create!(
        account_id: user.read_attribute(:account_id),
        user: user,
        role: "owner"
      )
    end

    remove_reference :users, :account
  end

  def down
    add_reference :users, :account, foreign_key: true

    AccountUser.find_each do |au|
      User.where(id: au.user_id).update_all(account_id: au.account_id)
    end
  end
end
```

Existing users all become `owner` — they created the account, they
own it. New roles are assigned via invites.

---

## Model changes

### AccountUser

```ruby
# app/models/account_user.rb
class AccountUser < ApplicationRecord
  belongs_to :account
  belongs_to :user

  ROLES = %w[owner manager agent].freeze

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :account_id }

  def owner?      = role == "owner"
  def manager?    = role == "manager"
  def agent_role? = role == "agent"

  def can_manage?
    owner? || manager?
  end
end
```

### User (changes)

```ruby
class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :account_users, dependent: :destroy
  has_many :accounts, through: :account_users

  # admin boolean stays — system-level, not tenant-level

  # Agent profile link (for agent-role users)
  has_one :agent_profile, class_name: "Agent", foreign_key: :user_id

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email_address, presence: true, uniqueness: true
  validates :phone, presence: true
end
```

`belongs_to :account` is removed. No role on User — roles live
on AccountUser.

### Account (changes)

```ruby
class Account < ApplicationRecord
  has_many :account_users, dependent: :destroy
  has_many :users, through: :account_users

  # everything else unchanged
  has_many :sites, dependent: :destroy
  has_many :screens, through: :sites
  has_many :listings, dependent: :destroy
  # ...
end
```

### Current (changes)

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :account_user  # set at login / account switch

  delegate :user, to: :session, allow_nil: true
  delegate :account, to: :account_user, allow_nil: true
end
```

`Current.account` now comes from `Current.account_user.account`
instead of `Current.user.account`. Every controller that uses
`Current.account` keeps working — no changes needed.

`Current.account_user` gives you the role context:
`Current.account_user.can_manage?`, `Current.account_user.owner?`, etc.

---

## Authentication flow changes

### Login (single account)

For now, most users have one account. Login sets `Current.account_user`
to their only membership:

```ruby
# app/controllers/concerns/authentication.rb (addition)

def resume_session
  # existing session resume...
  if Current.user
    Current.account_user = Current.user.account_users.first
  end
end

def start_new_session_for(user)
  # existing session creation...
  Current.account_user = user.account_users.first
end
```

### Account switching (future)

When a user has multiple accounts, they need an account switcher.
For now, default to the first account. The switcher is a future
enhancement — store the selected account_user_id in the session
cookie or a separate cookie:

```ruby
# Future: account switcher
Current.account_user = Current.user.account_users.find_by(account_id: selected_account_id)
```

This is not in scope for this plan but the model supports it.

---

## Pundit setup

### Gem

```ruby
# Gemfile
gem "pundit"

# Gemfile (test group)
gem "pundit-matchers", "~> 4.0"
```

### BaseController integration

```ruby
# app/controllers/app/base_controller.rb
module App
  class BaseController < ApplicationController
    include Pundit::Authorization
    layout "app"

    after_action :verify_authorized, except: :index
    after_action :verify_policy_scoped, only: :index

    rescue_from Pundit::NotAuthorizedError, with: :handle_unauthorized

    private

      def handle_unauthorized
        redirect_to app_root_path, alert: "You don't have permission to do that."
      end

      def pundit_user
        Current.account_user
      end
  end
end
```

`pundit_user` returns the `AccountUser` — policies receive the
membership (with role) as the "user" context, not the bare User.
This means policies can check `user.can_manage?` where `user`
is actually the AccountUser.

---

## Base policy

```ruby
# app/policies/application_policy.rb
class ApplicationPolicy
  attr_reader :account_user, :record

  def initialize(account_user, record)
    @account_user = account_user
    @record = record
  end

  # Defaults: managers+ can do everything, agents can't mutate
  def index?   = true
  def show?    = true
  def create?  = account_user.can_manage?
  def new?     = create?
  def update?  = account_user.can_manage?
  def edit?    = update?
  def destroy? = account_user.can_manage?

  class Scope
    def initialize(account_user, scope)
      @account_user = account_user
      @scope = scope
    end

    def resolve = scope.all

    private

    attr_reader :account_user, :scope
  end
end
```

Default: everyone can view, only managers+ can mutate. Read access
is open because agents need to browse screens, playlists, ads for
context. Policies override where scoping or restrictions are needed.

---

## Policy classes

### ListingPolicy

```ruby
class ListingPolicy < ApplicationPolicy
  def show?
    account_user.can_manage? || owns_listing?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if account_user.can_manage?
        scope.all
      else
        scope.joins(:listing_agents)
             .where(listing_agents: { agent_id: agent_id })
      end
    end

    private

    def agent_id
      account_user.user.agent_profile&.id
    end
  end

  private

  def owns_listing?
    record.listing_agents.exists?(agent_id: account_user.user.agent_profile&.id)
  end
end
```

### LeadPolicy

```ruby
class LeadPolicy < ApplicationPolicy
  def show?    = account_user.can_manage? || owns_lead?
  def update?  = account_user.can_manage? || owns_lead?
  def destroy? = account_user.can_manage?

  class Scope < ApplicationPolicy::Scope
    def resolve
      if account_user.can_manage?
        scope.all
      else
        scope.joins(:lead_agents)
             .where(lead_agents: { agent_id: agent_id })
      end
    end

    private

    def agent_id
      account_user.user.agent_profile&.id
    end
  end

  private

  def owns_lead?
    record.current_agent == account_user.user.agent_profile
  end
end
```

### AgentPolicy

```ruby
class AgentPolicy < ApplicationPolicy
  def update? = account_user.can_manage? || own_profile?
  def edit?   = update?

  private

  def own_profile?
    record.user_id == account_user.user_id
  end
end
```

### LeadAgentPolicy

```ruby
class LeadAgentPolicy < ApplicationPolicy
  def new?    = account_user.can_manage?
  def create? = account_user.can_manage?
end
```

### AccountPolicy

```ruby
class AccountPolicy < ApplicationPolicy
  def edit?    = account_user.owner?
  def update?  = account_user.owner?
  def destroy? = account_user.owner?
end
```

### Simple policies (Site, Screen, Playlist, Ad)

All use `ApplicationPolicy` defaults — read for all, write for
managers+. No custom policy file needed unless you want to be
explicit:

```ruby
# app/policies/site_policy.rb
class SitePolicy < ApplicationPolicy; end
```

---

## Controller usage

### ListingsController (example)

```ruby
module App
  class ListingsController < App::BaseController
    def index
      base = policy_scope(Current.account.listings)
      base = base.search(params[:q]) if params[:q].present?
      base = base.by_status(params[:status]) if params[:status].present?
      @pagy, @listings = pagy(base.order(created_at: :desc))
    end

    def show
      @listing = Current.account.listings.find(params[:id])
      authorize @listing
    end

    def new
      @listing = Current.account.listings.build
      authorize @listing
    end

    def create
      @listing = Current.account.listings.build(listing_params)
      authorize @listing
      # ...
    end

    def destroy
      @listing = Current.account.listings.find(params[:id])
      authorize @listing
      # ...
    end
  end
end
```

`Current.account` still provides tenant scoping. Pundit provides
authorization on top. No controller changes for the tenant scoping
pattern — only adding `authorize` and `policy_scope` calls.

---

## View authorization

```erb
<%# Show button only if policy allows %>
<% if policy(@listing).edit? %>
  <%= link_to "Edit", edit_listing_path(@listing), class: "..." %>
<% end %>

<%# Sidebar: owner-only sections %>
<% if policy(Current.account).edit? %>
  <%# Team, Billing, Account settings %>
<% end %>

<%# Create buttons %>
<% if policy(Listing).create? %>
  <%= link_to "New listing", new_listing_path, class: "..." %>
<% end %>
```

---

## Permission matrix

| Resource | Agent | Manager | Owner |
|----------|:-----:|:-------:|:-----:|
| **Sites** | view | CRUD | CRUD |
| **Screens** | view | CRUD | CRUD |
| **Listings** | view/show own | CRUD all | CRUD all |
| **Agents** | view, edit self | CRUD | CRUD |
| **Ads** | view | CRUD | CRUD |
| **Playlists** | view | CRUD | CRUD |
| **QR Codes** | view | view | view |
| **Leads** | view/update own | CRUD all | CRUD all |
| **Lead assignment** | — | assign/reassign | assign/reassign |
| **Team (users)** | — | invite agents | invite all, remove |
| **Billing** | — | — | manage |
| **Account settings** | — | — | edit, delete |

---

## Factory changes

```ruby
# spec/factories/account_users.rb
FactoryBot.define do
  factory :account_user do
    account
    user
    role { "owner" }

    trait :manager do
      role { "manager" }
    end

    trait :agent do
      role { "agent" }
    end
  end
end

# spec/factories/users.rb (updated)
FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    phone      { Faker::PhoneNumber.cell_phone_in_e164 }
    password   { "password123" }

    # Convenience: auto-create an account + membership
    transient do
      account { nil }
      role { "owner" }
    end

    after(:create) do |user, evaluator|
      acct = evaluator.account || create(:account)
      create(:account_user, user: user, account: acct, role: evaluator.role)
    end
  end
end
```

Existing specs that do `create(:user, account: account)` keep
working — the transient attribute creates the AccountUser behind
the scenes. But `user.account` no longer works directly — use
`user.accounts.first` or rely on `Current.account`.

### Test helper update

```ruby
# spec/support/authentication.rb
def sign_in(user, account: nil)
  account_user = if account
                   user.account_users.find_by!(account: account)
                 else
                   user.account_users.first!
                 end

  session = user.sessions.create!(user_agent: "RSpec", ip_address: "127.0.0.1")
  jar = ActionDispatch::Request.new(Rails.application.env_config.deep_dup).cookie_jar
  jar.signed[:session_id] = { value: session.id, httponly: true }
  cookies[:session_id] = jar[:session_id]

  # Set account context for the test
  Current.account_user = account_user
end
```

---

## Seed updates

```ruby
# db/seeds.rb
demo_account = Account.first_or_create!

# Owner
demo_user = User.find_or_create_by!(email_address: "demo@example.com") do |u|
  u.first_name = "Demo"
  u.last_name  = "Owner"
  u.phone      = "+12125550001"
  u.password   = "password"
end
demo_user.update!(admin: true) unless demo_user.admin?
AccountUser.find_or_create_by!(user: demo_user, account: demo_account) do |au|
  au.role = "owner"
end

# Manager
manager_user = User.find_or_create_by!(email_address: "manager@example.com") do |u|
  u.first_name = "Morgan"
  u.last_name  = "Manager"
  u.phone      = "+12125550002"
  u.password   = "password"
end
AccountUser.find_or_create_by!(user: manager_user, account: demo_account) do |au|
  au.role = "manager"
end

# Agent (linked to Agent record)
jane_user = User.find_or_create_by!(email_address: "jane.broker@example.com") do |u|
  u.first_name = "Jane"
  u.last_name  = "Broker"
  u.phone      = "+12125550003"
  u.password   = "password"
end
AccountUser.find_or_create_by!(user: jane_user, account: demo_account) do |au|
  au.role = "agent"
end

jane_agent = Agent.find_by(email: "jane.broker@example.com")
jane_agent&.update!(user: jane_user)

demo_account = demo_user.accounts.first  # for subsequent seed sections
```

Three demo logins:
- `demo@example.com` / `password` — owner
- `manager@example.com` / `password` — manager
- `jane.broker@example.com` / `password` — agent

---

## Blast radius

The `User belongs_to :account` → `User has_many :accounts through: :account_users`
change touches several layers. Here's the impact:

| Layer | Change needed | Scope |
|-------|--------------|-------|
| `Current.account` | Delegate to `account_user` instead of `user` | 1 file |
| `User` model | Remove `belongs_to :account`, add `has_many :account_users` | 1 file |
| `Account` model | Change `has_many :users` to through | 1 file |
| Authentication concern | Set `Current.account_user` on login | 1 file |
| `users` table | Drop `account_id` column | 1 migration |
| Controllers using `Current.account` | **No changes** — `Current.account` keeps working | 0 files |
| Controllers using `Current.user.account` | None exist (all go through `Current.account`) | 0 files |
| `account.users` references | Update 4 files (mailer, accounts controller, agents form, admin) | 4 files |
| Factory for `:user` | Transient `account` + `role`, auto-creates AccountUser | 1 file |
| Seeds | Create AccountUser records instead of `User.create!(account:)` | 1 file |
| Test sign_in helper | Set `Current.account_user` | 1 file |
| Existing request specs | Most keep working if factory handles the join. May need `role:` transient. | Review |

**Controllers are untouched.** That's the key — `Current.account` keeps
delegating correctly, just from a different source.

---

## What this does NOT do

- **Account switcher UI** — model supports multi-account, but the UI defaults to first account. Switcher is a future enhancement.
- **Row-level security** — scoping is in Ruby via Pundit, not Postgres RLS.
- **Custom permissions** — three fixed roles, no per-resource overrides.
- **Multiple owners** — one owner per account initially.
- **Role history** — no audit of role changes. Add with audit trail (Tier 3).
- **API authorization** — player API uses token auth, not roles. Orthogonal.
- **Pundit on admin controllers** — Administrate uses `admin?` boolean. Pundit stays in `App::`.

---

## Build order

### Phase 1 — AccountUser model
1. Create `account_users` table with role column (RED/GREEN)
2. `AccountUser` model with role validation and predicates (RED/GREEN)
3. Factory for `:account_user` with role traits

### Phase 2 — Migrate User-Account relationship
4. Update `User` — remove `belongs_to :account`, add `has_many :account_users` (RED/GREEN)
5. Update `Account` — `has_many :users, through: :account_users`
6. Update `Current` — add `account_user` attribute, delegate `account` to it
7. Update authentication concern — set `Current.account_user` on login
8. Data migration: backfill `account_users` from `users.account_id`, drop column
9. Update user factory — transient `account` + `role`, auto-create AccountUser
10. Update test sign_in helper
11. Fix `account.users` references (4 files)
12. Run full suite — fix any breakage

### Phase 3 — Pundit setup
13. Add `pundit` + `pundit-matchers` gems
14. `ApplicationPolicy` with defaults (RED/GREEN)
15. Include `Pundit::Authorization` in `App::BaseController`
16. `rescue_from Pundit::NotAuthorizedError`

### Phase 4 — Policies (TDD per model)
17. `ListingPolicy` + spec — agent scoping via `Scope` (RED/GREEN)
18. `LeadPolicy` + spec — agent scoping via `Scope` (RED/GREEN)
19. `AgentPolicy` + spec — agents edit own profile (RED/GREEN)
20. `LeadAgentPolicy` + spec — managers only (RED/GREEN)
21. `SitePolicy` + spec (RED/GREEN)
22. `ScreenPolicy` + spec (RED/GREEN)
23. `AdPolicy` + spec (RED/GREEN)
24. `PlaylistPolicy` + spec (RED/GREEN)
25. `AccountPolicy` + spec — owner only (RED/GREEN)

### Phase 5 — Wire up controllers
26. Add `authorize` and `policy_scope` calls to every app controller
27. Update existing request specs to pass with `verify_authorized`
28. Test each role against each controller action

### Phase 6 — UI
29. View authorization: `policy(@record).edit?` on buttons/links
30. Sidebar: conditionally show create actions and owner-only sections
31. Role badge on user display in sidebar

### Phase 7 — Seeds + integration
32. Update seeds — three demo users (owner, manager, agent)
33. End-to-end: agent logs in, sees own listings/leads, can't create/delete
34. End-to-end: manager logs in, full CRUD, can't access billing
35. End-to-end: owner logs in, full access
36. Full suite green, coverage maintained

---

## What changed from v2

- **AccountUser replaces role column on User** — role lives on the join between User and Account. Supports multi-account users.
- **`Current.account_user`** — new primary context. Replaces `Current.user.role` with `Current.account_user.can_manage?`. `Current.account` delegates through it.
- **`pundit_user` returns AccountUser** — policies receive the membership context, not the bare User. `account_user.can_manage?` in policies.
- **Data migration** — backfill AccountUser from `users.account_id`, then drop the column. Two-step migration.
- **Factory transients** — `create(:user, account: account, role: "agent")` works transparently via `after(:create)` hook.
- **Zero controller changes for tenant scoping** — `Current.account` keeps working, just delegated differently.

---

## Dependencies

- **User invites** — creates an AccountUser with a role. Plan and build after Phase 2.
- **Billing/subscriptions** — gated by `AccountPolicy`. Build after RBAC.
- **Notifications** — role determines who gets notified. Build after RBAC.
- **Account switcher** — model supports it. UI is a future enhancement.
