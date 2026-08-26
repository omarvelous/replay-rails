# Plan: Migrate Pundit → Action Policy + Multi-Role AccountUser

## Two changes in one plan

1. **Replace Pundit with Action Policy** — cleaner authorization context, no `pundit_user` hacks
2. **Allow multiple roles per user per account** — drop the unique index, role checks become `exists?` queries

These are coupled — Action Policy's authorization context makes
multi-role checking clean, and we're touching all the policies
anyway.

---

## Current state

- Pundit with `pundit_user` returning `Current.account_user`
- `AccountUser` has unique index on `[account_id, user_id]` — one role per user
- Predicates on AccountUser (`can_manage?`, `owner?`)
- 15 policy files, 6 policy specs
- `Current.account_user` attribute set on every request
- `pundit-matchers` with `default_user_alias = :account_user`

### Problems

- A user can only have one role per account (manager can't also be an agent)
- `account_user` passed as Pundit's "user" — policies reach through it to get `user`
- `Current.account_user` materialized on every request (extra query)
- Invite accept flow breaks — no AccountUser exists yet for the invitee

---

## Multi-role AccountUser

### Schema change

Drop the unique index, replace with a unique index on
`[account_id, user_id, role]` — a user can have multiple roles
but not duplicate roles.

```ruby
class AllowMultipleRolesPerAccountUser < ActiveRecord::Migration[8.1]
  def change
    remove_index :account_users, [ :account_id, :user_id ]
    add_index :account_users, [ :account_id, :user_id, :role ], unique: true
  end
end
```

### Model change

```ruby
class AccountUser < ApplicationRecord
  belongs_to :account
  belongs_to :user

  ROLES = %w[owner manager agent].freeze

  validates :role, inclusion: { in: ROLES }
  validates :role, uniqueness: { scope: [ :account_id, :user_id ] }
end
```

No predicates on AccountUser — it's a pure join table.

### Authorizable concern on User

```ruby
# app/models/concerns/authorizable.rb
module Authorizable
  extend ActiveSupport::Concern

  def roles_on(account)
    account_users.where(account: account).pluck(:role)
  end

  def has_role?(role, account)
    account_users.exists?(account: account, role: role)
  end

  def owner_of?(account)
    has_role?("owner", account)
  end

  def can_manage?(account)
    account_users.exists?(account: account, role: %w[owner manager])
  end

  def agent_on?(account)
    has_role?("agent", account)
  end

  def member_of?(account)
    account_users.exists?(account: account)
  end
end
```

### What multi-role enables

A brokerage office manager who is also an active listing agent:

```ruby
AccountUser.create!(account: brokerage, user: morgan, role: "manager")
AccountUser.create!(account: brokerage, user: morgan, role: "agent")

morgan.can_manage?(brokerage)  # true — has manager role
morgan.agent_on?(brokerage)    # true — also has agent role
```

Policies check capabilities, not single roles. A user with both
`manager` and `agent` gets the union of both permission sets.

---

## Action Policy

### Why migrate

| Pundit | Action Policy |
|--------|--------------|
| `pundit_user` returns one object — has to be the user OR the membership | `authorize :user` + `authorize :account` — inject both explicitly |
| Policies get `account_user`, reach through to `user` | Policies get `user` and `account` directly |
| No built-in caching | Caches authorization checks within a request |
| Failure returns generic `NotAuthorizedError` | Failure reasons: `result.reasons.details` for better UX |
| `policy_scope(Model)` | `authorized_scope(Model)` — same concept, cleaner naming |
| `verify_authorized` / `verify_policy_scoped` | Built-in: `verify_authorized` |

### Gem

```ruby
# Gemfile
gem "action_policy"

# Remove
# gem "pundit"
# gem "pundit-matchers" (test group)
```

Action Policy has its own test helpers and matchers built in.

---

## Current model — simplify

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :account

  delegate :user, to: :session, allow_nil: true

  def account
    super || user&.accounts&.first
  end
end
```

- Remove `account_user` attribute
- `account` is a settable attribute with fallback

---

## Authentication concern — simplify

Remove `set_account_user` entirely:

```ruby
def resume_session
  Current.session ||= find_session_by_cookie
  Current.session
end

def start_new_session_for(user)
  user.sessions.create!(...).tap do |session|
    Current.session = session
    cookies.signed.permanent[:session_id] = { ... }
  end
end

# Remove: def set_account_user
```

---

## BaseController

```ruby
module App
  class BaseController < ApplicationController
    include ActionPolicy::Controller
    layout "app"

    authorize :user, through: :current_user
    authorize :account, through: :current_account

    rescue_from ActionPolicy::Unauthorized, with: :handle_unauthorized

    verify_authorized except: :index

    private

      def current_user
        Current.user
      end

      def current_account
        Current.account
      end

      def handle_unauthorized
        redirect_to app_root_path, alert: "You don't have permission to do that."
      end
  end
end


```

`authorize :user` and `authorize :account` inject both into every
policy automatically. No `pundit_user` override needed.

`verify_authorized except: :index` replaces Pundit's
`after_action :verify_authorized`. Index actions use
`authorized_scope` instead.

---

## ApplicationPolicy

```ruby
# app/policies/application_policy.rb
class ApplicationPolicy < ActionPolicy::Base
  authorize :user, :account

  def index?   = true
  def show?    = true
  def create?  = user&.can_manage?(account)
  def new?     = create?
  def update?  = user&.can_manage?(account)
  def edit?    = update?
  def destroy? = user&.can_manage?(account)

  scope_for :relation do |relation|
    relation.all
  end
end
```

Key differences from Pundit:
- `authorize :user, :account` — declares what context policies receive
- `scope_for :relation` replaces `class Scope`
- `user` and `account` are available as methods, not constructor args

---

## Policy migrations (Pundit → Action Policy)

### ListingPolicy

```ruby
class ListingPolicy < ApplicationPolicy
  def show?
    user.can_manage?(account) || owns_listing?
  end

  scope_for :relation do |relation|
    if user.can_manage?(account)
      relation.all
    else
      relation.joins(:listing_agents)
              .where(listing_agents: { agent_id: user.agent_profile&.id })
    end
  end

  private

  def owns_listing?
    record.listing_agents.exists?(agent_id: user.agent_profile&.id)
  end
end
```

### LeadPolicy

```ruby
class LeadPolicy < ApplicationPolicy
  def show?    = user.can_manage?(account) || owns_lead?
  def update?  = user.can_manage?(account) || owns_lead?
  def destroy? = user.can_manage?(account)

  scope_for :relation do |relation|
    if user.can_manage?(account)
      relation.all
    else
      relation.joins(:lead_agents)
              .where(lead_agents: { agent_id: user.agent_profile&.id })
    end
  end

  private

  def owns_lead?
    user.agent_profile && record.current_agent == user.agent_profile
  end
end
```

### AgentPolicy

```ruby
class AgentPolicy < ApplicationPolicy
  def update? = user.can_manage?(account) || own_profile?
  def edit?   = update?

  private

  def own_profile?
    record.user_id == user.id
  end
end
```

### AccountPolicy

```ruby
class AccountPolicy < ApplicationPolicy
  def edit?    = user&.owner_of?(account)
  def update?  = user&.owner_of?(account)
  def destroy? = user&.owner_of?(account)
end
```

### LeadAgentPolicy

```ruby
# Remove file — ApplicationPolicy defaults (can_manage?) are correct
```

### InvitePolicy (for user invites plan)

```ruby
class InvitePolicy < ApplicationPolicy
  def show?
    user.nil? || user.email_address == record.email
  end

  def update?
    user.nil? || user.email_address == record.email
  end

  def create?
    return true if user&.owner_of?(account)
    user&.can_manage?(account) && record.role == "agent"
  end
end
```

`user.nil?` works naturally — unauthenticated invitee, no
`account_user` workaround needed.

### Simple policies (Site, Screen, Playlist, Ad, QrCode, etc.)

```ruby
# All inherit ApplicationPolicy defaults — remove the files
# or keep as empty subclasses for explicitness:
class SitePolicy < ApplicationPolicy; end
```

---

## Controller changes

### `authorize` — same

```ruby
# Pundit
authorize @listing

# Action Policy — identical
authorize! @listing
```

The `!` is Action Policy convention. Also supports `authorize @listing`
without bang if preferred.

### `policy_scope` → `authorized_scope`

```ruby
# Pundit
base = policy_scope(Current.account.listings)

# Action Policy
base = authorized_scope(Current.account.listings)
```

### `policy(@record).edit?` in views → same

```ruby
# Pundit
<% if policy(@listing).edit? %>

# Action Policy
<% if allowed_to?(:edit?, @listing) %>
```

---

## Test changes

### Remove pundit-matchers, use Action Policy testing

Action Policy has built-in RSpec helpers:

```ruby
# Gemfile test group
# Remove: gem "pundit-matchers"
# Action Policy includes its own matchers
```

### Policy spec migration

```ruby
# Before (Pundit)
RSpec.describe ListingPolicy do
  let(:account) { create(:account) }
  let(:listing) { create(:listing, account: account) }

  when "user is owner" do
    let(:account_user) { create(:account_user, account: account, role: "owner") }
    subject { described_class.new(account_user, listing) }

    it { is_expected.to permit_actions(%i[index show create update destroy]) }
  end
end

# After (Action Policy)
RSpec.describe ListingPolicy do
  let(:account) { create(:account) }
  let(:listing) { create(:listing, account: account) }

  when "user is owner" do
    let(:user) { create(:user, account: account, role: "owner") }

    it "permits full CRUD" do
      expect(policy).to be_allowed(:index?)
      expect(policy).to be_allowed(:show?)
      expect(policy).to be_allowed(:create?)
      expect(policy).to be_allowed(:update?)
      expect(policy).to be_allowed(:destroy?)
    end
  end

  when "user is agent" do
    let(:user) { create(:user, account: account, role: "agent") }
    let(:agent) { create(:agent, account: account, user: user) }

    it "forbids create and destroy" do
      expect(policy).not_to be_allowed(:create?)
      expect(policy).not_to be_allowed(:destroy?)
    end

    when "viewing their own listing" do
      before { create(:listing_agent, listing: listing, agent: agent) }

      it "permits show" do
        expect(policy).to be_allowed(:show?)
      end
    end
  end

  private

  def policy
    described_class.new(listing, user: user, account: account)
  end
end
```

Action Policy policies take `(record, **contexts)` — contexts
are the `authorize :user, :account` declarations.

### Authorization spec (request-level)

```ruby
# Same pattern — sign_in, make request, check response
# No changes needed in request specs
```

### Remove pundit support file

```ruby
# Delete spec/support/pundit.rb entirely
```

---

## View changes

```erb
<%# Before (Pundit) %>
<% if policy(@listing).edit? %>
  <%= link_to "Edit", edit_listing_path(@listing) %>
<% end %>

<%# After (Action Policy) %>
<% if allowed_to?(:edit?, @listing) %>
  <%= link_to "Edit", edit_listing_path(@listing) %>
<% end %>
```

`allowed_to?` is Action Policy's view helper, equivalent to
Pundit's `policy(@record).action?`.

---

## Full file inventory

### Files to create
- `app/models/concerns/authorizable.rb`
- Migration: drop unique index, add composite unique index

### Files to modify
- `Gemfile` — swap `pundit` → `action_policy`, remove `pundit-matchers`
- `app/models/user.rb` — `include Authorizable`
- `app/models/account_user.rb` — remove predicates, update uniqueness validation
- `app/models/current.rb` — remove `account_user`, add settable `account`
- `app/controllers/concerns/authentication.rb` — remove `set_account_user`
- `app/controllers/app/base_controller.rb` — Action Policy include + context
- 15 policy files — rewrite to Action Policy base class
- 6 policy spec files — rewrite to Action Policy matchers
- `spec/support/pundit.rb` → delete
- Views with `policy(@record).action?` → `allowed_to?(:action?, @record)`
- `spec/requests/authorization_spec.rb` — no changes (tests HTTP responses)

### Files unchanged
- All app controllers (except BaseController) — `authorize` calls stay
- All request specs (except authorization) — behavior unchanged
- Models, migrations, seeds, mailers — untouched

---

## Build order

### Phase 1 — Multi-role AccountUser
1. Drop unique index, add composite unique index migration (RED/GREEN)
2. Update AccountUser validation — uniqueness on `[account_id, user_id, role]`
3. Remove predicates from AccountUser model + spec

### Phase 2 — Authorizable concern
4. Create `Authorizable` concern with `has_role?`, `roles_on`, `can_manage?`, `owner_of?`, `agent_on?`, `member_of?` (RED/GREEN)
5. `include Authorizable` in User
6. Update user spec

### Phase 3 — Simplify Current + auth
7. Update Current — remove `account_user`, add settable `account` with fallback
8. Update authentication concern — remove `set_account_user`

### Phase 4 — Swap gems
9. Replace `pundit` with `action_policy` in Gemfile
10. Remove `pundit-matchers` from Gemfile
11. Bundle install

### Phase 5 — Rewrite policies
12. Rewrite `ApplicationPolicy` as Action Policy base (RED/GREEN)
13. Rewrite `ListingPolicy` + spec (RED/GREEN)
14. Rewrite `LeadPolicy` + spec (RED/GREEN)
15. Rewrite `AgentPolicy` + spec (RED/GREEN)
16. Rewrite `AccountPolicy` + spec (RED/GREEN)
17. Rewrite `LeadAgentPolicy` + spec (RED/GREEN)
18. Rewrite `InvitePolicy` + spec (RED/GREEN) — with `user.nil?` support
19. Update remaining simple policies (Site, Screen, Ad, Playlist, etc.)

### Phase 6 — Wire up controllers
20. Update `App::BaseController` — Action Policy include + context declarations
21. Update all controllers: `authorize` → `authorize!`, `policy_scope` → `authorized_scope`
22. Run full suite

### Phase 7 — Views
23. Replace `policy(@record).action?` with `allowed_to?(:action?, @record)` in all views
24. Replace `policy(Model).action?` with `allowed_to?(:action?, Model)` for class-level checks

### Phase 8 — Cleanup
25. Delete `spec/support/pundit.rb`
26. Delete `app/policies/lead_agent_policy.rb` (if inheriting defaults is sufficient)
27. Update seeds — add dual-role user (manager + agent)
28. Remove `as` and `"on"` from `RSpec/ContextWording` Prefixes in `.rubocop.yml` — use defaults only (`when`/`with`/`without`)
29. Rename policy spec contexts: `"as an owner"` → `"when user is owner"`, `"on their own listing"` → `"when viewing their own listing"`
30. Full suite green, lint clean
31. Move plan to `.claude/plans/`

---

## What this does NOT change

- **Controller actions** — `authorize!` is the same call, just with a bang
- **Tenant scoping** — `Current.account` still used everywhere
- **Join tables** — ListingAgent, LeadAgent stay as-is (domain data)
- **Admin panel** — Administrate uses `admin?` boolean, unaffected
- **Public controllers** — Go::, Marketing::, Scans — no policies

---

## Dependencies

- **RBAC v3 (done)** — AccountUser, policies, controller wiring exist
- **Blocks user invites** — InvitePolicy with `user.nil?` support
