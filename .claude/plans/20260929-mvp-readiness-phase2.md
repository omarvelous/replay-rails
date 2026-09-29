# Plan: MVP Readiness — Phase 2

**Created:** 2026-09-29
**Completed:** 2026-09-29
**Status:** Complete
**Branch:** `feature/mvp-readiness-phase2`

## Context

The MVP readiness audit identified 12 items. Five are shipped (SSL,
CSP, Resend, host validation, Rack::Attack store, session expiration).
This plan covers the remaining 7 items, ordered by impact.

---

## Part A — Quick wins (< 30 min total)

### 1. Ads index N+1 fix

**File:** `app/controllers/app/ads_controller.rb`

The index action queries `Ad.all` without includes. Every ad card
triggers N+1 queries for adable and image.

```ruby
# Before
base = authorized_scope(Ad.all)
# After
base = authorized_scope(Ad.all).includes(:adable, image_attachment: :blob)
```

- **RED:** Spec that the index response is successful (already exists)
- **GREEN:** Add `.includes`
- Verify with Bullet in dev

### 2. Schedule cleanup jobs

**File:** `config/recurring.yml`

`PlayerCleanupJob` and `VersionCleanupJob` exist but aren't scheduled.

```yaml
production:
  player_cleanup:
    class: PlayerCleanupJob
    schedule: at 3:30am every day
  version_cleanup:
    class: VersionCleanupJob
    schedule: at 4am every day
```

Add to staging too.

### 3. CSP enforce mode

**File:** `config/initializers/content_security_policy.rb`

Currently `report_only = true`. Flip to enforce once confirmed no
violations in logs.

- Check Render logs for CSP violation reports
- If clean, set `config.content_security_policy_report_only = false`
- If violations exist, fix the policy first

---

## Part B — Account name + settings

### 4. Add name column to accounts

**Migration:**
```ruby
add_column :accounts, :name, :string, null: false, default: ""
```

**Model:** Add validation `validates :name, presence: true`

**TDD:**
- RED: Model spec for name presence validation
- GREEN: Migration + validation

### 5. Collect name on signup

**File:** `app/views/app/accounts/new.html.erb`

Add "Company / brokerage name" field above the user fields.
Submits under `account[name]`.

**File:** `app/controllers/app/accounts_controller.rb`

Permit `name` in `account_params`.

**TDD:**
- RED: Request spec — signup with name creates account with name
- GREEN: Update form + controller

### 6. Account settings page

New route: `resource :settings, only: [:show, :update]` (singular)

**Controller:** `App::SettingsController`
- `show` — displays account name
- `update` — updates account name (owner only)

**View:** Simple form with account name field. Owner-only edit.
Managers and agents see the name but can't edit.

**Policy:** `SettingsPolicy` — show: any member, update: owner only

**TDD:**
- RED: Request spec for GET /settings (success), PATCH /settings
  (owner can update, agent cannot)
- GREEN: Controller, view, policy, route

### 7. Update admin + seeds

- Admin dashboard: show account name in listings
- Seeds: name the demo accounts ("Demo Brokerage", etc.)
- Update factory: add `name` to account factory

---

## Part C — User profile edit

### 8. Profile controller actions

**File:** `app/controllers/app/users_controller.rb`

Add `edit` and `update` actions. Users can only edit themselves.

```ruby
def edit
  @user = current_user
  authorize! @user
end

def update
  @user = current_user
  authorize! @user
  if @user.update(user_params)
    redirect_to user_path(@user), notice: t(".success")
  else
    render :edit, status: :unprocessable_entity
  end
end

private

def user_params
  params.require(:user).permit(
    :first_name, :last_name, :email_address, :phone,
    :password, :password_confirmation
  )
end
```

**Route:** Already has `resources :users` — just needs edit/update
actions (not restricted by `only`).

**Policy:** `UserPolicy#update?` — user can edit self. Manager+ can
view others but not edit them.

**View:** Profile edit form with name, email, phone, optional
password change section.

**TDD:**
- RED: Request spec — user can edit self, cannot edit others,
  password change works, invalid params return 422
- GREEN: Controller actions, view, policy update

### 9. Navigation link

Add "Profile" or user name link in the app sidebar/nav that links
to `edit_user_path(current_user)`.

---

## Part D — COMING_SOON gate

### 10. Convert to feature flag

**Current:** `ComingSoonMiddleware` checks `ENV["COMING_SOON"]` and
blocks the entire app with a static page.

**Options:**
a) Just remove the env var in Render when ready to launch (simplest)
b) Convert to per-account feature flag for staged rollout

**Recommendation:** Option (a) for now. The middleware is fine as a
global kill switch — just unset the env var when ready. No code
change needed, just a deploy config change.

Document this in the launch checklist.

---

## Part E — Dashboard caching

### 11. Cache dashboard stats

**File:** `app/presenters/dashboard_presenter.rb`

The presenter runs 8+ queries on every page load (screens online,
impressions, scans, leads, charts). Cache the expensive ones.

```ruby
def impressions_month
  Rails.cache.fetch(cache_key("impressions"), expires_in: 5.minutes) do
    account_events.where(name: "content.impressed").count
  end
end
```

Cache keys scoped by account + method name. 5-minute TTL is fine
for dashboard stats — they don't need to be real-time.

**TDD:**
- RED: Spec that presenter returns correct values (already exists
  or add if missing)
- GREEN: Add caching, verify same results

---

## Execution Order (TDD)

### Batch 1 — Quick wins
```
1. Ads N+1 fix + commit
2. Schedule cleanup jobs + commit
3. CSP enforce (if logs are clean) + commit
```

### Batch 2 — Account name
```
4. RED:  Account model spec for name validation
   GREEN: Migration + validation + factory update
   COMMIT

5. RED:  Signup request spec with account name
   GREEN: Form field + permit name in controller
   COMMIT

6. RED:  Settings request spec (show, update, authorization)
   GREEN: SettingsController + view + policy + route
   COMMIT

7. Update admin dashboard + seeds
   COMMIT
```

### Batch 3 — User profile
```
8. RED:  Profile edit request spec (edit self, reject others,
         password change, invalid params)
   GREEN: UsersController edit/update + view + policy
   COMMIT

9. Add nav link to profile
   COMMIT
```

### Batch 4 — Performance
```
10. Dashboard caching + commit
```

### Batch 5 — Docs
```
11. Update CLAUDE.md (account name, settings, profile)
    Update roadmap (mark items shipped)
    Promote plan
    COMMIT
```

---

## Verification

1. `make test` — green after each batch
2. `make lint` — no offenses
3. Sign up as new user — name collected, settings page works
4. Edit profile — name, email, password change all work
5. Dashboard loads without N+1 (check Bullet output)
6. Cleanup jobs appear in `make console` → `SolidQueue::RecurringTask.all`

## Out of Scope

- Subscriptions / billing (separate plan needed)
- In-app notification system (separate plan needed)
- Content scheduling (separate plan exists)
- COMING_SOON removal (deploy config, not code)
