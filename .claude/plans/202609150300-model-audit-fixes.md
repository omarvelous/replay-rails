# Plan: Model Audit Fixes

## Context

The model audit (`.claude/analysis/model-audit.md`) scored the
codebase 4.2/5. This plan fixes all identified issues in priority
order and adds a model standard to `.claude/standards/`.

---

## Phase 1: P0 — Data Integrity (Schema/Validation Mismatches)

### 1a. NOT NULL migration

Single migration adding `null: false` to all columns that have
model-level presence validations but allow NULL in the schema:

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

No data issues since there's no existing data to worry about.

---

## Phase 2: P1 — Validation Gaps

### 2a. User email format validation

**File:** `app/models/user.rb`

Add format validation:

```ruby
validates :email_address, format: { with: URI::MailTo::EMAIL_REGEXP }
```

Already has presence and uniqueness — just missing format.

### 2b. Agent email uniqueness within account

**File:** `app/models/agent.rb`

Add scoped uniqueness:

```ruby
validates :email, uniqueness: { scope: :account_id }
```

Add matching unique index in migration:

```ruby
add_index :agents, [:account_id, :email], unique: true
```

### 2c. QrCode destination validation

**File:** `app/models/qr_code.rb`

Add custom validation ensuring at least one destination:

```ruby
validate :destination_present

private

def destination_present
  unless destination_url.present? || destination_record.present?
    errors.add(:base, "must have a destination URL or destination record")
  end
end
```

---

## Phase 3: P2 — Test Coverage

### 3a. Missing model specs

Add specs for models that have no dedicated spec file:

| Model | What to test |
|-------|-------------|
| `Inquiry` | Validations (name, email, inquiry_type inclusion), TYPES constant |
| `Site` | Validations (name presence), association (screens dependent destroy) |
| `Playlist` | Validations (name, status), scopes (search, by_status), STATUSES constant |
| `PlaylistAd` | Validations (duration, same_account), positioning |
| `LeadAgent` | Associations (belongs_to lead, agent) |
| `QrCode` | Validations (token uniqueness, URL format, destination_present), methods (scan_events, scan_count) |
| `AccountUser` | Validations (role inclusion, uniqueness), callback (ensure_not_last_owner) |

### 3b. Scope specs

Add scope specs for models with search/filter scopes:

| Model | Scopes to test |
|-------|---------------|
| `Listing` | `search`, `by_status`, `by_property_type`, `by_listing_type` |
| `Lead` | `unread`, `by_status`, `search` |
| `Playlist` | `search`, `by_status` |
| `Screen` | `search`, `live`, `idle` |
| `Ad` | `search` |
| `Invite` | `pending`, `expired` |

### 3c. Delegated type model specs

Add specs for ad type models:

| Model | What to test |
|-------|-------------|
| `Ads::ListingAd` | Badge validations (conditional: open_house requires event_date, price_reduction requires original_price, just_sold requires sold_price), `default_headline`, badge predicate methods |
| `Ads::AgentAd` | Agent presence, `default_headline` returns agent name |
| `Ads::BrandAd` | `default_headline` returns nil, LAYOUTS constant |
| `Ads::CollectionAd` | collection_title presence, `default_headline`, MAX_ITEMS constant |
| `Experiences::ListingExperience` | Listing presence, `default_agent` delegation |

---

## Phase 4: P3 — Performance

### 4a. Counter caches

Add `counter_cache: true` to frequently counted associations:

| Parent | Child | Column to add |
|--------|-------|---------------|
| `Playlist` | `PlaylistAd` | `playlist_ads_count` |
| `Listing` | `ListingAgent` | `listing_agents_count` |

Migration:

```ruby
class AddCounterCaches < ActiveRecord::Migration[8.1]
  def change
    add_column :playlists, :playlist_ads_count, :integer, default: 0, null: false
    add_column :listings, :listing_agents_count, :integer, default: 0, null: false
  end
end
```

Update `belongs_to` declarations:

```ruby
# PlaylistAd
belongs_to :playlist, counter_cache: true

# ListingAgent
belongs_to :listing, counter_cache: true
```

Reset counters in migration or rake task.

---

## Phase 5: P4 — Cleanup

### 5a. Extract Player device detection to service

**New file:** `app/services/parse_device_info.rb`

Extract `parse_user_agent!` and `infer_device_type` from Player
into a `ParseDeviceInfo` service. It takes a raw UA string, calls
DeviceDetector, infers the device type, and writes fields back
to the player. The model drops ~30 lines of transformation logic
that doesn't belong on the record.

API controllers call `ParseDeviceInfo.new(player:).call` instead
of `player.parse_user_agent!`. Player keeps only data, associations,
and state queries (`online?`, `paired?`, `provisioned?`).

### 5b. Extract Invite#accept! to service

**New file:** `app/services/accept_invite.rb`

Move the orchestration logic (create AccountUser, link agent
profile, mark accepted) to a service. Invite model keeps the
state query methods (`pending?`, `expired?`, `accepted?`).

### 5c. Add inverse_of to scoped associations

**Files:** `screen.rb`, `player.rb`

```ruby
has_one :active_player_assignment, -> { active },
        class_name: "ScreenPlayer", inverse_of: :screen

has_one :active_assignment, -> { active },
        class_name: "ScreenPlayer", inverse_of: :player
```

### 5d. Consider destroy_async on Account

**File:** `account.rb`

For high-volume associations that would slow down account deletion:

```ruby
has_many :leads, dependent: :destroy_async
has_many :ads, dependent: :destroy_async
```

Requires Active Job queue to be running. Deferred until account
deletion is a real use case.

---

## Phase 6: Model Standard

**New file:** `.claude/standards/models/conventions.md`

Sections:
1. **Structure** — file ordering, inheritance, max lines, constants
2. **Validations** — presence + null: false, uniqueness + unique index, format, inclusion with constants
3. **Associations** — dependent options, inverse_of, counter_cache, ordering
4. **Scopes** — no default_scope, chainable, sanitize_sql_like, naming
5. **Callbacks** — minimal, after_commit for side effects, before_create for tokens
6. **Data Integrity** — schema must match validations, FK constraints, boolean null: false
7. **Multi-Tenant** — acts_as_tenant on all account-scoped models, scoped uniqueness
8. **Security** — has_secure_password, SecureRandom tokens, public_id, PaperTrail
9. **Testing** — associations, validations, scopes, methods, factories

Update `.claude/standards/index.yml` and `CLAUDE.md`.

---

## Build Order (TDD)

### Phase 1: P0

```
1. Migration: add null: false to 10 columns
2. Run tests — verify no factories create invalid records
3. COMMIT
```

### Phase 2: P1

```
4. RED:  User email format spec
5. GREEN: Add format validation
6. COMMIT

7. RED:  Agent email uniqueness within account spec
8. GREEN: Add scoped uniqueness + index migration
9. COMMIT

10. RED:  QrCode destination validation spec
11. GREEN: Add custom validation
12. COMMIT
```

### Phase 3: P2

```
13. Add model specs for 7 missing models
14. COMMIT

15. Add scope specs for 6 models
16. COMMIT

17. Add delegated type model specs for 5 ad/experience models
18. COMMIT
```

### Phase 4: P3

```
19. Counter cache migration + belongs_to updates
20. COMMIT
```

### Phase 5: P4

```
21. Extract ParseDeviceInfo service from Player
22. COMMIT

23. Extract AcceptInvite service from Invite#accept!
24. COMMIT

25. Add inverse_of to scoped associations
26. COMMIT
```

### Phase 6: Standard

```
27. Write .claude/standards/models/conventions.md
28. Update index.yml + CLAUDE.md
29. COMMIT
```

---

## Verification

1. `make test` — green after each phase
2. `make lint` — clean
3. Schema constraints match model validations (audit script)
4. No model exceeds 100 lines after extractions
5. Every model has a spec file
6. Standard covers every checklist item

---

## Expected Post-Completion Score

| Category | Current | Target |
|----------|:-------:|:------:|
| Data Integrity | 3 | 5 |
| Validations | 3 | 5 |
| Testing | 3 | 5 |
| Performance | 4 | 5 |
| Everything else | 4-5 | 5 |
| **Overall** | **4.2** | **5.0** |
