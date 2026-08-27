# Plan: Namespace Adables under `Ads::`

## What changes

| Before | After |
|--------|-------|
| `ListingAd` | `Ads::ListingAd` |
| `CollectionAd` | `Ads::CollectionAd` |
| `AgentAd` | `Ads::AgentAd` |
| `BrandAd` | `Ads::BrandAd` |
| `CollectionAdAd` | `Ads::CollectionAdAd` |

Tables stay the same (`listing_ads`, `collection_ads`, etc.).
The `Ads` module wraps the classes but doesn't change the table name.

---

## Every file that moves

### Models

```
app/models/listing_ad.rb       → app/models/ads/listing_ad.rb
app/models/collection_ad.rb    → app/models/ads/collection_ad.rb
app/models/agent_ad.rb         → app/models/ads/agent_ad.rb
app/models/brand_ad.rb         → app/models/ads/brand_ad.rb
app/models/collection_ad_ad.rb → app/models/ads/collection_ad_ad.rb
```

Each model gets `module Ads` wrapper:
```ruby
module Ads
  class ListingAd < ApplicationRecord
    # ... existing code
  end
end
```

### Ad model update

```ruby
# app/models/ad.rb
delegated_type :adable, types: %w[
  Ads::ListingAd
  Ads::CollectionAd
  Ads::AgentAd
  Ads::BrandAd
], dependent: :destroy
```

### Data migration

The `adable_type` column in the `ads` table stores the class name.
Existing data has `"ListingAd"` — needs to become `"Ads::ListingAd"`.

```ruby
class NamespaceAdableTypes < ActiveRecord::Migration[8.1]
  def up
    {
      "ListingAd"      => "Ads::ListingAd",
      "CollectionAd"   => "Ads::CollectionAd",
      "AgentAd"        => "Ads::AgentAd",
      "BrandAd"        => "Ads::BrandAd",
    }.each do |old_type, new_type|
      Ad.where(adable_type: old_type).update_all(adable_type: new_type)
    end
  end

  def down
    {
      "Ads::ListingAd"      => "ListingAd",
      "Ads::CollectionAd"   => "CollectionAd",
      "Ads::AgentAd"        => "AgentAd",
      "Ads::BrandAd"        => "BrandAd",
    }.each do |old_type, new_type|
      Ad.where(adable_type: old_type).update_all(adable_type: new_type)
    end
  end
end
```

### Factories

```
spec/factories/listing_ads.rb       → spec/factories/ads/listing_ads.rb
spec/factories/collection_ads.rb    → spec/factories/ads/collection_ads.rb
spec/factories/agent_ads.rb         → spec/factories/ads/agent_ads.rb
spec/factories/brand_ads.rb         → spec/factories/ads/brand_ads.rb
spec/factories/collection_ad_ads.rb → spec/factories/ads/collection_ad_ads.rb
```

Factory names stay the same (`:listing_ad`, etc.) — FactoryBot resolves
by name, not class. But each factory needs `class { Ads::ListingAd }`:

```ruby
FactoryBot.define do
  factory :listing_ad, class: "Ads::ListingAd" do
    # ...
  end
end
```

### Specs

```
spec/models/listing_ad_spec.rb       → spec/models/ads/listing_ad_spec.rb
spec/models/collection_ad_spec.rb    → spec/models/ads/collection_ad_spec.rb
spec/models/agent_ad_spec.rb         → spec/models/ads/agent_ad_spec.rb
spec/models/brand_ad_spec.rb         → spec/models/ads/brand_ad_spec.rb
spec/models/collection_ad_ad_spec.rb → spec/models/ads/collection_ad_ad_spec.rb
```

`RSpec.describe ListingAd` → `RSpec.describe Ads::ListingAd`

### Controllers (already namespaced)

App controllers are already under `App::Ads::`:
```
app/controllers/app/ads/listing_ads_controller.rb
```

These reference `ListingAd` directly — needs to become `Ads::ListingAd`:
```ruby
# Before
@listing_ad = ListingAd.new(listing_ad_params)

# After
@listing_ad = Ads::ListingAd.new(listing_ad_params)
```

Admin controllers (Administrate) reference the models too.
Dashboard files reference `Ads::ListingAd` constants.

### Views

Content partials are at:
```
app/views/app/ads/listing_ads/_content.html.erb
```

The render call uses `ad.adable_name.pluralize`:
```erb
<%= render "app/ads/#{ad.adable_name.pluralize}/content", ad: ad %>
```

With `Ads::ListingAd`, `adable_name` returns `"ads_listing_ad"`.
Pluralized: `"ads_listing_ads"`. The render looks for:
```
app/views/app/ads/ads_listing_ads/_content.html.erb
```

**Approach: Move views to match the namespace.**

Views move into an `ads/` subdirectory under the existing `ads/` layout
directory, mirroring the model namespace:

```
app/views/app/ads/listing_ads/     → app/views/app/ads/ads/listing_ads/
app/views/app/ads/collection_ads/  → app/views/app/ads/ads/collection_ads/
app/views/app/ads/agent_ads/       → app/views/app/ads/ads/agent_ads/
app/views/app/ads/brand_ads/       → app/views/app/ads/ads/brand_ads/
```

With `Ads::ListingAd`, `adable_name` returns `"ads_listing_ad"`.
The render call `ad.adable_name.pluralize` gives `"ads_listing_ads"`.

But we want the path to use `/` not `_`. So we use a helper:

```ruby
# app/models/ad.rb
def adable_partial_path
  adable.class.name.underscore.pluralize  # "ads/listing_ads"
end
```

Render calls become:
```erb
<%= render "app/ads/#{ad.adable_partial_path}/content", ad: ad %>
```

This resolves to `app/views/app/ads/ads/listing_ads/_content.html.erb` —
properly namespaced, colocated under `ads/ads/`.

### Seeds

```ruby
# Before
listing_ad = ListingAd.create!(listing: fifth_ave, badge: "just_listed")

# After
listing_ad = Ads::ListingAd.create!(listing: fifth_ave, badge: "just_listed")
```

### Ad model convenience method

```ruby
# app/models/ad.rb — update listing delegation
def listing
  adable.try(:listing)
end
```
No change needed — `try` works regardless of namespace.

### Administrate dashboards

Dashboard files reference constants:
```ruby
# Before
class ListingAdDashboard < Administrate::BaseDashboard

# After
class Ads::ListingAdDashboard < Administrate::BaseDashboard
```

Wait — Administrate expects dashboards at `app/dashboards/`. With
namespaced models, the dashboard should be at:
```
app/dashboards/ads/listing_ad_dashboard.rb → Ads::ListingAdDashboard
```

Or we keep them flat with the class name matching:
```
app/dashboards/ads_listing_ad_dashboard.rb → AdsListingAdDashboard
```

Administrate resolves dashboards by convention: `ModelName` + `Dashboard`.
For `Ads::ListingAd`, it looks for `Ads::ListingAdDashboard` at
`app/dashboards/ads/listing_ad_dashboard.rb`.

### Other references to grep for

```bash
grep -rn "ListingAd\b" app/ spec/ --include="*.rb" --include="*.erb"
grep -rn "CollectionAd\b" app/ spec/ --include="*.rb" --include="*.erb"
grep -rn "AgentAd\b" app/ spec/ --include="*.rb" --include="*.erb"
grep -rn "BrandAd\b" app/ spec/ --include="*.rb" --include="*.erb"
grep -rn "CollectionAdAd\b" app/ spec/ --include="*.rb" --include="*.erb"
```

Every match needs `Ads::` prefix (except inside the `module Ads` block
itself and string references like `"ListingAd"` in delegated_type).

---

## What does NOT change

- Table names: `listing_ads`, `collection_ads`, etc.
- URL paths: `/ads/listing_ads/new` etc.
- Route helpers: `ads_listing_ads_path`, `new_ads_listing_ad_path`
- Controller file locations (already under `app/ads/`)
- The `Ad` base model file location
- Layout partials (`_hero`, `_split`, etc.) — stay at `app/views/app/ads/layouts/`
- Shared form partials — stay at `app/views/app/ads/shared/`

---

## Build order

### Phase 1 — Models
1. Create `app/models/ads/` directory
2. Move 5 model files, wrap in `module Ads`
3. Update `Ad#delegated_type` types list
4. Add `Ad#adable_partial_path` helper for view lookup

### Phase 2 — Views
5. Create `app/views/app/ads/ads/` directory
6. Move type-specific view dirs into it:
   ```
   app/views/app/ads/listing_ads/ → app/views/app/ads/ads/listing_ads/
   app/views/app/ads/collection_ads/ → app/views/app/ads/ads/collection_ads/
   app/views/app/ads/agent_ads/ → app/views/app/ads/ads/agent_ads/
   app/views/app/ads/brand_ads/ → app/views/app/ads/ads/brand_ads/
   ```
7. Update all render calls: `ad.adable_name.pluralize` → `ad.adable_partial_path`
8. Update layout partials that render content partials
9. Update player_api play view

### Phase 3 — Controllers
10. Update all `ListingAd` → `Ads::ListingAd` references in controllers
11. Update `App::Ads::*Controller` files
12. Update `App::AdsController`

### Phase 4 — Factories + specs
13. Move factory files to `spec/factories/ads/`, add `class: "Ads::ListingAd"`
14. Move spec files to `spec/models/ads/`, update `RSpec.describe`
15. Update all inline references in specs

### Phase 5 — Dashboards
16. Move Administrate dashboard files to `app/dashboards/ads/`
17. Namespace dashboard classes under `Ads::`
18. Update admin controllers to match

### Phase 6 — Seeds + cleanup
19. Update seeds with `Ads::` prefix
20. Grep audit: ensure no un-namespaced references remain
21. `db:reset` to re-seed with new type names
22. Run full suite — 0 failures
23. Verify coverage above thresholds

---

## Grep audit (run before and after)

```bash
# Before: count all references
grep -rn "ListingAd\|CollectionAd\|AgentAd\|BrandAd\|CollectionAdAd" \
  app/ spec/ --include="*.rb" --include="*.erb" | wc -l

# After: ensure no un-namespaced references remain (except inside module blocks)
grep -rn "\bListingAd\b" app/ spec/ --include="*.rb" --include="*.erb" | \
  grep -v "module Ads" | grep -v "Ads::ListingAd"
```
