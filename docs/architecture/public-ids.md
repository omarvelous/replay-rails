# Public IDs

All tenant-scoped models include `PublicIdentifiable`, which adds a UUID `public_id` column used in URLs, API responses, and analytics instead of autoincrementing integer IDs. Integer PKs remain for internal joins and indexes.

## Naming conventions

| Suffix | Meaning | Used in |
|--------|---------|---------|
| `_id` | Integer FK, internal only | DB joins, model associations |
| `_pid` | Public ID (UUID string) | Analytics events, JS data attributes, API params |
| `_sid` | Signed ID (tamper-proof) | Lead form hidden fields |

## PublicIdentifiable concern

```ruby
# app/models/concerns/public_identifiable.rb
module PublicIdentifiable
  extend ActiveSupport::Concern

  included do
    before_create :generate_public_id
  end

  def to_param
    public_id
  end

  class_method def find_by_param!(param)
    find_by!(public_id: param)
  end
end
```

`to_param` returns `public_id`, so all Rails URL helpers automatically generate UUID-based URLs. Controllers use `find_by_param!` to resolve by public ID.

## Controller lookup patterns

```ruby
# App controllers (tenant-scoped)
@listing = Current.account.listings.find_by_param!(params[:id])

# Go controllers (public, no tenant)
@listing = Listing.find_by_param!(params[:id])
```

## Lead form fields

Lead forms use Rails signed IDs (`_sid`) to prevent tampering:

```ruby
# View
f.hidden_field :listing_sid, value: listing.signed_id(purpose: :lead_form)
# Controller
listing = Listing.find_signed(params[:listing_sid], purpose: :lead_form)
```

## Analytics events

Governed event POROs use `_pid` suffix for all resource references:

```ruby
attribute :ad_pid,     :string   # NOT :ad_id
attribute :screen_pid, :string   # NOT :screen_id
```

## Manifest API

The player manifest serves `pid` (not `id`) in JSON responses:

```json
{ "pid": "a1b2c3d4-...", "updated_at": 1726329600 }
```
