# Plan: Single AccountUser per Membership + Current.account_user

## Context

`AccountUser` is a membership record — one per user per account.
A real estate agent at three brokerages has three memberships.
The role (owner/manager/agent) is an attribute on that membership.

Currently the schema allows multiple `AccountUser` records per
user-account pair (one per role), but in practice this never
happens — seeds and invite flow always create one. The unique
index is on `(account_id, user_id, role)` instead of
`(account_id, user_id)`.

This prevents `Current.account_user` from existing, forcing every
authorization check to query the database.

---

## What Changes

| Layer | Before | After |
|-------|--------|-------|
| **Schema** | Unique on `(account_id, user_id, role)` | Unique on `(account_id, user_id)` |
| **AccountUser** | Multiple records per pair possible | One record per pair, enforced |
| **Current** | `session`, `account`, `user` | + `account_user` |
| **Authentication** | Sets `Current.session` → derives user/account | Also sets `Current.account_user` |
| **Authorizable** | Each method does SQL query | `at_least?` on cached record |
| **Policies** | `user.can_manage?(account)` | `account_user&.at_least?("manager")` |
| **BaseController** | `authorize :user, :account` | + `authorize :account_user` |

---

## Step 1 — AccountUser: add `at_least?`, change uniqueness

**File:** `app/models/account_user.rb`

```ruby
class AccountUser < ApplicationRecord
  include PublicIdentifiable
  has_paper_trail

  ROLES = %w[owner manager agent].freeze
  ROLE_HIERARCHY = { "owner" => 0, "manager" => 1, "agent" => 2 }.freeze

  belongs_to :account
  belongs_to :user

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :account_id }

  before_destroy :ensure_not_last_owner

  def at_least?(required_role)
    ROLE_HIERARCHY[role] <= ROLE_HIERARCHY[required_role]
  end

  private

    def ensure_not_last_owner
      return unless role == "owner"
      if account.account_users.where(role: "owner").count <= 1
        errors.add(:base, "Cannot remove the last owner")
        throw(:abort)
      end
    end
end
```

**Migration:**

```ruby
class ConsolidateAccountUserUniqueness < ActiveRecord::Migration[8.1]
  def change
    remove_index :account_users, [:account_id, :user_id, :role]
    add_index :account_users, [:account_id, :user_id], unique: true
  end
end
```

---

## Step 2 — Current: add account_user attribute

**File:** `app/models/current.rb`

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :account
  attribute :account_user

  delegate :user, to: :session, allow_nil: true

  def account
    super || user&.accounts&.first
  end

  def account_user
    super || user&.account_users&.find_by(account: account)
  end
end
```

The `account_user` lazy-loads from user + account if not explicitly
set. Once loaded, it's cached for the rest of the request by
`CurrentAttributes`.

---

## Step 3 — Authentication: set Current.account_user on resume

**File:** `app/controllers/concerns/authentication.rb`

No change needed — `Current.account_user` is lazy-loaded from
`Current.user` + `Current.account` via the method override in
Step 2. The first time any code accesses `Current.account_user`,
it fires one query and caches for the rest of the request.

If we want to be explicit (one query on session resume instead
of lazy):

```ruby
def resume_session
  Current.session ||= find_session_by_cookie
  Current.account_user = Current.user&.account_users&.find_by(account: Current.account) if Current.session
  Current.session
end
```

Either approach works. Lazy is simpler, explicit is one less
surprise.

---

## Step 4 — Authorizable: simplify with membership_on

**File:** `app/models/concerns/authorizable.rb`

```ruby
module Authorizable
  extend ActiveSupport::Concern

  def membership_on(account)
    account_users.find_by(account: account)
  end

  def member_of?(account)
    membership_on(account).present?
  end

  def owner_of?(account)
    membership_on(account)&.role == "owner"
  end

  def can_manage?(account)
    membership_on(account)&.at_least?("manager") || false
  end
end
```

These methods exist for contexts without `Current` (background
jobs, console, specs). In controller context, policies use
`account_user` directly — no User methods needed.

---

## Step 5 — BaseController: require membership + auth context

**File:** `app/controllers/app/base_controller.rb`

```ruby
module App
  class BaseController < ApplicationController
    include ActionPolicy::Controller
    layout "app"

    before_action :require_membership

    authorize :user, through: :current_user
    authorize :account, through: :current_account
    authorize :account_user, through: :current_account_user

    # ...

    private

      def current_account_user
        Current.account_user
      end

      def require_membership
        return if Current.account_user.present?
        redirect_to app_root_path, alert: "You don't have access to this account."
      end
  end
end
```

`require_membership` runs after `require_authentication` (inherited
from ApplicationController). If the authenticated user has no
membership on the current account, they're redirected. This means
`account_user` is always present in policies — no nil guards.

---

## Step 6 — Update policies to use account_user

All policies gain access to `account_user` alongside `user` and
`account`. Migration path: replace `user.can_manage?(account)`
with `account_user&.at_least?("manager")`.

**File:** `app/policies/application_policy.rb`

```ruby
class ApplicationPolicy < ActionPolicy::Base
  authorize :user, :account, :account_user

  def index?   = true
  def show?    = true
  def create?  = account_user.at_least?("manager")
  def update?  = account_user.at_least?("manager")
  def destroy? = account_user.at_least?("manager")

  # ...
end
```

No `&.` safe navigation — `require_membership` in BaseController
guarantees `account_user` is present. No `optional:` — it's
required in the app context.

**Files to update:**

| Policy | Before | After |
|--------|--------|-------|
| `ApplicationPolicy` | `user&.can_manage?(account)` | `account_user.at_least?("manager")` |
| `AccountPolicy` | `user&.owner_of?(account)` | `account_user.role == "owner"` |
| `AgentPolicy` | `user.can_manage?(account)` | `account_user.at_least?("manager")` |
| `InvitePolicy` | `user&.owner_of?` / `can_manage?` | `account_user.role == "owner"` / `at_least?("manager")` |
| `LeadPolicy` | `user.can_manage?(account)` | `account_user.at_least?("manager")` |
| `ListingPolicy` | `user.can_manage?(account)` | `account_user.at_least?("manager")` |
| `UserPolicy` | `user&.can_manage?(account)` | `account_user.at_least?("manager")` |
| `AccountUserPolicy` | `user&.can_manage?(account)` | `account_user.at_least?("manager")` |

Agent-specific checks (`owns_listing?`, `owns_lead?`) stay on the
User model — they check `user.agent_profile`, not roles.

---

## Step 7 — Update AccountUsersController (role management)

The `create` action currently adds a role. With single-record
membership, it should **change** the role instead:

```ruby
# Before: Creates a new AccountUser record
AccountUser.create!(account: Current.account, user: @user, role: params[:role])

# After: Updates the existing membership's role
@account_user = @user.account_users.find_by!(account: Current.account)
@account_user.update!(role: params[:role])
```

The `destroy` action currently removes a role record. With single
record, destroying removes the user from the account entirely.
This is the correct semantic — "remove this user from the account."

---

## Step 8 — Update specs

### Model specs

- `AccountUser`: update uniqueness test from `scope: [:account_id, :user_id]` (role-based) to `scope: :account_id` (user-based)
- Add specs for `at_least?`
- `Current`: add spec for `account_user` lazy loading

### Policy specs

- Update all policy specs to pass `account_user:` in context
- Verify `at_least?` hierarchy: owner passes manager checks,
  manager passes agent checks, agent fails manager checks

### Request specs

- Verify `current_account_user` is available in controllers

---

## Build Order (TDD)

```
1. RED:  AccountUser#at_least? spec
2. GREEN: Add at_least? + ROLE_HIERARCHY
3. COMMIT

4. Migration: change unique index
5. Update AccountUser uniqueness validation
6. COMMIT

7. Add Current.account_user attribute
8. Add current_account_user to BaseController
9. Add authorize :account_user to BaseController
10. COMMIT

11. RED:  Policy specs with account_user context
12. GREEN: Update all 8 policy files
13. COMMIT

14. Update Authorizable concern
15. Update AccountUsersController
16. COMMIT

17. Update remaining specs
18. COMMIT
```

---

## Verification

1. `make test` — green after each step
2. Login as owner → can manage everything
3. Login as manager → can manage content, can't manage account
4. Login as agent → can only see own listings/leads
5. `Current.account_user` is set and cached per request
6. No SQL queries for role checks after session resume
7. Multi-account user can switch accounts and get correct role

---

## Files Changed

| Category | Files | Count |
|----------|-------|-------|
| Models | `account_user.rb`, `current.rb`, `authorizable.rb` | 3 |
| Migration | `consolidate_account_user_uniqueness.rb` | 1 |
| Controller | `app/base_controller.rb` | 1 |
| Policies | 8 policy files | 8 |
| Specs | Model + policy + request specs | ~10 |
| **Total** | | **~23** |

---

## What This Does NOT Change

- Multi-account membership — unchanged
- `acts_as_tenant` — unchanged
- Invite flow — still creates one AccountUser
- Admin panel — unchanged (operates without tenant)
- API auth — unchanged (token-based, no roles)
- Player auth — unchanged (no roles)
