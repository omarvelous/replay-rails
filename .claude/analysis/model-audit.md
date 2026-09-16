# Analysis: Model Audit

## Methodology

Scored every model against a 12-category checklist derived from
Rails 8 best practices, OWASP guidelines, and multi-tenant SaaS
patterns. Each category scored 1-5.

**Codebase stats:** 44 model files, 1,024 lines of code, 27 models
with `PublicIdentifiable`, 9 with `acts_as_tenant`, 18 with
`has_paper_trail`.

---

## Scorecard

| Category | Score | Summary |
|----------|:-----:|---------|
| 1. Model Structure | 4 | Clean ordering, concerns well-used. Player is 84 lines (largest). |
| 2. Validations | 3 | Good coverage. Some model/schema mismatches. Missing email format validation on User. |
| 3. Associations | 4 | Consistent `dependent:` options. Missing `inverse_of` on some scoped associations. |
| 4. Scopes | 5 | Clean, chainable, use `sanitize_sql_like`. No `default_scope`. |
| 5. Callbacks | 5 | Minimal, correct placement. Side effects in `after_commit`. Token gen in `before_create`. |
| 6. Data Integrity | 3 | FK constraints exist. Some validation/schema mismatches. Missing NOT NULL on validated fields. |
| 7. Security | 5 | `has_secure_password`, SecureRandom tokens, UUID public_ids, PaperTrail audit. |
| 8. Multi-Tenant | 4 | `acts_as_tenant` on all tenant models. Some uniqueness validations missing `scope: :account_id`. |
| 9. Audit/Versioning | 5 | PaperTrail on all business models. Metadata includes account_id. Sensible `ignore:` lists. |
| 10. Testing | 3 | Good spec coverage. Some models missing specs. No scope specs for most models. |
| 11. Performance | 4 | Bullet gem active. Counter caches missing where useful. |
| 12. Code Organization | 5 | Thin models, concerns for shared behavior, service objects for orchestration. |
| **Overall** | **4.2** | |

---

## Category Details

### 1. Model Structure — Score: 4

**What's working:**
- All models inherit from `ApplicationRecord`
- Canonical ordering mostly followed (concerns → macros → associations → validations → scopes → callbacks → methods)
- Constants frozen with `.freeze`
- No model exceeds 150 lines

**Issues:**

| Issue | Severity | Where |
|-------|----------|-------|
| Player model is 84 lines with `parse_user_agent!` and `infer_device_type` — could extract to a concern | Low | `player.rb` |
| `Invite#accept!` is 15+ lines of orchestration — could be a service | Low | `invite.rb` |
| Some models mix association ordering (has_one before belongs_to) | Low | Various |

### 2. Validations — Score: 3

**What's working:**
- Presence validations on key fields
- Inclusion validations reference frozen constants
- Conditional validations on ListingAd (badge-specific fields)
- `belongs_to` required by default (no redundant presence validations)

**Issues:**

| Issue | Severity | Where | Fix |
|-------|----------|-------|-----|
| User has no email format validation | Medium | `user.rb` | Add `format: { with: URI::MailTo::EMAIL_REGEXP }` |
| Account has zero validations | Medium | `account.rb` | Add `validates :name, presence: true` if name exists, or document why empty |
| Listing doesn't validate address uniqueness within account | Low | `listing.rb` | May be intentional (same address, different units) — document |
| QrCode validates URL format but allows blank — no presence validation on either destination_url or destination_record | Medium | `qr_code.rb` | Add custom validation: at least one destination must be set |
| Inquiry missing phone format validation | Low | `inquiry.rb` | Add same format as User's phone |
| Site has no `name` uniqueness within account | Low | `site.rb` | Consider `uniqueness: { scope: :account_id }` |
| Schema has `null: false` on several columns with no matching model validation | Medium | Various | See Data Integrity section |

### 3. Associations — Score: 4

**What's working:**
- Every `has_many` has `dependent:` option
- `has_many :through` used for all many-to-many (no HABTM)
- Delegated types used correctly (Ad → adable, Experience → experienceable, ScreenContent → contentable)
- Polymorphic associations have composite indexes
- FK constraints in schema for all relationships

**Issues:**

| Issue | Severity | Where | Fix |
|-------|----------|-------|-----|
| `has_one :active_player_assignment, -> { active }` missing `inverse_of:` | Low | `screen.rb` | Add `inverse_of: :screen` |
| `has_one :active_assignment, -> { active }` missing `inverse_of:` | Low | `player.rb` | Add `inverse_of: :player` |
| `has_many :playlist_ads, -> { order(:position) }` has `inverse_of: :playlist` (good) but other ordered associations don't | Low | Various | Add `inverse_of` to scoped associations |
| Account has 12 `has_many` with `dependent: :destroy` — cascading delete of a large account could be very slow | Medium | `account.rb` | Consider `dependent: :destroy_async` for high-volume associations (leads, impressions) |
| `Ad` has `has_many :collection_ad_ads, dependent: :restrict_with_error` — correctly prevents orphaning, but the error is not user-friendly | Low | `ad.rb` | Add custom error message |

### 4. Scopes — Score: 5

**What's working:**
- No `default_scope` anywhere
- All scopes are chainable (return Relations)
- `sanitize_sql_like` used in all `ILIKE` search scopes
- Lambda syntax for parameterized scopes
- Descriptive naming (`search`, `by_status`, `unread`, `live`, `idle`)

**No issues found.**

### 5. Callbacks — Score: 5

**What's working:**
- Token generation in `before_create` with `||=` guard
- `after_commit` for ActionCable broadcasts (ScreenContent)
- `before_destroy :ensure_not_last_owner` with proper abort pattern (AccountUser)
- Email normalization in `normalizes` (User)
- Minimal callbacks — most models have 0-1

**No issues found.**

### 6. Data Integrity — Score: 3

**What's working:**
- FK constraints on all relationships
- Unique indexes on tokens, public_ids
- Composite unique indexes on join tables
- Partial unique indexes for "one active" constraints
- `decimal(12,2)` for price columns

**Issues:**

| Issue | Severity | Where | Fix |
|-------|----------|-------|-----|
| `Agent.email` validates presence but schema allows NULL | Medium | `agents` table | Add `null: false` migration |
| `Agent.name` validates presence but schema allows NULL | Medium | `agents` table | Add `null: false` migration |
| `Site.name` validates presence but schema allows NULL | Medium | `sites` table | Add `null: false` migration |
| `Screen.name` validates presence but schema allows NULL | Medium | `screens` table | Add `null: false` migration |
| `Playlist.name` validates presence but schema allows NULL | Medium | `playlists` table | Add `null: false` migration |
| `Playlist.status` validates presence but schema allows NULL | Medium | `playlists` table | Add `null: false` migration |
| `Lead.name` validates presence but schema allows NULL | Medium | `leads` table | Add `null: false` migration |
| `Experience.name` validates presence but schema allows NULL | Medium | `experiences` table | Add `null: false` migration |
| `Inquiry.name` and `Inquiry.email` validate presence but schema allows NULL | Medium | `inquiries` table | Add `null: false` migration |
| Boolean `active` on screen_contents has `null: false` + default (good) | — | — | — |
| Boolean `touch_capable` on players has default but should verify `null: false` | Low | `players` table | Verify |
| Missing CHECK constraints for enum-style columns (status, role, theme, etc.) | Low | Various | Add CHECK constraints for defense-in-depth |

### 7. Security — Score: 5

**What's working:**
- `has_secure_password` on User
- SecureRandom tokens (32 bytes for auth tokens, 8 bytes for QR codes)
- Pairing codes are 6-char alphanumeric with 10-minute expiry
- All tokens have unique indexes
- UUID `public_id` on every model — no sequential ID exposure
- PaperTrail on all business models
- `filter_parameters` configured

**No issues found.**

### 8. Multi-Tenant — Score: 4

**What's working:**
- 9 models with `acts_as_tenant :account` — all tenant-scoped models
- Non-tenant models (User, Session, Player) correctly excluded
- FK constraints on `account_id` columns
- Controllers scope through `Current.account`

**Issues:**

| Issue | Severity | Where | Fix |
|-------|----------|-------|-----|
| Agent `email` uniqueness not scoped to account | Medium | `agent.rb` | Has no uniqueness validation — two agents in same account can share email. Add `validates :email, uniqueness: { scope: :account_id }` |
| Playlist `name` not unique within account | Low | `playlist.rb` | Consider `uniqueness: { scope: :account_id }` |
| QrCode `label` not unique within account | Low | `qr_code.rb` | Low priority — labels are optional |
| Join tables (ListingAgent, LeadAgent, PlaylistAd) don't have `acts_as_tenant` — correctly accessed through tenant-scoped parents, but direct queries would bypass | Low | Various | Safe as-is since controllers always scope through parent |

### 9. Audit/Versioning — Score: 5

**What's working:**
- PaperTrail on all 18 business models
- `ignore: [:updated_at]` on most (reduces noise)
- Player ignores heartbeat/IP/UA/pairing fields
- `paper_trail_metadata` includes `account_id` via ApplicationRecord
- `set_paper_trail_whodunnit` in App::BaseController

**No issues found.**

### 10. Testing — Score: 3

**What's working:**
- Model specs exist for key models (User, Screen, Listing, Ad, Lead, Player, etc.)
- shoulda-matchers for associations and validations
- Factory Bot with traits for state variations
- Service specs for extracted logic

**Issues:**

| Issue | Severity | Where | Fix |
|-------|----------|-------|-----|
| Missing model specs for: Inquiry, Site, Playlist, PlaylistAd, LeadAgent, Invite, AccountUser (validations/methods) | Medium | `spec/models/` | Add specs for validations, scopes, and custom methods |
| No scope specs for most models (search, by_status, etc.) | Medium | Various | Add specs: one matching record, one not |
| Ads delegated type models (ListingAd, AgentAd, etc.) have no model specs | Medium | `spec/models/ads/` | Add specs for conditional validations, default_headline |
| Experience/ListingExperience have no model specs | Medium | `spec/models/experiences/` | Add specs for delegation methods |
| QrCode has no model spec (destination validation, scan_events) | Medium | `spec/models/` | Add spec |

### 11. Performance — Score: 4

**What's working:**
- Bullet gem active in dev and test
- Eager loading in controllers (added in P3)
- Pagination on all index actions
- Indexes on query columns

**Issues:**

| Issue | Severity | Where | Fix |
|-------|----------|-------|-----|
| No counter caches — views call `.count` on associations | Medium | Various | Add `counter_cache: true` to `belongs_to` for: Screen (screen_players), Playlist (playlist_ads), Listing (listing_agents) |
| `Account` has 12 `has_many :through` — loading an account eager loads a lot | Low | `account.rb` | Only matters for admin — acceptable |
| Polymorphic N+1 on `ListingAd => listing` is safelisted, not fixed | Low | N/A | Accept — can't deep-include through delegated_type |

### 12. Code Organization — Score: 5

**What's working:**
- Concerns for shared behavior (`PublicIdentifiable`, `Authorizable`)
- Service objects for orchestration (`AssignScreenContent`, `PairPlayerToScreen`, `CaptureLead`)
- Presenter for complex queries (`DashboardPresenter`)
- No model references `Current` in instance methods
- No model calls external services directly
- No model returns HTML or view-layer concerns

**No issues found.**

---

## Priority Fixes

### P0 — Data Integrity (Schema/Validation Mismatches)

One migration to add `null: false` to all columns that validate presence:

```ruby
class EnforceNotNullOnValidatedColumns < ActiveRecord::Migration[8.1]
  def change
    change_column_null :agents, :name, false
    change_column_null :agents, :email, false
    change_column_null :sites, :name, false
    change_column_null :screens, :name, false
    change_column_null :playlists, :name, false
    change_column_null :playlists, :status, false
    change_column_null :leads, :name, false
    change_column_null :experiences, :name, false
    change_column_null :inquiries, :name, false
    change_column_null :inquiries, :email, false
  end
end
```

**Effort:** Small (one migration). **Impact:** Prevents invalid data
from bypassing model validations (e.g., `save(validate: false)`,
raw SQL, console).

### P1 — Validations

| # | Fix | Effort |
|---|-----|--------|
| 1 | User: add email format validation | Small |
| 2 | Agent: add `uniqueness: { scope: :account_id }` on email | Small |
| 3 | QrCode: validate at least one destination present | Small |

### P2 — Testing

| # | Fix | Effort |
|---|-----|--------|
| 4 | Add model specs for: Inquiry, Site, Playlist, PlaylistAd, LeadAgent, QrCode | Medium |
| 5 | Add scope specs for search/by_status/unread on Listing, Lead, Playlist | Medium |
| 6 | Add specs for Ads delegated type models (conditional validations, methods) | Medium |
| 7 | Add specs for Experience/ListingExperience delegation methods | Small |

### P3 — Performance

| # | Fix | Effort |
|---|-----|--------|
| 8 | Add counter caches for frequently counted associations | Medium |

### P4 — Cleanup

| # | Fix | Effort |
|---|-----|--------|
| 9 | Extract Player `parse_user_agent!` / `infer_device_type` to concern | Small |
| 10 | Extract `Invite#accept!` to `AcceptInvite` service | Small |
| 11 | Add `inverse_of` to scoped `has_one` associations | Small |
| 12 | Consider `dependent: :destroy_async` on Account's high-volume associations | Small |

---

## Model-by-Model Quick Reference

| Model | Lines | Structure | Validations | Integrity | Tenant | Tests |
|-------|:-----:|:---------:|:-----------:|:---------:|:------:|:-----:|
| User | 18 | 5 | 3 | 4 | N/A | 5 |
| Account | 18 | 5 | 2 | 4 | N/A | 4 |
| AccountUser | 26 | 5 | 5 | 5 | N/A | 3 |
| Session | 5 | 5 | 5 | 5 | N/A | 5 |
| Invite | 61 | 4 | 4 | 4 | 5 | 3 |
| Agent | 21 | 5 | 3 | 3 | 5 | 4 |
| Listing | 42 | 5 | 5 | 4 | 5 | 5 |
| ListingAgent | 23 | 5 | 5 | 5 | N/A | 4 |
| Lead | 37 | 5 | 5 | 3 | 5 | 4 |
| LeadAgent | 7 | 5 | 5 | 5 | N/A | 3 |
| Inquiry | 11 | 5 | 3 | 3 | N/A | 2 |
| Site | 15 | 5 | 3 | 3 | 5 | 3 |
| Screen | 42 | 5 | 5 | 4 | N/A | 5 |
| ScreenContent | 19 | 5 | 5 | 5 | N/A | 4 |
| ScreenPlayer | 16 | 5 | 5 | 5 | N/A | 4 |
| Player | 84 | 4 | 4 | 4 | N/A | 5 |
| Ad | 47 | 5 | 4 | 4 | 5 | 4 |
| Ads::ListingAd | 44 | 5 | 5 | 4 | N/A | 3 |
| Ads::AgentAd | 14 | 5 | 5 | 4 | N/A | 3 |
| Ads::BrandAd | 11 | 5 | 5 | 4 | N/A | 3 |
| Ads::CollectionAd | 17 | 5 | 5 | 4 | N/A | 3 |
| Ads::CollectionAdAd | 8 | 5 | 5 | 5 | N/A | 3 |
| Playlist | 16 | 5 | 4 | 3 | 5 | 3 |
| PlaylistAd | 21 | 5 | 5 | 5 | N/A | 3 |
| Experience | 21 | 5 | 4 | 3 | 5 | 3 |
| Experiences::ListingExperience | 16 | 5 | 5 | 4 | N/A | 3 |
| QrCode | 29 | 5 | 3 | 4 | 5 | 2 |
