# Plan v3: Replace Autoincrement IDs with UUIDs

## Context

Every tenant-scoped resource uses autoincrementing BigInt IDs exposed
in URLs, API responses, HTML hidden fields, and analytics params.
Public `/go/` pages are unauthenticated and fully enumerable. This
plan replaces all exposed IDs with UUID `public_id` values across
the entire stack.

No backward compatibility needed — no existing data, QR codes, or
bookmarks to preserve.

---

## Changes from v2

- **Removed Sluggable concern entirely.** UUIDs only — no slugs.
  Simpler, one mechanism for everything. Slugs can be layered on
  later for SEO if needed.

---

## Naming Convention

| Suffix | Meaning | Example | Used where |
|--------|---------|---------|------------|
| `_id` | Integer FK (internal only) | `listing.id` | DB joins, model associations |
| `_pid` | Public ID (UUID string) | `ad_pid` | Analytics events, JS data attributes, API params |
| `_sid` | Signed ID (tamper-proof) | `listing_sid` | Lead form hidden fields |

---

## Approach

**UUID `public_id`** on all tenant-scoped models → non-enumerable
IDs for public URLs, app routes, API responses, analytics, and
form fields.

Integer PKs stay as-is for internal joins and indexes. `to_param`
returns `public_id`, so Rails URL helpers automatically generate
UUID-based URLs everywhere.

---

## Step 1 — `PublicIdentifiable` concern

**New file:** `app/models/concerns/public_identifiable.rb`

Shared concern for all tenant-scoped models. Generates a UUID
`public_id` on create, overrides `to_param`, provides `find_by_param!`.

```ruby
module PublicIdentifiable
  extend ActiveSupport::Concern

  included do
    before_create :set_public_id
    validates :public_id, uniqueness: true, allow_nil: true
  end

  def to_param
    public_id
  end

  class_methods do
    def find_by_param!(value)
      find_by!(public_id: value)
    end
  end

  private

  def set_public_id
    self.public_id ||= SecureRandom.uuid
  end
end
```

**Models to include it:**
- `Listing`, `Agent`, `Ad`, `Lead`, `Playlist`, `Screen`, `Site`,
  `Experience`, `QrCode`, `ScreenContent`

---

## Step 2 — Migration

**New file:** `db/migrate/TIMESTAMP_add_public_ids.rb`

```ruby
class AddPublicIds < ActiveRecord::Migration[8.1]
  def change
    %i[listings agents ads leads playlists screens sites
       experiences qr_codes screen_contents].each do |table|
      add_column table, :public_id, :uuid, default: "gen_random_uuid()", null: false
      add_index table, :public_id, unique: true
    end
  end
end
```

---

## Step 3 — Model changes

All 10 models get one line: `include PublicIdentifiable`

| Model | File |
|-------|------|
| `Listing` | `app/models/listing.rb` |
| `Agent` | `app/models/agent.rb` |
| `Experience` | `app/models/experience.rb` |
| `Ad` | `app/models/ad.rb` |
| `Lead` | `app/models/lead.rb` |
| `Playlist` | `app/models/playlist.rb` |
| `Screen` | `app/models/screen.rb` |
| `Site` | `app/models/site.rb` |
| `QrCode` | `app/models/qr_code.rb` |
| `ScreenContent` | `app/models/screen_content.rb` |

---

## Step 4 — Go controllers (use `find_by_param!`)

| File | Before | After |
|------|--------|-------|
| `app/controllers/go/listings_controller.rb` | `Listing.find(params[:id])` | `Listing.find_by_param!(params[:id])` |
| `app/controllers/go/agents_controller.rb` | `Agent.find(params[:id])` | `Agent.find_by_param!(params[:id])` |
| `app/controllers/go/experiences_controller.rb` | `Experience.find(params[:id])` | `Experience.find_by_param!(params[:id])` |

---

## Step 5 — Lead form (signed IDs)

**File:** `app/views/go/leads/_form.html.erb`

```erb
<%# Before %>
<%= f.hidden_field :listing_id, value: local_assigns[:listing]&.id %>
<%= f.hidden_field :agent_id, value: local_assigns[:agent]&.id %>

<%# After %>
<%= f.hidden_field :listing_sid, value: local_assigns[:listing]&.signed_id(purpose: :lead_form) %>
<%= f.hidden_field :agent_sid, value: local_assigns[:agent]&.signed_id(purpose: :lead_form) %>
```

**File:** `app/controllers/go/leads_controller.rb`

```ruby
# Before
listing = Listing.find_by(id: lead_params[:listing_id])
agent = Agent.find_by(id: lead_params[:agent_id]) || listing&.primary_agent

# After
listing = Listing.find_signed(lead_params[:listing_sid], purpose: :lead_form)
agent = Agent.find_signed(lead_params[:agent_sid], purpose: :lead_form) || listing&.primary_agent
```

Update `lead_params` to permit `:listing_sid`, `:agent_sid` instead
of `:listing_id`, `:agent_id`.

---

## Step 6 — App controllers (use `find_by_param!`)

All `set_*` methods change from `.find(params[:id])` to
`.find_by_param!(params[:id])`:

| File | Method |
|------|--------|
| `app/controllers/app/listings_controller.rb` | `set_listing` |
| `app/controllers/app/agents_controller.rb` | `set_agent` |
| `app/controllers/app/ads_controller.rb` | `set_ad` |
| `app/controllers/app/leads_controller.rb` | `set_lead` |
| `app/controllers/app/playlists_controller.rb` | `set_playlist` |
| `app/controllers/app/screens_controller.rb` | `set_screen` |
| `app/controllers/app/sites_controller.rb` | `set_site` |
| `app/controllers/app/experiences_controller.rb` | `set_experience` |
| `app/controllers/app/qr_codes_controller.rb` | `set_qr_code` |

Since `to_param` returns `public_id`, all URL helpers
(`listing_path(@listing)`) automatically generate UUID-based URLs.
No view changes needed.

---

## Step 7 — Player views (rename data attributes to `_pid`)

**File:** `app/views/play/players/show.html.erb`

```erb
<%# Before %>
data-device-playback-playlist-id-value="<%= @playlist&.id %>"
data-device-playback-screen-id-value="<%= @screen&.id %>"
data-device-playback-screen-content-id-value="<%= @screen&.active_screen_content&.id %>"
data-device-playback-account-id-value="<%= @screen&.site&.account_id %>"
data-ad-id="<%= pa.ad.id %>"

<%# After %>
data-device-playback-playlist-pid-value="<%= @playlist&.public_id %>"
data-device-playback-screen-pid-value="<%= @screen&.public_id %>"
data-device-playback-screen-content-pid-value="<%= @screen&.active_screen_content&.public_id %>"
data-device-playback-account-pid-value="<%= @screen&.site&.account&.public_id %>"
data-ad-pid="<%= pa.ad.public_id %>"
```

**File:** `app/views/play/players/experience.html.erb`

Same pattern — all `*-id-value` data attributes become `*-pid-value`
with `.public_id` values:
- `experience-id-value` → `experience-pid-value`
- `screen-id-value` → `screen-pid-value`
- `screen-content-id-value` → `screen-content-pid-value`
- `account-id-value` → `account-pid-value`

---

## Step 8 — Stimulus controllers (rename values to `_pid`)

**File:** `app/javascript/controllers/device_playback_controller.js`

```javascript
// Before
static values = {
  apiHost: String,
  playerToken: String,
  playlistId: Number,
  screenId: Number,
  screenContentId: Number,
  accountId: Number
}

// After
static values = {
  apiHost: String,
  playerToken: String,
  playlistPid: String,
  screenPid: String,
  screenContentPid: String,
  accountPid: String
}
```

Update all references:
- `this.screenIdValue` → `this.screenPidValue`
- `this.playlistIdValue` → `this.playlistPidValue`
- `this.screenContentIdValue` → `this.screenContentPidValue`
- `this.accountIdValue` → `this.accountPidValue`

In `recordImpression`:
```javascript
// Before
recordImpression({ adId, position, duration }) {
  Analytics.create("content.impressed", {
    ad_id: adId,
    screen_id: this.screenIdValue,
    ...
  })
}

// After
recordImpression({ adPid, position, duration }) {
  Analytics.create("content.impressed", {
    ad_pid: adPid,
    screen_pid: this.screenPidValue,
    screen_content_pid: this.screenContentPidValue,
    playlist_pid: this.playlistPidValue,
    ...
  })
}
```

**File:** `app/javascript/controllers/slideshow_controller.js`

```javascript
// Before
if (!slide.dataset.adId) return
this.dispatch("impression", {
  detail: { adId: slide.dataset.adId, ... }
})

// After
if (!slide.dataset.adPid) return
this.dispatch("impression", {
  detail: { adPid: slide.dataset.adPid, ... }
})
```

**File:** `app/javascript/controllers/experience_controller.js`

```javascript
// Before
static values = {
  ...
  experienceId: Number,
  screenId: Number,
  screenContentId: Number,
  accountId: Number
}

// After
static values = {
  ...
  experiencePid: String,
  screenPid: String,
  screenContentPid: String,
  accountPid: String
}
```

Update all `Analytics.create` calls to use `_pid` keys.

---

## Step 9 — Analytics JS catalog (rename to `_pid`)

**File:** `app/javascript/analytics/catalog.js`

Rename all resource ID properties across every event:
- `ad_id` → `ad_pid`
- `screen_id` → `screen_pid`
- `screen_content_id` → `screen_content_pid`
- `playlist_id` → `playlist_pid`
- `experience_id` → `experience_pid`
- `content_id` → `content_pid`

Non-resource properties stay unchanged: `position`, `duration`,
`direction`, `photo_index`, `target`, `view_duration`, `player_token`,
`content_type`.

---

## Step 10 — Analytics event models (rename to `_pid`, type to `:string`)

All analytics event models rename `_id` attributes to `_pid` and
change type from `:integer` to `:string`:

**`content_impressed.rb`**
```ruby
attribute :ad_pid,             :string
attribute :screen_pid,         :string
attribute :screen_content_pid, :string
attribute :playlist_pid,       :string
attribute :position,           :integer
attribute :duration,           :integer
```

**`content_loaded.rb`**
```ruby
attribute :screen_pid,         :string
attribute :screen_content_pid, :string
attribute :content_type,       :string
attribute :content_pid,        :string
```

**`interaction_started.rb`**
```ruby
attribute :experience_pid,     :string
attribute :screen_pid,         :string
attribute :screen_content_pid, :string
```

**`interaction_ended.rb`**
```ruby
attribute :experience_pid,     :string
attribute :screen_pid,         :string
attribute :screen_content_pid, :string
attribute :duration,           :integer
```

**`interaction_navigated.rb`**
```ruby
attribute :experience_pid,     :string
attribute :screen_content_pid, :string
attribute :direction,          :string
attribute :photo_index,        :integer
```

**`interaction_opened.rb`**
```ruby
attribute :experience_pid,     :string
attribute :screen_content_pid, :string
attribute :target,             :string
```

**`interaction_closed.rb`**
```ruby
attribute :experience_pid,     :string
attribute :screen_content_pid, :string
attribute :target,             :string
attribute :view_duration,      :integer
```

**`device_connected.rb`**
```ruby
attribute :screen_pid,    :string
attribute :player_token,  :string
```

**`qr_scanned.rb`**
```ruby
attribute :qr_code_pid,        :string
attribute :destination_url,    :string
attribute :screen_content_pid, :string
attribute :ad_pid,             :string
attribute :screen_pid,         :string
```

Update the `Scopes` module:
```ruby
module Scopes
  def qualified
    where("properties ? 'ad_pid' AND properties ? 'screen_pid'")
  end
end
```

Update validations in all event models to match new attribute names.

---

## Step 11 — QR scan URL params (plain `_pid` passthrough)

**File:** `app/helpers/qr_helper.rb`

```ruby
# Before
query[:a] = ad.id if ad
query[:s] = screen.id if screen
query[:sc] = screen_content.id if screen_content

# After
query[:a] = ad.public_id if ad
query[:s] = screen.public_id if screen
query[:sc] = screen_content.public_id if screen_content
```

Same query param names, UUID values instead of integers. No signing
needed — UUIDs are not enumerable.

**File:** `app/controllers/scans_controller.rb`

```ruby
# Before
Analytics::Events::QrScanned.create(
  qr_code_id: qr.id,
  destination_url: destination,
  screen_content_id: params[:sc].presence&.to_i,
  ad_id: params[:a].presence&.to_i,
  screen_id: params[:s].presence&.to_i,
  request: request
)

# After
Analytics::Events::QrScanned.create(
  qr_code_pid: qr.public_id,
  destination_url: destination,
  screen_content_pid: params[:sc].presence,
  ad_pid: params[:a].presence,
  screen_pid: params[:s].presence,
  request: request
)
```

No `find`, no `to_i`, no record lookup — pure passthrough.

---

## Step 12 — Manifest API (serve `public_id`)

All Jbuilder manifest templates change `json.id X.id` to
`json.id X.public_id`:

| File | Change |
|------|--------|
| `manifests/show.json.jbuilder` | `@screen_content.id` → `.public_id` |
| `manifests/_ad.json.jbuilder` | `ad.id` → `ad.public_id` |
| `manifests/_agent.json.jbuilder` | `agent.id` → `agent.public_id` |
| `manifests/_experience.json.jbuilder` | `experience.id` → `.public_id`, `experienceable_id` → `.experienceable.public_id` |
| `manifests/_listing.json.jbuilder` | `listing.id` → `listing.public_id` |
| `manifests/_playlist.json.jbuilder` | `playlist.id` → `playlist.public_id` |
| `manifests/_playlist_ad.json.jbuilder` | `playlist_ad.id` → `.public_id` |
| `manifests/_qr_code.json.jbuilder` | `qr_code.id` → `qr_code.public_id` |
| `manifests/ads/_listing_ad.json.jbuilder` | `listing_ad.id` → `.public_id` |
| `manifests/ads/_agent_ad.json.jbuilder` | `agent_ad.id` → `.public_id` |
| `manifests/ads/_brand_ad.json.jbuilder` | `brand_ad.id` → `.public_id` |
| `manifests/ads/_collection_ad.json.jbuilder` | `collection_ad.id` → `.public_id` |
| `manifests/experiences/_listing_experience.json.jbuilder` | `listing_experience.id` → `.public_id` |

---

## Step 13 — Specs

**Factories:** No changes — model callbacks auto-generate `public_id`.

### New specs

**`spec/models/concerns/public_identifiable_spec.rb`**
- Generates UUID on create
- UUID is unique
- `to_param` returns `public_id`
- `find_by_param!` finds by `public_id`
- `find_by_param!` raises RecordNotFound for invalid UUID

### Updated specs

- Go request specs — routes work with UUIDs
- App request specs — routes work with UUIDs
- Lead creation spec — `_sid` fields decode correctly
- Scans spec — `_pid` params pass through to analytics
- Analytics event specs — validate `_pid` attributes

---

## Step 14 — Docs update

Update `CLAUDE.md` and `docs/dev/event-catalog.md` to reflect:
- `_pid` naming convention for analytics
- `_sid` naming convention for lead forms
- `find_by_param!` pattern for controllers
- `PublicIdentifiable` concern

---

## Build Order (TDD)

### Phase A: Foundation (concern + migration)

```
1. RED:  PublicIdentifiable concern spec
2. GREEN: Concern + migration
3. Include concern in all 10 models
4. Run full test suite — fix any to_param breakage in request specs
```

### Phase B: Public pages (Go controllers + lead form)

```
5. RED:  Go listings/agents/experiences specs with UUIDs
6. GREEN: Controllers use find_by_param!
7. RED:  Lead form spec with _sid fields
8. GREEN: Update form + controller
```

### Phase C: App controllers

```
9.  Update all 9 set_* methods to use find_by_param!
10. Run full test suite — fix request spec URL assertions
```

### Phase D: Player + analytics (the _pid rename)

```
11. Update player views (show + experience) data attributes
12. Update Stimulus controllers (values + Analytics.create calls)
13. Update analytics catalog.js
14. Update all 8 analytics event models (_pid, :string)
15. Update QR helper (pass public_id in query params)
16. Update scans controller (passthrough, no lookup)
```

### Phase E: API manifest

```
17. Update all 13 Jbuilder manifest templates
18. Run full test suite
```

---

## Verification

1. `make test` — full suite passes
2. `GET /go/listings/<uuid>` → 200
3. `GET /go/listings/1` → 404
4. `GET /app/listings` → URLs show UUIDs, not integers
5. Submit lead form → signed IDs decode, lead created
6. Scan QR code → UUID params pass through to analytics
7. Player loads playlist → `_pid` in data attributes, impressions tracked with UUIDs
8. Manifest API → returns UUIDs, no integer IDs
9. Ahoy events → properties use `_pid` keys with UUID values

---

## Files Changed Summary

| Category | Files | Count |
|----------|-------|-------|
| New concern | `public_identifiable.rb` | 1 |
| Migration | `add_public_ids.rb` | 1 |
| Models | 10 models get `include` line | 10 |
| Go controllers | `listings`, `agents`, `experiences`, `leads` | 4 |
| Go views | `leads/_form.html.erb` | 1 |
| App controllers | 9 controllers, `set_*` methods | 9 |
| Player views | `show.html.erb`, `experience.html.erb` | 2 |
| Stimulus controllers | `device_playback`, `slideshow`, `experience` | 3 |
| Analytics catalog | `catalog.js` | 1 |
| Analytics events | 8 event model classes | 8 |
| QR helper | `qr_helper.rb` | 1 |
| Scans controller | `scans_controller.rb` | 1 |
| Manifest templates | 13 Jbuilder files | 13 |
| Specs | New concern spec + updated request specs | ~8 |
| Docs | `CLAUDE.md`, `event-catalog.md` | 2 |
| **Total** | | **~65** |
