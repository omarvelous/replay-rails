# Plan: Structured address fields on Listing

## Context

The ad composition system needs to position address parts independently — street on one line at hero size, neighborhood/city below it at subtitle size. Currently `Listing` has a single `address` string ("350 Fifth Ave, New York, NY 10118"). The design spec treats street and neighborhood as separate visual elements with different sizing and color.

## Migration

Add 4 new columns to `listings`:

```ruby
class AddStructuredAddressToListings < ActiveRecord::Migration[8.1]
  def change
    add_column :listings, :street, :string
    add_column :listings, :city, :string
    add_column :listings, :state, :string
    add_column :listings, :zip, :string
    add_column :listings, :neighborhood, :string
  end
end
```

Keep `address` column as the canonical full address (used in search, display elsewhere). The new fields are for structured rendering.

## Model

```ruby
# app/models/listing.rb
validates :street, presence: true
validates :city, presence: true
validates :state, presence: true

# Compose full address from parts when structured fields are present
before_validation :compose_address, if: :street_changed?

def compose_address
  self.address = [street, city, [state, zip].compact.join(" ")].compact.join(", ")
end

# For display: neighborhood line = "Westlake Hills, Austin TX 78746"
def location_line
  parts = [neighborhood, city, [state, zip].compact.join(" ")].compact
  parts.join(", ")
end
```

## Backfill

A one-time task to parse existing `address` strings into structured fields. Simple comma-split heuristic:

```ruby
# lib/tasks/listings.rake
task backfill_address: :environment do
  Listing.where(street: nil).find_each do |listing|
    parts = listing.address.split(", ")
    listing.update_columns(
      street: parts[0],
      city: parts[1],
      state: parts[2]&.split(" ")&.first,
      zip: parts[2]&.split(" ")&.last
    )
  end
end
```

Manual review needed — parsing addresses is fuzzy. This handles the common "Street, City, ST ZIP" format.

## Manifest

Update `app/views/api/v1/players/manifests/_listing.json.jbuilder`:

```ruby
json.street listing.street
json.city listing.city
json.state listing.state
json.zip listing.zip
json.neighborhood listing.neighborhood
# Keep address for backwards compat
json.address listing.address
```

## TypeScript types

Update `player-app/src/types/index.ts` — `ManifestListing`:

```ts
interface ManifestListing {
  // ... existing fields
  street: string | null
  city: string | null
  state: string | null
  zip: string | null
  neighborhood: string | null
}
```

## Address element

Update `player-app/src/components/ads/elements/Address/index.tsx`:

```tsx
interface AddressProps {
  street?: string | null
  city?: string | null
  state?: string | null
  neighborhood?: string | null
  address?: string  // fallback
}

export function Address({ street, city, state, neighborhood, address }: AddressProps) {
  const mainLine = street || address || ""
  const subLine = neighborhood
    ? `${neighborhood}, ${city} ${state}`
    : city ? `${city}, ${state}` : null

  return (
    <div>
      <div style={{ fontSize: "var(--t-address)", fontWeight: 600, ... }}>
        {mainLine}
      </div>
      {subLine && (
        <div style={{ fontSize: "var(--t-sub)", color: "var(--ad-text-muted)", ... }}>
          {subLine}
        </div>
      )}
    </div>
  )
}
```

## Compositions

Update Overlay and Split compositions to pass structured fields:

```tsx
<Address
  street={listing.street}
  city={listing.city}
  state={listing.state}
  neighborhood={listing.neighborhood}
  address={listing.address}
/>
```

Falls back to `listing.address` if structured fields aren't populated yet.

## Update mocks

Update `player-app/src/__mocks__/manifest.ts` — `mockListing`:

```ts
export function mockListing(overrides?: Partial<ManifestListing>): ManifestListing {
  return {
    // ...existing
    street: "350 Fifth Ave",
    city: "New York",
    state: "NY",
    zip: "10118",
    neighborhood: "Midtown Manhattan",
    ...overrides,
  }
}
```

## Files to modify

- `db/migrate/XXXX_add_structured_address_to_listings.rb` (new)
- `app/models/listing.rb`
- `app/views/api/v1/players/manifests/_listing.json.jbuilder`
- `player-app/src/types/index.ts`
- `player-app/src/components/ads/elements/Address/index.tsx`
- `player-app/src/components/ads/Overlay/Landscape/index.tsx`
- `player-app/src/components/ads/Overlay/Portrait/index.tsx`
- `player-app/src/components/ads/Split/Landscape/index.tsx`
- `player-app/src/components/ads/Split/Portrait/index.tsx`
- `player-app/src/__mocks__/manifest.ts`
- `spec/factories/listings.rb` (update factory)
- `lib/tasks/listings.rake` (new — backfill task)

## Verification

1. `make migrate` — migration runs
2. `make test` — existing specs pass
3. React build passes
4. Storybook shows street + neighborhood as separate lines
5. Backfill task parses existing addresses correctly
