# Plan: Test Coverage Audit & Enforcement

## Current state
- 276 specs, 0 failures
- Estimated ~75-80% coverage with significant gaps in scopes, attachments, tenant isolation, and newer models
- No coverage tracking tool — no way to measure, enforce, or catch regressions

---

## Phase 1 — Add SimpleCov (coverage tracking)

### Step 1: Install SimpleCov

```ruby
# Gemfile (test group)
gem "simplecov", require: false
```

```ruby
# spec/spec_helper.rb (top of file, before anything else)
require "simplecov"
SimpleCov.start "rails" do
  enable_coverage :branch  # branch coverage, not just line
  minimum_coverage 80      # fail if coverage drops below 80%
  minimum_coverage_by_file 50  # flag files under 50%

  add_filter "/spec/"
  add_filter "/config/"
  add_filter "/db/"

  add_group "Models",      "app/models"
  add_group "Controllers", "app/controllers"
  add_group "Helpers",     "app/helpers"
  add_group "Services",    "app/services"
end
```

### Step 2: Add to CI

Add `coverage/` to `.gitignore`. The CI job runs `make test` which now
generates `coverage/index.html`. SimpleCov fails the suite if coverage
drops below the threshold.

### Step 3: Baseline

Run `make test` once to establish the baseline. Set `minimum_coverage`
to whatever the baseline is minus 2% — gives us a floor that only goes up.

---

## Phase 2 — Fill model spec gaps

### Task 1: Account associations
Currently only tests `has_many :users`. Add:
```
has_many :sites
has_many :listings
has_many :agents
has_many :ads
has_many :playlists
```

### Task 2: Scope coverage (4 models)

**Screen scopes:**
```ruby
describe ".search" do
  it "searches by name (case-insensitive)"
end

describe ".live" do
  it "returns screens with active screen_playlists"
  it "excludes screens without active playlists"
end

describe ".idle" do
  it "returns screens without active screen_playlists"
end
```

**Listing scopes:**
```ruby
describe ".search" do
  it "searches by address (case-insensitive)"
end

describe ".by_status" do
  it "filters by status"
end
```

**Playlist scopes:**
```ruby
describe ".search" do
  it "searches by name (case-insensitive)"
end

describe ".by_status" do
  it "filters by status"
end
```

**Ad scopes:**
```ruby
describe ".search" do
  it "searches by headline (case-insensitive)"
end
```
(Already tested in ad_spec.rb but as an integration test — add a focused unit test)

### Task 3: CollectionAd associations + validation

```ruby
describe "associations" do
  it { is_expected.to have_many(:collection_ad_ads).dependent(:destroy) }
  it { is_expected.to have_many(:member_ads).through(:collection_ad_ads) }
end

describe "member count validation" do
  it "is invalid with fewer than 2 members"
  it "is invalid with more than 8 members"
  it "is valid with 2-8 members"
end
```

### Task 4: BrandAd association

```ruby
describe "associations" do
  it "has one ad as adable"
end
```

### Task 5: Attachment specs

**Agent photo:**
```ruby
describe "photo attachment" do
  it "attaches a photo"
  it { expect(Agent.new.photo).not_to be_attached }
end
```

**Site photo:**
```ruby
describe "photo attachment" do
  it "attaches a photo"
  it { expect(Site.new.photo).not_to be_attached }
end
```

### Task 6: Session model spec

```ruby
# spec/models/session_spec.rb
describe "associations" do
  it { is_expected.to belong_to(:user) }
end
```

---

## Phase 3 — Fill request spec gaps

### Task 7: Ad type filtering

```ruby
# In ads_spec.rb
describe "GET /ads" do
  it "filters by ad type" do
    listing_ad = create(:ad, account: account, adable: create(:listing_ad))
    brand_ad = create(:ad, account: account, adable: create(:brand_ad), headline: "Brand")
    get ads_path, params: { ad_type: "ListingAd" }
    expect(response.body).to include(listing_ad.headline)
    expect(response.body).not_to include("Brand")
  end
end
```

### Task 8: File upload request specs

```ruby
# In ads/listing_ads_spec.rb
it "creates a listing ad with an image" do
  image = fixture_file_upload("test.jpg", "image/jpeg")
  post ads_listing_ads_path, params: {
    ad: { headline: "With Image", layout: "hero", theme: "dark", image: image },
    listing_ad: { listing_id: listing.id, badge: "just_listed" }
  }
  expect(Ad.last.image).to be_attached
end

# In listings_spec.rb
it "creates a listing with photos" do
  photo = fixture_file_upload("test.jpg", "image/jpeg")
  post listings_path, params: {
    listing: { address: "123 Test", price: 500000, status: "active", photos: [photo] }
  }
  expect(Listing.last.photos).to be_attached
end
```

Need to create `spec/fixtures/files/test.jpg` — a tiny 1x1 JPEG for test speed.

### Task 9: Tenant isolation sweep

For every controller, ensure there's at least one spec that tries to
access another account's record and gets 404. Currently missing on:
- `Ads::ListingAdsController` (edit/update)
- `Ads::CollectionAdsController` (edit/update)
- `Ads::AgentAdsController` (edit/update)
- `Ads::BrandAdsController` (edit/update)
- `ScreenPlaylistsController`

### Task 10: PasswordsController

```ruby
describe "GET /passwords/new" do
  it "returns a successful response"
end

describe "POST /passwords" do
  it "sends a password reset email"
  it "redirects even with unknown email (no enumeration)"
end

describe "GET /passwords/:token/edit" do
  it "returns a successful response with valid token"
end

describe "PATCH /passwords/:token" do
  it "resets the password"
  it "rejects invalid token"
end
```

### Task 11: HomeController

```ruby
describe "GET /" do
  it "redirects to login when not authenticated"
  it "returns a successful response when authenticated"
end
```

---

## Phase 4 — CI enforcement

### Task 12: Add SimpleCov to CI workflow

In `.github/workflows/ci.yml` (or equivalent), the test job already
runs rspec. SimpleCov runs automatically and will fail the build if
coverage drops below the threshold. No CI config change needed beyond
ensuring the gem is installed.

### Task 13: Add coverage badge (optional)

If using GitHub Actions, output the coverage percentage and add a badge
to the README. Visible accountability.

### Task 14: Ratchet the threshold

After filling the gaps, the coverage will be higher than 80%. Update
`minimum_coverage` to the new baseline minus 2%. This ratchet means
coverage can only go up — any PR that drops it fails CI.

---

## Build order

| Priority | Tasks | Effort | Impact |
|----------|-------|--------|--------|
| **P0** | SimpleCov install (Tasks 1-3) | 15 min | Measurement baseline |
| **P1** | Scope tests (Task 2) | 30 min | 4 models, 8 scopes — the search/filter UI depends on these |
| **P1** | Tenant isolation sweep (Task 9) | 30 min | Security — prevent data leaks |
| **P1** | File upload specs (Task 8) | 20 min | New feature has zero request-level coverage |
| **P2** | CollectionAd + BrandAd gaps (Tasks 3-4) | 15 min | New models undertested |
| **P2** | Attachment specs (Task 5) | 10 min | Agent and Site photos untested |
| **P2** | Account associations (Task 1) | 10 min | Foundational model |
| **P2** | Ad type filtering (Task 7) | 10 min | Index filter untested |
| **P3** | Session model (Task 6) | 5 min | Minimal model |
| **P3** | PasswordsController (Task 10) | 20 min | Auth edge case |
| **P3** | HomeController (Task 11) | 5 min | Trivial controller |
| **P3** | CI ratchet (Tasks 12-14) | 10 min | Ongoing enforcement |

---

## What this gives us

- **Measurable coverage** — SimpleCov reports exact percentage per file
- **Coverage floor** — CI fails if coverage drops, prevents regressions
- **Scope confidence** — Search, filter, and status scopes tested
- **Tenant safety** — Every controller verified for cross-account isolation
- **Upload confidence** — File uploads tested end-to-end in request specs
- **Ratchet** — Coverage only goes up over time
