# Plan: Code Organization Standards

## Problem

File structure within models, controllers, routes, specs, factories,
policies, and the Gemfile is inconsistent. Macros, associations,
validations, and methods appear in different orders across files. The
Gemfile has no grouping convention. Routes have inconsistent spacing
and commenting. This makes it harder for developers to quickly find
things and slows down code review.

## Goal

Define canonical ordering for every frequently-edited file type. Audit
the codebase for violations. Fix existing files. The standard prevents
drift on future work.

---

## Standards

### 1. Models

```ruby
class Listing < ApplicationRecord
  # ── Gem macros ──────────────────────────────────────
  acts_as_tenant :account
  has_paper_trail ignore: [:updated_at]

  # ── Constants ───────────────────────────────────────
  STATUSES = %w[active pending sold].freeze

  # ── Enums / store accessors ─────────────────────────
  enum :status, { active: 0, pending: 1, sold: 2 }
  store_accessor :context, :playlist_id

  # ── Associations ────────────────────────────────────
  # belongs_to → has_one → has_many → has_many :through
  belongs_to :account
  has_one :qr_code, as: :destination_record, dependent: :destroy
  has_many :listing_agents, dependent: :destroy
  has_many :agents, through: :listing_agents

  # ── Attachments ─────────────────────────────────────
  has_one_attached :photo
  has_many_attached :photos

  # ── Delegations ─────────────────────────────────────
  delegate :name, to: :account, prefix: true

  # ── Validations ─────────────────────────────────────
  validates :address, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }

  # ── Scopes ──────────────────────────────────────────
  scope :active, -> { where(status: "active") }
  scope :search, ->(q) { where("address ILIKE ?", "%#{q}%") }

  # ── Callbacks ───────────────────────────────────────
  before_create :set_defaults
  after_commit :notify_agents, on: :create

  # ── Class methods ───────────────────────────────────
  def self.recent
    order(created_at: :desc)
  end

  # ── Instance methods ────────────────────────────────
  def primary_agent
    listing_agents.primary.first&.agent
  end

  private

  def set_defaults
    self.status ||= "active"
  end
end
```

**Rules:**
- Section comments use `# ── Name ──` format (optional for small models with < 3 sections)
- Associations ordered: `belongs_to` → `has_one` → `has_many` → `has_many :through`
- Gem macros always first (after any `include`/`extend`)
- Empty lines between sections, no empty lines within a section
- `private` keyword on its own line before private methods

### 2. Controllers

```ruby
class ListingsController < App::BaseController
  # ── Filters ─────────────────────────────────────────
  before_action :set_listing, only: %i[show edit update destroy]

  # ── Actions (REST order) ────────────────────────────
  def index
  end

  def show
  end

  def new
  end

  def create
  end

  def edit
  end

  def update
  end

  def destroy
  end

  # ── Custom actions ──────────────────────────────────
  def preview
  end

  private

  # ── Setters ─────────────────────────────────────────
  def set_listing
    @listing = authorized_scope(Listing.all).find(params[:id])
  end

  # ── Params ──────────────────────────────────────────
  def listing_params
    params.require(:listing).permit(:address, :price, :status)
  end
end
```

**Rules:**
- Actions in REST order: index, show, new, create, edit, update, destroy
- Custom actions after REST actions
- `before_action` / `skip_before_action` at the top
- Private methods: setters first, then params, then helpers
- One blank line between actions

### 3. Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # ── Marketing (root domain) ────────────────────────
  constraints subdomain: "" do
    scope module: "marketing" do
      root "pages#home", as: :marketing_root
      get "/features", to: "pages#features", as: :features
      get "/pricing",  to: "pages#pricing",  as: :pricing
      get "/about",    to: "pages#about",    as: :about
    end
  end

  # ── App (authenticated) ────────────────────────────
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

      # Team
      resources :users
      resources :invites
    end
  end
end
```

**Rules:**
- Each subdomain block has a section comment header
- Resources grouped by domain concept with inline comments
- Nested resources indented under parent
- Consistent spacing between resource groups
- One blank line between groups, no blank lines within a group

### 4. Policies

```ruby
class ListingPolicy < ApplicationPolicy
  # ── Permissions ─────────────────────────────────────
  def show?    = user.can_manage?(account) || owns_listing?
  def create?  = user.can_manage?(account)
  def update?  = user.can_manage?(account)
  def destroy? = user.can_manage?(account)

  # ── Scopes ──────────────────────────────────────────
  scope_for :active_record_relation do |relation|
    if user.can_manage?(account)
      relation
    else
      relation.joins(:listing_agents)
              .where(listing_agents: { agent_id: user.agent_profile&.id })
    end
  end

  private

  def owns_listing?
    record.listing_agents.exists?(agent_id: user.agent_profile&.id)
  end
end
```

**Rules:**
- Permissions first (one-liner style for simple checks)
- Scopes after permissions
- Private helpers last
- Group read permissions (index?, show?) then write (create?, update?, destroy?)

### 5. Specs

```ruby
RSpec.describe Listing do
  # ── Subject / lets ──────────────────────────────────
  subject { build(:listing, account: account) }

  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  # ── Associations ────────────────────────────────────
  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:listing_agents) }
  end

  # ── Validations ─────────────────────────────────────
  describe "validations" do
    it { is_expected.to validate_presence_of(:address) }
  end

  # ── Scopes ──────────────────────────────────────────
  describe ".active" do
    it "returns active listings" do
      # ...
    end
  end

  # ── Instance methods ────────────────────────────────
  describe "#primary_agent" do
    it "returns the primary agent" do
      # ...
    end
  end
end
```

**Rules:**
- `let` declarations at the top: subject → dependencies (account, user) → records
- `describe` blocks mirror the model structure: associations → validations → scopes → methods
- Class methods use `.method_name`, instance methods use `#method_name`
- Shared setup in `before` blocks, not repeated in each `it`

### 6. Factories

```ruby
FactoryBot.define do
  factory :listing do
    # ── Required associations ─────────────────────────
    account

    # ── Required attributes ───────────────────────────
    address { Faker::Address.full_address }
    price { Faker::Number.between(from: 200_000, to: 2_000_000) }
    status { "active" }

    # ── Optional associations ─────────────────────────
    # (none)

    # ── Traits ────────────────────────────────────────
    trait :sold do
      status { "sold" }
    end

    trait :with_photos do
      after(:create) do |listing|
        listing.photos.attach(...)
      end
    end
  end
end
```

**Rules:**
- Associations first (required, then optional)
- Attributes next (required, then optional with defaults)
- Traits last
- Traits ordered: state variations → with_X attachment traits → role traits
- No business logic in factories — keep them simple

### 7. Gemfile

```ruby
source "https://rubygems.org"

# ── Framework ─────────────────────────────────────────
gem "rails", "~> 8.1"
gem "propshaft"
gem "puma", ">= 5.0"

# ── Database ──────────────────────────────────────────
gem "pg", "~> 1.1"
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# ── Frontend ──────────────────────────────────────────
gem "importmap-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "turbo-rails"

# ── Auth & Authorization ──────────────────────────────
gem "action_policy"
gem "acts_as_tenant"
gem "bcrypt", "~> 3.1"
gem "rack-attack"

# ── Content & Media ──────────────────────────────────
gem "chartkick"
gem "groupdate"
gem "image_processing", "~> 2.0"
gem "pagy", "~> 43.6"
gem "paper_trail"
gem "positioning"
gem "rqrcode", "~> 3.2"
gem "ruby-vips", "~> 2.0"

# ── Admin ─────────────────────────────────────────────
gem "administrate"
gem "administrate-field-active_storage"

# ── API & Middleware ──────────────────────────────────
gem "jbuilder"
gem "rack-cors"

# ── Infrastructure ────────────────────────────────────
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false
gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "factory_bot_rails"
  gem "faker"
  gem "rspec-rails", "~> 8.0"
  gem "rubocop-capybara", require: false
  gem "rubocop-factory_bot", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-rspec_rails", require: false
end

group :development do
  gem "letter_opener_web"
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "database_cleaner-active_record"
  gem "selenium-webdriver"
  gem "shoulda-matchers", "~> 8.0"
  gem "simplecov", require: false
end
```

**Rules:**
- Grouped by purpose with `# ── Group ──` section comments
- Alphabetical within each group
- Version constraints only when necessary (not on every gem)
- `group` blocks at the bottom: `:development, :test` → `:development` → `:test`
- Alphabetical within group blocks
- No inline comments on individual gems unless truly necessary

---

## Audit approach

### Rake task

A `docs:audit_organization` Rake task that reads each model and checks:
- Are sections in the expected order?
- Are associations ordered (belongs_to → has_one → has_many)?
- Are gem macros before associations?

This is lightweight pattern matching — not a full parser. It flags files
for manual review rather than auto-fixing.

### Manual audit checklist

For file types that are harder to lint programmatically:

- [ ] Models: all 16+ models follow section ordering
- [ ] Controllers: all controllers follow REST action ordering
- [ ] Routes: subdomain blocks have consistent spacing and comments
- [ ] Policies: permissions before scopes, private last
- [ ] Specs: let ordering, describe structure mirrors model
- [ ] Factories: associations → attributes → traits
- [ ] Gemfile: grouped, alphabetical, consistent comments

---

## Build order

### Phase 1 — Write the standard

1. Create `.claude/standards/code-organization/file-structure.md` with all 7 file type conventions
2. Update `.claude/standards/index.yml` and `CLAUDE.md`
3. Commit

### Phase 2 — Audit and fix models

4. Audit all models against the standard
5. Reorder each model file to match (gem macros → constants → associations → validations → scopes → callbacks → methods)
6. Run tests after each batch
7. Commit

### Phase 3 — Audit and fix controllers

8. Audit all controllers
9. Reorder actions to REST order, group before_actions, organize private methods
10. Run tests
11. Commit

### Phase 4 — Audit and fix Gemfile

12. Reorganize Gemfile into purpose groups
13. Alphabetize within groups
14. Add section comments
15. `bundle install` to verify
16. Commit

### Phase 5 — Audit and fix routes

17. Add consistent section comments within subdomain blocks
18. Group resources by domain concept
19. Consistent spacing
20. Run tests
21. Commit

### Phase 6 — Audit and fix policies, factories, specs

22. Reorder policies: permissions → scopes → private
23. Reorder factories: associations → attributes → traits
24. Spot-check spec ordering (full rewrite not needed — enforce going forward)
25. Run tests
26. Commit

### Phase 7 — Contributing guide

27. Write `docs/contributing.md` — the human-readable "how we work" guide covering:
    - File structure conventions (summary of all 7 file types with examples)
    - Adding a new model / controller / feature (step-by-step)
    - TDD workflow and commit cadence
    - Work lifecycle (branch → plan → build → docs → PR)
    - Linting and testing expectations (`make lint`, `make test`)
    - Where to find things (`.claude/standards/`, `.claude/plans/`, `docs/`)
28. Commit

### Phase 8 — Optional: Rake audit task

29. Write `lib/tasks/audit.rake` with basic model section ordering check
30. Add `make audit` to Makefile
31. Commit

---

## What's deferred

- **Custom RuboCop cops** — could enforce model section ordering automatically, but high effort for limited value. The standard + code review is sufficient.
- **Auto-formatter** — tools like `prettier-ruby` or custom scripts that reorder sections. Risky and hard to maintain.
- **View/partial conventions** — lower frequency, more context-dependent. Document when patterns emerge.
