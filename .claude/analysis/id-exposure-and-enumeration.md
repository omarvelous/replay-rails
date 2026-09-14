# Analysis: Autoincrement ID Exposure in a Multi-Tenant App

## The Problem

Every table in RePlay uses autoincrementing BigInt primary keys.
These IDs are sequential, predictable, and exposed in URLs, API
responses, HTML forms, and query parameters across the entire app.

In a multi-tenant application, this creates three categories of risk:

### 1. Enumeration (IDOR)

Sequential IDs let attackers walk through resources:

```
GET /go/listings/1    → Listing exists (200)
GET /go/listings/2    → Listing exists (200)
GET /go/listings/3    → Not found (404)
GET /go/listings/4    → Listing exists (200)
```

The `/go/` pages are **public, unauthenticated, and not tenant-scoped**.
Anyone can enumerate every listing and agent across every account in
the system by incrementing the ID.

### 2. Information Leakage

Sequential IDs reveal business intelligence:

- Competitor creates an account → sees their listing is ID 847 →
  knows there are ~846 listings in the system
- Creates another listing a week later → ID 863 → knows 16 listings
  were created that week
- Same logic applies to leads, ads, agents, accounts — growth rates,
  volume, and activity patterns are all inferrable

### 3. Cross-Tenant Reference Attacks

Even with `acts_as_tenant` scoping, IDs leak across boundaries:

- Public lead form has `<input type="hidden" name="listing_id" value="42">`
- Attacker changes it to `value="43"` (a listing from a different account)
- If the controller doesn't validate ownership, the lead is attached
  to the wrong listing

---

## Current Exposure Audit

### Critical — Public, Unauthenticated, Enumerable

| Endpoint | What's Exposed | Risk |
|----------|---------------|------|
| `GET /go/listings/:id` | Any listing, any account | Full enumeration of all listings |
| `GET /go/agents/:id` | Any agent, any account | Full enumeration of all agents |
| `GET /go/experiences/:id` | Any experience, any account | Full enumeration of all experiences |
| `POST /go/leads` (hidden fields) | `listing_id`, `agent_id` in HTML source | ID harvesting from page source |
| `GET /s/:token?a=1&s=2&sc=3` | Ad, screen, screen_content IDs in query params | Analytics poisoning, ID mapping |

### Medium — Authenticated but Leaky

| Endpoint | What's Exposed | Risk |
|----------|---------------|------|
| `GET /app/listings/:id` | Listing ID in URL | Tenant-scoped, but ID is visible and predictable |
| `GET /app/ads/:id` | Ad ID in URL | Same |
| `GET /app/leads/:id` | Lead ID in URL | Same |
| Manifest API JSON | playlist.id, ad.id, screen_content.id | Device with valid token sees all content IDs |
| Player status API | `screen_id` in JSON response | Leaks screen ID to device |

### Already Secure

| Endpoint | How | Why It Works |
|----------|-----|--------------|
| `GET /play/players/:token` | Cryptographic token (32 bytes) | Not enumerable |
| `GET /s/:token` | QR code token (8 bytes) | Not enumerable |
| Invite acceptance | Token-based | Not enumerable |
| Pairing flow | 6-char code + 10-min expiry | Rate-limited window |

---

## Solutions

### Solution 1: Slugs for Public URLs

Replace integer IDs with human-readable slugs on public-facing
resources. This is the highest-impact, lowest-risk change.

**Before:**
```
/go/listings/42
/go/agents/17
```

**After:**
```
/go/listings/1234-oceanview-dr-malibu
/go/agents/sarah-johnson
```

**Implementation:**

```ruby
# app/models/listing.rb
before_validation :generate_slug, on: :create

def generate_slug
  base = address.parameterize
  self.slug = base
  # Handle collisions
  counter = 1
  while Listing.exists?(slug: slug)
    self.slug = "#{base}-#{counter}"
    counter += 1
  end
end

def to_param
  slug
end
```

```ruby
# Migration
add_column :listings, :slug, :string
add_index :listings, :slug, unique: true

add_column :agents, :slug, :string
add_index :agents, :slug, unique: true
```

```ruby
# Controller
def show
  @listing = Listing.find_by!(slug: params[:id])
end
```

**Pros:**
- SEO-friendly URLs
- Not enumerable (can't increment a slug)
- Human-readable (agents can share links verbally)
- Low migration cost — only public controllers change
- Internal app routes can stay ID-based (they're tenant-scoped)

**Cons:**
- Slug collisions need handling (two "123 Main St" listings)
- Slugs need to be immutable or have redirects for old slugs
- Doesn't solve the information leakage problem (just obscures it)
- Need to backfill slugs for existing records

**Best for:** Public-facing URLs (`/go/` pages). This is the
minimum viable fix and should be done regardless of other changes.

---

### Solution 2: UUIDs as Public Identifiers

Add a UUID column to tenant-scoped models. Use UUIDs in URLs and
API responses. Keep the integer PK for internal joins and indexes.

**Before:**
```
/go/listings/42
/app/listings/42
```

**After:**
```
/go/listings/a1b2c3d4-e5f6-7890-abcd-ef1234567890
/app/listings/a1b2c3d4-e5f6-7890-abcd-ef1234567890
```

**Implementation:**

```ruby
# Migration
add_column :listings, :public_id, :uuid, default: "gen_random_uuid()", null: false
add_index :listings, :public_id, unique: true

# Repeat for: agents, ads, leads, playlists, screens, sites,
# experiences, qr_codes
```

```ruby
# app/models/concerns/public_identifiable.rb
module PublicIdentifiable
  extend ActiveSupport::Concern

  included do
    before_create :set_public_id
  end

  def to_param
    public_id
  end

  private

  def set_public_id
    self.public_id ||= SecureRandom.uuid
  end
end
```

```ruby
# app/models/listing.rb
class Listing < ApplicationRecord
  include PublicIdentifiable
  # ...
end
```

```ruby
# Controllers — find by public_id instead of id
def set_listing
  @listing = Current.account.listings.find_by!(public_id: params[:id])
end
```

**Pros:**
- Not enumerable (UUIDs are random, 2^122 possible values)
- No information leakage (can't infer volume or growth)
- Works for both public and authenticated routes
- PostgreSQL has native UUID support (`gen_random_uuid()`)
- Can be added incrementally without changing primary keys

**Cons:**
- UUIDs are ugly in URLs (`/listings/a1b2c3d4-...` vs `/listings/42`)
- Slightly slower lookups than integer PKs (but with an index, negligible)
- Need to backfill existing records
- Need to update all `find(params[:id])` calls to `find_by!(public_id:)`
- API consumers need to update if they cache by ID

**Best for:** API responses, internal app routes, any context where
human-readability doesn't matter.

---

### Solution 3: Hashids / Sqids (Obfuscated Integer IDs)

Encode integer IDs into short, non-sequential strings. The database
stays integer-based; encoding/decoding happens at the controller layer.

**Before:**
```
/go/listings/42
```

**After:**
```
/go/listings/xR3j9
```

**Implementation:**

```ruby
# Gemfile
gem "sqids"

# config/initializers/sqids.rb
SQIDS = Sqids.new(min_length: 6, alphabet: "abcdefghijklmnopqrstuvwxyz0123456789")

# app/models/concerns/sqid_param.rb
module SqidParam
  def to_param
    SQIDS.encode([id])
  end

  def self.decode(param)
    SQIDS.decode(param).first
  end
end

# app/models/listing.rb
class Listing < ApplicationRecord
  include SqidParam
end

# Controller
def set_listing
  id = SqidParam.decode(params[:id])
  @listing = Current.account.listings.find(id)
end
```

**Pros:**
- Zero database changes — no migration, no new columns
- Short, URL-friendly strings (`xR3j9` vs UUID)
- Reversible — decode in the controller, query by integer PK
  (fastest possible lookup)
- Drop-in — add `to_param` to models, update controller `find` calls
- Can use a per-model salt so listing `xR3j9` and agent `xR3j9`
  decode to different integers

**Cons:**
- Security through obscurity — the encoding is reversible by anyone
  who knows the algorithm and salt. Not cryptographically secure.
- If the salt leaks (it's in source code), all IDs are decodable
- Doesn't prevent a determined attacker (they can still try random
  strings, though the space is much larger than 1-N)
- Need to update all URL helpers and controller lookups
- Third-party gem dependency

**Best for:** Quick win to prevent casual enumeration. Not a
long-term security solution, but dramatically raises the bar vs
raw integers.

---

### Solution 4: UUIDs as Primary Keys (Full Migration)

Replace integer primary keys with UUIDs on all tenant-scoped tables.
The most thorough solution but the most disruptive migration.

**Implementation:**

```ruby
# config/initializers/generators.rb
Rails.application.config.generators do |g|
  g.orm :active_record, primary_key_type: :uuid
end

# Migration for each table (listing as example)
class MigrateListingsToUuid < ActiveRecord::Migration[8.1]
  def up
    add_column :listings, :new_id, :uuid, default: "gen_random_uuid()", null: false

    # Update all foreign keys that reference listings
    add_column :listing_agents, :new_listing_id, :uuid
    execute "UPDATE listing_agents SET new_listing_id = listings.new_id FROM listings WHERE listing_agents.listing_id = listings.id"

    # ... repeat for all FK references ...

    # Swap columns
    rename_column :listings, :id, :old_id
    rename_column :listings, :new_id, :id
    # ... update PKs, FKs, indexes ...
  end
end
```

**Pros:**
- Complete solution — IDs are non-enumerable everywhere
- No dual-column confusion (one ID per record)
- Future tables automatically use UUIDs
- PostgreSQL UUIDs are indexable and performant
- Standard Rails pattern (well-documented)

**Cons:**
- **Extremely disruptive migration.** Every foreign key, every join,
  every `belongs_to` reference needs updating. For RePlay's schema
  (30+ tables, 50+ foreign keys), this is a multi-day migration
  with high risk of data loss.
- **Breaks PaperTrail history.** Version records reference integer
  IDs that no longer exist.
- **Breaks all cached URLs, bookmarks, browser history.**
- **UUIDs are 128 bits vs 64 bits.** Slightly larger indexes and
  slower joins (marginal in practice).
- **No ordering by ID.** `Listing.last` no longer returns the most
  recently created record (use `created_at` ordering instead — you
  should be doing this anyway).
- **Breaks seed data.** Any hardcoded IDs in seeds, fixtures, or
  tests need updating.

**Best for:** Greenfield projects or apps early enough in their
lifecycle that the migration cost is low. **Not recommended for
RePlay at this stage** — the disruption outweighs the benefit vs.
Solution 2 (UUID as secondary column).

---

### Solution 5: Signed/Encrypted IDs in URLs

Use Rails' built-in `MessageVerifier` or `MessageEncryptor` to sign
or encrypt IDs in URLs. The server can decode them, but clients
cannot forge or enumerate them.

**Implementation:**

```ruby
# app/models/concerns/signed_param.rb
module SignedParam
  extend ActiveSupport::Concern

  class_methods do
    def signed_id_verifier
      @signed_id_verifier ||= Rails.application.message_verifier("#{name}/signed_param")
    end

    def find_signed!(param)
      id = signed_id_verifier.verify(param)
      find(id)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      raise ActiveRecord::RecordNotFound
    end
  end

  def signed_param
    self.class.signed_id_verifier.generate(id)
  end

  def to_param
    signed_param
  end
end
```

**Note:** Rails 7+ already has `find_signed` and `signed_id` built
into ActiveRecord. These use `ActiveRecord::SignedId` and can be
configured with a purpose and expiry.

```ruby
# Built-in Rails signed IDs
listing = Listing.find(42)
listing.signed_id                          # => "eyJfcm..."
listing.signed_id(purpose: :public_view)   # => "eyJfcm..." (scoped)
listing.signed_id(expires_in: 1.hour)      # => "eyJfcm..." (expiring)

Listing.find_signed("eyJfcm...")           # => #<Listing id: 42>
Listing.find_signed!("eyJfcm...")          # => raises if invalid
```

**Pros:**
- **Zero database changes.** No migrations, no new columns.
- **Cryptographically secure.** Can't be forged without the app's
  secret key. Can't be decoded client-side.
- **Built into Rails.** No gem dependency.
- **Expiring IDs.** Can create time-limited URLs (useful for QR scan
  analytics params).
- **Scoped purposes.** Different signatures for different contexts
  (a listing ID for a public page vs. a lead form).

**Cons:**
- **Long, ugly URLs.** Signed IDs are Base64-encoded and long:
  `/go/listings/eyJfcmFpbHMiOnsiZGF0YSI6NDIsInB1ciI6InB...`
- **Not cacheable across deploys.** If the secret key rotates, all
  signed URLs break.
- **Server-side decode required.** Can't inspect the URL to know
  what resource it points to (debugging is harder).
- **Not SEO-friendly.** Search engines can't parse or index them.

**Best for:** Ephemeral or sensitive URLs (analytics params, form
hidden fields, API tokens). Not ideal for permanent public URLs.

---

## Recommended Approach: Layered Strategy

No single solution covers every surface. The right answer is to
use different strategies for different exposure levels:

### Layer 1: Slugs for Public Go Pages (Do First)

| Resource | Slug Format | Example |
|----------|-------------|---------|
| Listing | Address-based | `/go/listings/1234-oceanview-dr-malibu-ca` |
| Agent | Name-based | `/go/agents/sarah-johnson` |
| Experience | Listing name | `/go/experiences/1234-oceanview-open-house` |

**Why first:** These are the most critical exposure — public,
unauthenticated, and currently enumerable. Slugs are SEO-friendly,
human-shareable, and completely non-enumerable.

**Effort:** Small. Add slug columns, generate on create, update
3 controllers and their views.

### Layer 2: UUID `public_id` for App Routes & API (Do Second)

Add a `public_id` UUID column to all tenant-scoped models. Use it
in authenticated app URLs and API responses.

```
/app/listings/a1b2c3d4-e5f6-... (instead of /app/listings/42)
```

**Why second:** Prevents information leakage in authenticated
contexts. Stops a curious agent from knowing that listing 847
means there are ~846 listings in the system.

**Effort:** Medium. Migration to add columns, concern for shared
behavior, update all `find` calls and `to_param` overrides.

**Models to migrate (priority order):**
1. Listing, Agent (public-facing)
2. Lead, Ad, Playlist (business-sensitive)
3. Screen, Site, QrCode (operational)
4. Experience, Invite (lower volume)

### Layer 3: Signed IDs for Hidden Fields & Analytics Params (Do Third)

Replace raw IDs in form hidden fields and QR scan query parameters
with Rails signed IDs.

**Before:**
```html
<input type="hidden" name="listing_id" value="42">
```
```
/s/abc123?a=42&s=17&sc=5
```

**After:**
```html
<input type="hidden" name="listing_sid" value="eyJfcm...">
```
```
/s/abc123?ctx=eyJfcm...  (signed blob containing a, s, sc)
```

**Why third:** Prevents parameter tampering on public forms and
analytics poisoning via QR scan URLs.

**Effort:** Small. Use Rails' built-in `signed_id` for form fields.
Bundle analytics params into a single signed token.

### Layer 4: Scrub IDs from API Responses (Do Fourth)

Replace integer IDs in manifest and player API responses with
`public_id` UUIDs (from Layer 2).

**Before:**
```json
{ "id": 42, "screen_id": 17, "playlist": { "id": 5 } }
```

**After:**
```json
{ "id": "a1b2c3d4-...", "playlist": { "id": "e5f6g7h8-..." } }
```

**Why fourth:** The manifest API is token-authenticated and lower
risk than public URLs, but still leaks integer IDs to devices.

**Effort:** Small once Layer 2 is done. Update Jbuilder templates
to use `public_id` instead of `id`.

---

## Migration Plan

### Phase 1: Slugs (1-2 days)

```
1. Add slug columns to listings, agents, experiences
2. Write slug generation logic (address-based, name-based)
3. Backfill slugs for existing records
4. Update Go controllers to find_by!(slug:)
5. Update Go views to use slug-based paths
6. Add unique indexes on slug columns
7. Handle slug collisions (append counter or short hash)
```

### Phase 2: Public IDs (2-3 days)

```
1. Create PublicIdentifiable concern
2. Add public_id UUID columns to all tenant-scoped models
3. Backfill UUIDs for existing records
4. Update App controllers to find_by!(public_id:)
5. Update to_param on models
6. Update views that generate links
7. Update Jbuilder templates for API responses
```

### Phase 3: Signed Form Fields (1 day)

```
1. Replace hidden listing_id/agent_id with signed equivalents
2. Update lead creation controller to decode signed IDs
3. Bundle QR scan analytics params into a signed context token
4. Update scans controller to decode signed context
```

### Phase 4: Verify & Harden (1 day)

```
1. Audit all routes for remaining integer ID exposure
2. Add request specs for enumeration resistance
3. Test that old integer-based URLs return 404 (not redirect)
4. Verify PaperTrail, Administrate, and admin still work
   (admin can keep using integer IDs internally)
```

---

## What NOT to Do

- **Don't migrate primary keys to UUID.** Too disruptive for the
  benefit. Adding a secondary `public_id` column gets 95% of the
  security benefit at 10% of the migration cost.

- **Don't use Hashids/Sqids as your only protection.** They're
  reversible — anyone who reads your source code (or guesses the
  algorithm) can decode them. They're fine as a convenience layer
  but not a security boundary.

- **Don't ignore the admin panel.** Admin bypasses tenant scoping
  by design. This is acceptable but needs audit logging. Don't
  expose admin to non-superusers.

- **Don't break existing QR codes.** QR codes already use tokens,
  not IDs. But the analytics params on QR scan URLs use IDs. When
  you sign those params (Phase 3), ensure backward compatibility
  for already-printed QR codes.

---

## Quick Wins (Can Do Today)

Even before the full migration, these changes reduce exposure
immediately:

1. **Rate-limit `/go/` endpoints.** Add Rack::Attack throttle to
   prevent automated enumeration:
   ```ruby
   throttle("go/listings", limit: 30, period: 1.minute) do |req|
     req.ip if req.path.start_with?("/go/listings")
   end
   ```

2. **Remove IDs from lead form hidden fields.** Use the listing
   slug (once available) or a signed token instead of raw integer.

3. **Validate analytics params server-side.** In the scans
   controller, verify that the `ad_id`, `screen_id`, and
   `screen_content_id` params actually belong to the QR code's
   account. Reject mismatches silently.

4. **Don't return `screen_id` in player status API.** The device
   doesn't need the screen's integer ID — it already has a token.
