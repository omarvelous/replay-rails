# Plan: Controller Audit Fixes + Controller Standard (v2)

## Context

The controller audit (`.claude/analysis/controller-audit.md`) scored
the codebase 3.5/5. This plan fixes all identified issues in priority
order, introduces service objects and base controllers where they
add clarity, and adds a controller standard to prevent regression.

---

## Service Objects & Extractions

| Extraction | Type | Why |
|-----------|------|-----|
| `AssignScreenContent` | Service object | Deactivate/activate pattern is a business rule, protects analytics history, reusable for future API content switching |
| `PairPlayerToScreen` | Service object | Move orchestration out of model — unpairing old player, creating ScreenPlayer, clearing code, broadcasting. Model keeps associations only. |
| `CaptureLead` | Service object | Resolves signed IDs, determines account, creates lead, assigns agent, sends mail — testable pipeline |
| `App::Ads::BaseController` | Base controller | 4 ad type controllers duplicate build/validate/save. Parent extracts shared flow, children define type-specific params. |
| `DashboardPresenter` | Presenter/query object | Extracts ~8 inline queries from DashboardController |

---

## Phase 1: P0 Fixes (Security / Data Integrity)

### 1a. ScreenContentsController + AssignScreenContent service — DONE

Clean separation of concerns across four layers:

| Layer | Responsibility |
|-------|---------------|
| **Model** (`ScreenContent`) | Validates `contentable_type` via `delegated_type`, validates presence via `belongs_to` |
| **Policy** (`ScreenContentPolicy`) | "Can this user assign content?" — role check only, no data validation |
| **Service** (`AssignScreenContent`) | Deactivates old active content, saves new — workflow only |
| **Controller** | Builds the object, authorizes, calls service, responds |

Controller flow:
```ruby
@screen_content = @screen.screen_contents.build(screen_content_params)
authorize! @screen_content
AssignScreenContent.new(screen_content: @screen_content).call
```

The service receives a built (unsaved) `ScreenContent` and handles
the deactivate/save workflow. No type resolution or authorization
in the service — those are handled by the model and policy.

Removed `ScreenContent.find_contentable` — type validation belongs
to the model via `delegated_type`, not a custom class method.

### 1b. API BaseController — error handlers

**File:** `app/controllers/api/base_controller.rb`

Add `rescue_from` for:
- `ActiveRecord::RecordNotFound` → JSON 404
- `ActiveRecord::RecordInvalid` → JSON 422
- `ActionController::ParameterMissing` → JSON 400

### 1c. API rate limiting

**File:** `app/controllers/api/base_controller.rb`

Add Rails 8 `rate_limit` — 60 req/min baseline, tighter on
player registration.

### 1d. Rate limit Go::LeadsController

Add `rate_limit to: 10, within: 1.hour` on `:create`.

---

## Phase 2: P1 Fixes (Best Practice Gaps)

### 2a. API versioning

Wrap API routes in `namespace :v1`. Move controllers to `api/v1/`.
Update player JS URLs. No external consumers.

### 2b. API response envelope

Standardize: `{ "data": { ... } }` / `{ "error": { "message": "..." } }`

### 2c. PairPlayerToScreen service + PairingsController fix

**New file:** `app/services/pair_player_to_screen.rb`

Move orchestration from `Screen#pair_player!` to service:
- Validate pairing code exists and is not expired
- Unpair old player from screen
- Unpair this player from any other screen
- Create ScreenPlayer record
- Clear pairing code
- Broadcast via ActionCable

Returns a result object: `{ success: true }` or
`{ success: false, error: "Code expired" }`

Controller becomes thin: call service, handle result (redirect
or re-render with flash).

Also fix PairingsController:
- `find_by(id:)` → `find_by_param!`
- Add `authorize! screen, to: :update?`

ScreenPlayersController also calls `screen.pair_player!` — update
to use the service too.

### 2d. Cross-tenant isolation specs

Shared example `"tenant isolated"` in `spec/support/`.

### 2e. API players show — remove screen integer ID

Use `public_id` or remove entirely.

### 2f. CaptureLead service

**New file:** `app/services/capture_lead.rb`

Extract from Go::LeadsController:
- Resolve listing/agent from signed IDs
- Determine account from listing or agent
- Build lead with context (source_url, ip, user_agent)
- Assign agent via LeadAgent
- Enqueue LeadMailer

Returns: `{ success: true, lead: }` or `{ success: false, errors: }`

Controller becomes:

```ruby
def create
  return head(:ok) if honeypot_triggered?
  result = CaptureLead.call(params: lead_params, request:)
  if result.success?
    redirect_back_or_to marketing_root_path, flash: { submitted: true }
  elsif result.lead
    redirect_back_or_to marketing_root_path, alert: result.lead.errors.full_messages.to_sentence
  else
    head :unprocessable_content
  end
end
```

---

## Phase 3: P2 Improvements

### 3a. App::Ads::BaseController

**New file:** `app/controllers/app/ads/base_controller.rb`

Extract shared flow from 4 ad type controllers:

```ruby
module App
  module Ads
    class BaseController < App::BaseController
      before_action :set_ad, only: %i[edit update]

      def new
        @adable = build_adable
        @ad = Current.account.ads.build
        @ad.adable = @adable
        @ad.apply_defaults
        authorize! @ad
      end

      def create
        @adable = build_adable(adable_params)
        @ad = Current.account.ads.build(ad_params)
        @ad.adable = @adable
        @ad.apply_defaults
        authorize! @ad

        if @adable.valid? & @ad.valid?
          @adable.save!
          @ad.save!
          redirect_to @ad, notice: t(".success")
        else
          render :new, status: :unprocessable_entity
        end
      end

      # edit uses @ad from set_ad
      def update
        # ... shared update logic
      end

      private

        def set_ad
          @ad = Current.account.ads.find_by_param!(params[:id])
          @adable = @ad.adable
        end

        # Subclasses override:
        def adable_class = raise(NotImplementedError)
        def adable_params = raise(NotImplementedError)
        def ad_params = raise(NotImplementedError)
        def build_adable(params = {}) = adable_class.new(params)
    end
  end
end
```

Each child becomes ~15 lines:

```ruby
module App
  module Ads
    class ListingAdsController < App::Ads::BaseController
      private

        def adable_class = ::Ads::ListingAd
        def adable_params = params.require(:listing_ad).permit(...)
        def ad_params = params.require(:ad).permit(...)
    end
  end
end
```

### 3b. HoneypotProtection concern

### 3c. Route `:only` cleanup

### 3d. Strict loading + Bullet gem

### 3e. I18n flash messages

### 3f. DashboardPresenter

Extract ~8 queries to `app/presenters/dashboard_presenter.rb`.

---

## Phase 4: Controller Standard

**New file:** `.claude/standards/controllers/conventions.md`

Sections:
1. **Structure** — inheritance, ordering, max action size, callbacks
2. **Multi-Tenant** — Current.account scoping, bypasses
3. **Authorization** — authorize!/authorized_scope everywhere
4. **Parameters** — strong params, type validation, _sid for public
5. **Service Objects** — when to extract, naming, interface
6. **API** — /v1/, data/error envelope, rescue_from, rate_limit
7. **Error Handling** — HTML 422, API JSON, flash, I18n
8. **Performance** — includes, pagy, strict_loading
9. **Testing** — request specs, tenant isolation, shared examples

---

## Build Order (TDD)

### Phase 1: P0

```
1. AssignScreenContent service + update controller (replace destroy_all)
2. COMMIT

3. RED:  API spec — RecordNotFound returns JSON 404
4. GREEN: rescue_from handlers in Api::BaseController
5. COMMIT

6. Rate limits (API + Go::Leads)
7. COMMIT
```

### Phase 2: P1

```
8.  API v1 namespace (routes, controllers, JS)
9.  COMMIT

10. API response envelope
11. COMMIT

12. PairPlayerToScreen service + update controllers + fix PairingsController
13. COMMIT

14. CaptureLead service + update Go::LeadsController
15. COMMIT

16. Cross-tenant isolation specs
17. COMMIT

18. API players show fix
19. COMMIT
```

### Phase 3: P2

```
20. App::Ads::BaseController + slim children
21. COMMIT

22. HoneypotProtection concern
23. COMMIT

24. Route cleanup + strict loading + Bullet + I18n
25. COMMIT

26. DashboardPresenter
27. COMMIT
```

### Phase 4: Standard

```
28. Write .claude/standards/controllers/conventions.md
29. Update index.yml + CLAUDE.md
30. COMMIT
```

---

## Verification

1. `make test` — green after each phase
2. `make lint` — no offenses
3. API: JSON error responses (404, 400, 401, 429)
4. ScreenContents: deactivate old, create new (not destroy)
5. PairPlayerToScreen: service handles full workflow
6. CaptureLead: testable in isolation
7. Ads base controller: children are <20 lines each
8. Cross-tenant specs pass
9. Standard covers every audit item
