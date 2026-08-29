# Standard: File Structure

Canonical ordering for frequently-edited file types. Follow these conventions to keep the codebase consistent and scannable.

## Models

```ruby
class Listing < ApplicationRecord
  # 1. Includes / extends
  # 2. Gem macros (acts_as_tenant, has_paper_trail, positioned, etc.)
  # 3. Constants
  # 4. Enums / store accessors
  # 5. Associations (belongs_to → has_one → has_many → has_many :through)
  # 6. Attachments (has_one_attached, has_many_attached)
  # 7. Delegations
  # 8. Validations
  # 9. Scopes
  # 10. Callbacks
  # 11. Class methods
  # 12. Instance methods
  # 13. Private methods
end
```

**Rules:**
- Associations ordered: `belongs_to` → `has_one` → `has_many` → `has_many :through`
- Gem macros always first (after any `include`/`extend`)
- Empty line between sections
- `private` keyword on its own line before private methods
- Section comments (`# ── Name ──`) optional for small models with < 3 sections

## Controllers

```ruby
class ListingsController < App::BaseController
  # 1. Filters (before_action, skip_before_action, etc.)
  # 2. Actions in REST order: index, show, new, create, edit, update, destroy
  # 3. Custom actions (preview, export, etc.)
  #
  # private
  # 4. Setters (set_listing, set_account)
  # 5. Params (listing_params)
  # 6. Helpers
end
```

**Rules:**
- Actions in REST order: index → show → new → create → edit → update → destroy
- Custom actions after REST actions
- `before_action` at the top
- Private: setters first, then params, then helpers
- One blank line between actions

## Routes

```ruby
constraints subdomain: "app" do
  scope module: "app" do
    root "dashboard#show", as: :app_root

    # Content
    resources :listings
    resources :agents
    resources :ads

    # Playback
    resources :screens
    resources :playlists

    # Engagement
    resources :leads
    resources :qr_codes
  end
end
```

**Rules:**
- Each subdomain block has a section comment header
- Resources grouped by domain concept with inline comments
- Nested resources indented under parent
- One blank line between groups

## Policies

```ruby
class ListingPolicy < ApplicationPolicy
  # 1. Permissions (read first, then write)
  # 2. Scopes
  #
  # private
  # 3. Helper methods
end
```

**Rules:**
- Read permissions first (index?, show?), then write (create?, update?, destroy?)
- One-liner style for simple permission checks
- Scopes after permissions
- Private helpers last

## Specs

```ruby
RSpec.describe Listing do
  # 1. Subject
  # 2. let declarations (dependencies → records)
  # 3. describe "associations"
  # 4. describe "validations"
  # 5. describe ".class_method"
  # 6. describe "#instance_method"
end
```

**Rules:**
- `let` declarations: subject → dependencies (account, user) → records
- `describe` blocks mirror model structure: associations → validations → scopes → methods
- Class methods use `.method_name`, instance methods use `#method_name`
- Shared setup in `before` blocks, not repeated in each `it`

## Factories

```ruby
FactoryBot.define do
  factory :listing do
    # 1. Required associations
    # 2. Required attributes
    # 3. Optional attributes
    # 4. Traits (state variations → with_X → role traits)
  end
end
```

**Rules:**
- Associations first, then attributes, then traits
- Traits ordered: state variations → attachment traits → role traits
- No business logic in factories

## Gemfile

```ruby
source "https://rubygems.org"

# ── Framework ──
# ── Database ──
# ── Frontend ──
# ── Auth & Authorization ──
# ── Content & Media ──
# ── Admin ──
# ── API & Middleware ──
# ── Infrastructure ──

group :development, :test do ... end
group :development do ... end
group :test do ... end
```

**Rules:**
- Grouped by purpose with section comments
- Alphabetical within each group
- Version constraints only when necessary
- `group` blocks at the bottom: `:development, :test` → `:development` → `:test`
- Alphabetical within group blocks
