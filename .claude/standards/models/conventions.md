# Standard: Model Conventions

## File Ordering

```ruby
class Thing < ApplicationRecord
  # 1. Includes/concerns
  include PublicIdentifiable

  # 2. Gem macros
  has_paper_trail ignore: [:updated_at]
  acts_as_tenant :account

  # 3. Constants
  STATUSES = %w[active inactive].freeze

  # 4. Associations (belongs_to → has_one → has_many → has_many :through)
  belongs_to :parent
  has_one :profile, dependent: :destroy
  has_many :items, dependent: :destroy
  has_many :tags, through: :item_tags

  # 5. Attachments
  has_one_attached :photo

  # 6. Validations
  validates :name, presence: true

  # 7. Scopes
  scope :active, -> { where(status: "active") }

  # 8. Callbacks
  before_create :set_defaults

  # 9. Class methods
  # 10. Instance methods

  private

  # 11. Private methods
end
```

## Validations & Data Integrity

Every presence validation must have a matching `null: false` in
the schema. Every uniqueness validation must have a matching
unique index. These are defense-in-depth — the model catches it
first, the database catches it if the model is bypassed.

```ruby
# Model
validates :email, presence: true, uniqueness: { scope: :account_id }

# Schema
t.string :email, null: false
add_index :agents, [:account_id, :email], unique: true
```

Rules:
- `inclusion` validations reference frozen constants, not inline arrays
- `belongs_to` is required by default — don't add redundant presence validations
- Email fields use `format: { with: URI::MailTo::EMAIL_REGEXP }`
- Monetary values use `decimal(12,2)`, never `float`
- Booleans have `null: false` + `default:` in the schema — no three-state logic

## Associations

Every `has_many` and `has_one` declares `dependent:`:
- `:destroy` — children have their own callbacks/associations
- `:delete_all` — simple children, no callbacks needed
- `:nullify` — child persists without parent
- `:restrict_with_error` — block deletion if children exist
- `:destroy_async` — for high-volume associations on account deletion

Add `inverse_of:` on associations with scopes, `:class_name`, or
`:foreign_key` where Rails can't auto-detect:

```ruby
has_one :active_assignment, -> { active },
        class_name: "ScreenPlayer", inverse_of: :player
```

Use `counter_cache: true` on `belongs_to` when views frequently
call `.size` or `.count` on the parent's association.

## Scopes

- Never use `default_scope`
- All scopes return `ActiveRecord::Relation` (chainable)
- Use `sanitize_sql_like` for ILIKE search scopes
- Name as adjectives/prepositions: `active`, `by_status`, `search`
- Lambda syntax for parameterized scopes

## Callbacks

- `before_create` for token/UUID generation with `||=` guard
- `after_commit` for side effects (mail, broadcast, jobs) — never `after_save`
- Max 1-2 callbacks per lifecycle event
- No business logic — extract to service objects
- No `save`/`update` inside `after_save` (infinite loop risk)

## Multi-Tenant

Every model with `account_id` declares `acts_as_tenant :account`.
Models without `account_id` (User, Session, Player) do not.

Uniqueness validations on tenant-scoped models include
`scope: :account_id`:

```ruby
validates :email, uniqueness: { scope: :account_id }
```

## Security

- `has_secure_password` for password storage
- `SecureRandom.urlsafe_base64(32)` for auth tokens
- `SecureRandom.alphanumeric(6)` acceptable for short-lived codes with expiry
- All tokens have unique indexes
- `public_id` (UUID) on every model — never expose sequential IDs
- `has_paper_trail` on all business models

## Service Objects

Extract from models when logic involves:
- Multi-model orchestration (`AcceptInvite`, `PairPlayerToScreen`)
- External library calls (`ParseDeviceInfo` wraps DeviceDetector)
- Side effects beyond simple data assignment

Models keep: associations, validations, scopes, state queries
(`paired?`, `online?`, `pending?`), simple delegations.

## Testing

Every model has `spec/models/model_name_spec.rb` with:
1. Association tests (shoulda-matchers)
2. Validation tests (shoulda-matchers)
3. Scope tests (matching + non-matching records)
4. Custom method tests (happy path + edge cases)

Factories produce valid records by default. Traits for state
variations (`trait :sold`, `trait :expired`).
