# Plan: Adopt current_user / current_account Controller Pattern

## Problem

Ahoy's `BaseController` inherits from `ApplicationController` but
skips all before/after callbacks. This strips `resume_session`,
so `Current.user` and `Current.account` are nil when Ahoy processes
`/ahoy/events`. The result: events and visits have no user or
account association.

The current workaround reads session cookies directly in
`Ahoy.user_method` and the Store — duplicating session resolution
logic in multiple places.

## Root Cause

`Current.user` depends on `resume_session` running as a
before_action. This is a "push" model — auth state is pushed into
`Current` by a callback. If the callback doesn't run (Ahoy skips
it), the state is missing.

Devise uses a "pull" model — `current_user` is a method that
reads the cookie on demand and caches the result. Any controller
can call it at any time, no before_action dependency.

## Solution

Add `current_user` and `current_account` as on-demand methods in
the `Authentication` concern. They call `resume_session` lazily
and read from `Current` — reusing the existing session resolution
logic with no duplication. `Current.session ||=` makes repeated
calls safe (cookie is read once).

### Authentication Concern

```ruby
# app/controllers/concerns/authentication.rb
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :resume_session
    before_action :require_authentication
    helper_method :authenticated?, :current_user, :current_account
  end

  # ... existing methods ...

  private

    def current_user
      resume_session
      Current.user
    end

    def current_account
      resume_session
      Current.account
    end
end
```

`current_user` and `current_account` trigger `resume_session` on
demand, which sets `Current.session` from the cookie (if not
already set). Then they read from `Current` — the same path as
the existing before_action, just callable at any time.

### Ahoy Configuration

```ruby
# config/initializers/ahoy.rb

# No custom user_method needed — Ahoy's default calls
# controller.current_user, which is defined by Authentication.

class Ahoy::Store < Ahoy::DatabaseStore
  def track_visit(data)
    data[:account_id] = controller&.try(:current_account)&.id
    super(data)
  end

  def track_event(data)
    props = (data[:properties] || {}).with_indifferent_access
    data[:account_id] = controller&.try(:current_account)&.id || props[:account_id]
    super(data)
  end
end

Ahoy.exclude_method = ->(controller, request) { request&.subdomain == "admin" }

Ahoy.api = true
Ahoy.visit_duration = 4.hours
Ahoy.cookie_domain = :all
Ahoy.mask_ips = true
Ahoy.geocode = false
Ahoy.server_side_visits = :when_needed
```

### Why This Works for Ahoy

Ahoy::BaseController inherits from ApplicationController which
includes Authentication. Even though Ahoy skips the before_action
`:resume_session`, the `current_user` method is still available
as a regular method. When Ahoy calls `controller.current_user`
(its default user_method), it triggers `resume_session` lazily,
sets `Current.session`, and returns the user. Same for
`current_account` in the Store.

### What Changes

| Before | After |
|--------|-------|
| `Current.user` only works after callback | `current_user` triggers session on demand |
| Custom `Ahoy.user_method` lambda | Default `controller.current_user` works |
| Store reads cookies directly | Store calls `controller.current_account` |
| Session resolution logic duplicated | Single path through `resume_session` |

### What Doesn't Change

- `resume_session` logic unchanged
- `Current.session` / `Current.user` / `Current.account` unchanged
- `before_action :resume_session` still runs for app controllers
- `ahoy.authenticate(user)` still called at sign-in
- Views using `Current.user` or `Current.account` unchanged
- No changes to `Current` model

## Build Order

1. Add `current_user` and `current_account` to Authentication concern
2. Add to `helper_method` declaration
3. Simplify Ahoy initializer — remove custom `user_method` lambda,
   remove `resolve_user` / `resolve_account_id` from Store, use
   `controller.current_account` in Store
4. Run specs
5. Verify: app login → visit has user_id and account_id
6. Verify: page views → events have user_id and account_id
7. Verify: player → events have account_id from properties
8. Verify: admin → excluded from tracking
