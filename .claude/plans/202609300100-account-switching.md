# Plan: Account Switching

**Created:** 2026-09-29
**Status:** Complete
**Branch:** `account-switching`

## Problem

`Current.account` always returns `user.accounts.first`. Users who
belong to multiple accounts (admins, agents at multiple brokerages)
are stuck on whichever account comes first. No way to switch.

## Design

### How it works

1. Selected account ID stored in the Rails session (`session[:account_id]`)
2. `Current.account` checks session first, falls back to first account
3. `POST /account/switch` validates access and updates the session
4. Sidebar shows current account name with a dropdown to switch

### Current model changes

```ruby
# app/models/current.rb
class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :account
  attribute :account_user

  delegate :user, to: :session, allow_nil: true

  def account
    super || resolve_account
  end

  def account_user
    super || user&.account_users&.find_by(account: account)
  end

  private

  def resolve_account
    # Check session-stored selection first
    if session&.respond_to?(:[]) && (stored_id = session[:account_id])
      user&.accounts&.find_by(id: stored_id)
    end || user&.accounts&.first
  end
end
```

Wait — `Current.session` is the `Session` model record, not the
Rails `session` hash. The Rails session is on the controller. So
the account selection needs to flow through the controller.

### Better approach — controller sets Current.account

```ruby
# app/controllers/concerns/authentication.rb
def resume_session
  Current.session ||= find_session_by_cookie
  Current.account = resolve_current_account if Current.session
  Current.session
end

def resolve_current_account
  user = Current.user
  return unless user

  if session[:account_id]
    # Validate user still has access
    user.accounts.find_by(id: session[:account_id]) || user.accounts.first
  else
    user.accounts.first
  end
end
```

`Current.account` is set explicitly during session resume, reading
from the Rails `session[:account_id]`. Falls back to first account
if the stored ID is invalid (account deleted, user removed).

### Switching controller

Nested under accounts: `POST /account/switch`

```ruby
# app/controllers/app/accounts/switches_controller.rb
module App
  module Accounts
    class SwitchesController < App::BaseController
      def create
        accounts = authorized_scope(Account.all)
        account = accounts.find_by_param!(params[:account_id])
        session[:account_id] = account.id
        redirect_to app_root_path, notice: "Switched to #{account.name}"
      end
    end
  end
end
```

Route:
```ruby
resource :account, only: [] do
  resource :switch, only: :create, module: :accounts
end
```

### UI — sidebar account switcher

In the sidebar header, show the current account name. If the user
has multiple accounts, show a dropdown:

```erb
<% if current_user.accounts.count > 1 %>
  <select onchange="this.form.submit()" form="account-switch">
    <% current_user.accounts.each do |account| %>
      <option value="<%= account.to_param %>"
              <%= "selected" if account == current_account %>>
        <%= account.name %>
      </option>
    <% end %>
  </select>
  <form id="account-switch" action="<%= account_switch_path %>" method="post">
    <%= hidden_field_tag :authenticity_token, form_authenticity_token %>
    <input type="hidden" name="account_id" id="account-switch-value">
  </form>
<% end %>
```

Or a simpler dropdown menu with links/buttons per account.

### Policy-scoped available accounts

`AccountPolicy` gets a `relation_scope` that returns accounts
the user can access. Admins see all accounts.

```ruby
# app/policies/account_policy.rb
class AccountPolicy < ApplicationPolicy
  def update?  = owner?
  def edit?    = update?
  def destroy? = owner?
  def switch?  = true  # any member can switch to their own accounts

  scope_for :active_record_relation do |relation|
    if user.admin?
      relation.order(:name)
    else
      relation.where(id: user.account_ids).order(:name)
    end
  end
end
```

The switcher uses `authorized_scope(Account.all)` to get the
list, which flows through the policy scope.

Admin switching should log the switch in PaperTrail or an audit
log for accountability.

## Depends on

- Account `name` column (from MVP readiness plan — needed for the
  switcher to show meaningful names)

## Execution

### Step 1 — Authentication sets Current.account from session (TDD)
- **RED:** Spec that changing `session[:account_id]` changes `current_account`
- **GREEN:** Update `resume_session` to resolve account from session

### Step 2 — AccountPolicy scope (TDD)
- **RED:** Policy spec for `relation_scope` — users see their accounts, admins see all
- **GREEN:** Add `scope_for :active_record_relation` to AccountPolicy

### Step 3 — Account switch controller (TDD)
- **RED:** Request spec for `POST /account/switch` — switches account, rejects unauthorized
- **GREEN:** `App::Accounts::SwitchesController` uses `authorized_scope(Account.all)`

### Step 4 — Sidebar account switcher
- Add account name + dropdown to app sidebar
- Uses `authorized_scope(Account.all)` for the list
- Only shows dropdown when multiple accounts available

### Step 5 — Admin audit logging
- Log admin account switches via PaperTrail or dedicated audit entry

### Step 5 — Ship
- `make lint`, `make test`
- Push, create PR

## Current model simplification

With `Current.account` set explicitly by the controller, the
`Current` model becomes simpler:

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :account

  delegate :user, to: :session, allow_nil: true

  def account_user
    user&.account_users&.find_by(account: account)
  end
end
```

No more `resolve_account` fallback logic in the model — the
controller owns account resolution.
