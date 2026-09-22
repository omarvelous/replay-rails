# Plan: Touchpoints — Unified Lead Capture with QR, NFC, SMS

## Context

Lead capture currently runs through `QrCode` — a model that holds
destination, creative context, and a token for URL-based scanning.
NFC tags and SMS keywords are planned channels that share the same
destination resolution pattern.

Rather than duplicate destination logic across three models, unify
under a `Touchpoint` base model with `delegated_type :channelable`
for channel-specific data. Same pattern as `Ad → adable` and
`Experience → experienceable`.

No historical data to migrate. Fresh implementation.

---

## Data Model

### Touchpoint (shared base)

```ruby
class Touchpoint < ApplicationRecord
  include PublicIdentifiable
  acts_as_tenant :account

  delegated_type :channelable, types: %w[
    Channels::QrCode
    Channels::NfcTag
    Channels::SmsKeyword
  ], dependent: :destroy

  belongs_to :destination_record, polymorphic: true, optional: true

  validates :destination_url, format: { with: /\Ahttps?:\/\/\S+\z/i },
            allow_blank: true

  scope :active, -> { where(active: true) }

  def destination_url
    super.presence || resolve_destination_record
  end

  def destination?
    read_attribute(:destination_url).present? || destination_record.present?
  end

  private

  def resolve_destination_record
    return unless destination_record
    Rails.application.routes.url_helpers
         .polymorphic_url([:go, destination_record], subdomain: "")
  end
end
```

**Columns:**
- `account_id` (FK, not null)
- `channelable_type`, `channelable_id` (delegated type)
- `destination_record_type`, `destination_record_id` (polymorphic)
- `destination_url` (string, optional override)
- `label` (string — "Front window", "Table tent #3")
- `active` (boolean, default: true)
- `public_id` (UUID)

### Channels::QrCode

```ruby
module Channels
  class QrCode < ApplicationRecord
    include PublicIdentifiable

    has_one :touchpoint, as: :channelable, dependent: :destroy, touch: true

    belongs_to :creative, polymorphic: true, optional: true
    belongs_to :screen_content, optional: true

    validates :token, uniqueness: true

    before_validation :generate_token, on: :create

    private

    def generate_token
      self.token ||= SecureRandom.urlsafe_base64(8)
    end
  end
end
```

**Columns:** `token`, `creative_type`, `creative_id`,
`screen_content_id`, `public_id`

Disposable. Token is permanent (printed on QR codes). Destination
lives on the Touchpoint and is fixed at creation via `Touchpoint.for`.

### Channels::NfcTag

```ruby
module Channels
  class NfcTag < ApplicationRecord
    include PublicIdentifiable

    has_one :touchpoint, as: :channelable, dependent: :destroy, touch: true

    validates :uid, uniqueness: true

    before_validation :generate_uid, on: :create

    private

    def generate_uid
      self.uid ||= SecureRandom.urlsafe_base64(12)
    end
  end
end
```

**Columns:** `uid`, `last_tapped_at`, `public_id`

Reusable. UID is written to the physical tag once. Destination
lives on the Touchpoint and is **reassignable** from the dashboard.
Agent registers the tag, assigns it to a listing, reassigns it
next week to a different listing.

### Channels::SmsKeyword

```ruby
module Channels
  class SmsKeyword < ApplicationRecord
    include PublicIdentifiable

    has_one :touchpoint, as: :channelable, dependent: :destroy, touch: true

    validates :keyword, uniqueness: true, format: {
      with: /\A[A-Z0-9]{4,10}\z/,
      message: "must be 4-10 uppercase alphanumeric characters"
    }
  end
end
```

**Columns:** `keyword`, `public_id`

Virtual. Keyword is configured in the dashboard. Destination
lives on the Touchpoint and is reassignable. User texts the
keyword → Twilio webhook → auto-reply with destination URL →
Lead auto-created with phone number.

---

## Routes

```ruby
# Public — scan/tap/text entry points
get "/s/:token", to: "scans#show", as: :qr_scan
get "/t/:uid",   to: "taps#show",  as: :nfc_tap

# API — SMS webhook
namespace :api do
  namespace :v1 do
    namespace :sms do
      resource :inbound, only: :create
    end
  end
end

# App — management
resources :touchpoints, only: %i[index show] do
  resources :events, controller: "touchpoint_events", only: :index
end
resources :nfc_tags, only: %i[index new create edit update]
```

---

## Controllers

### ScansController (existing — update)

```ruby
class ScansController < ApplicationController
  skip_before_action :require_authentication

  def show
    touchpoint = Touchpoint.joins(:qr_code)
                   .find_by!(channels_qr_codes: { token: params[:token], active: true })

    Analytics::Events::TouchpointVisited.create(
      touchpoint_pid: touchpoint.public_id,
      channel: "qr",
      account_pid: touchpoint.account&.public_id,
      destination_url: touchpoint.destination_url,
      request: request
    )

    redirect_to touchpoint.destination_url, allow_other_host: true
  end
end
```

### TapsController (new)

```ruby
class TapsController < ApplicationController
  skip_before_action :require_authentication

  def show
    touchpoint = Touchpoint.joins(:nfc_tag)
                   .find_by!(channels_nfc_tags: { uid: params[:uid] })

    touchpoint.channelable.update!(last_tapped_at: Time.current)

    Analytics::Events::TouchpointVisited.create(
      touchpoint_pid: touchpoint.public_id,
      channel: "nfc",
      account_pid: touchpoint.account&.public_id,
      destination_url: touchpoint.destination_url,
      request: request
    )

    redirect_to touchpoint.destination_url, allow_other_host: true
  end
end
```

### Api::V1::Sms::InboundsController (new)

```ruby
module Api
  module V1
    module Sms
      class InboundsController < Api::BaseController
        skip_before_action :authenticate_player!

        def create
          keyword = extract_keyword(params[:Body])
          touchpoint = Touchpoint.joins(:sms_keyword)
                         .find_by(channels_sms_keywords: { keyword: keyword })

          if touchpoint
            create_lead_from_sms(touchpoint, params[:From])

            Analytics::Events::TouchpointVisited.create(
              touchpoint_pid: touchpoint.public_id,
              channel: "sms",
              account_pid: touchpoint.account&.public_id,
              destination_url: touchpoint.destination_url
            )

            render xml: twiml_reply(touchpoint.destination_url)
          else
            render xml: twiml_reply_unknown
          end
        end

        private

        def extract_keyword(body)
          body.to_s.strip.upcase
        end

        def create_lead_from_sms(touchpoint, phone)
          CaptureLead.new(
            params: {
              phone: phone,
              lead_type: "sms_inquiry",
              listing_sid: touchpoint.destination_record&.signed_id(purpose: :lead_form)
            },
            request_context: { source: "sms", keyword: touchpoint.channelable.keyword }
          ).call
        end

        def twiml_reply(url)
          "<?xml version=\"1.0\"?><Response><Message>Thanks! View the listing: #{url}</Message></Response>"
        end

        def twiml_reply_unknown
          "<?xml version=\"1.0\"?><Response><Message>Sorry, we didn't recognize that keyword.</Message></Response>"
        end
      end
    end
  end
end
```

---

## Analytics Event

Unify `QrScanned` into a single `TouchpointVisited` event:

```ruby
module Analytics
  module Events
    class TouchpointVisited < Base
      self.event_name = "touchpoint.visited"
      self.event_context = :server

      attribute :touchpoint_pid,  :string
      attribute :channel,         :string   # "qr", "nfc", "sms"
      attribute :account_pid,     :string
      attribute :destination_url, :string

      validates :touchpoint_pid, :channel, :destination_url,
                presence: true
    end
  end
end
```

Replaces `QrScanned`. The `channel` attribute distinguishes how
the visitor arrived. The `Scopes` module for qualified scans
moves to filtering by channel.

---

## Migration from QrCode

### New tables

```ruby
create_table :touchpoints do |t|
  t.timestamps
  t.references :account, null: false, foreign_key: true
  t.string :channelable_type, null: false
  t.bigint :channelable_id, null: false
  t.string :destination_record_type
  t.bigint :destination_record_id
  t.string :destination_url
  t.string :label
  t.boolean :active, null: false, default: true
  t.uuid :public_id, null: false, default: "gen_random_uuid()"
  t.index :public_id, unique: true
  t.index [:channelable_type, :channelable_id]
  t.index [:destination_record_type, :destination_record_id]
end

create_table :channels_qr_codes do |t|
  t.timestamps
  t.string :token, null: false
  t.string :creative_type
  t.bigint :creative_id
  t.references :screen_content, foreign_key: true
  t.uuid :public_id, null: false, default: "gen_random_uuid()"
  t.index :token, unique: true
  t.index :public_id, unique: true
  t.index [:creative_type, :creative_id]
end

create_table :channels_nfc_tags do |t|
  t.timestamps
  t.string :uid, null: false
  t.datetime :last_tapped_at
  t.uuid :public_id, null: false, default: "gen_random_uuid()"
  t.index :uid, unique: true
  t.index :public_id, unique: true
end

create_table :channels_sms_keywords do |t|
  t.timestamps
  t.string :keyword, null: false
  t.uuid :public_id, null: false, default: "gen_random_uuid()"
  t.index :keyword, unique: true
  t.index :public_id, unique: true
end
```

### Drop old table

```ruby
drop_table :qr_codes
```

### Update associations

```ruby
# Listing
has_many :touchpoints, as: :destination_record, dependent: :destroy

# Agent  
has_many :touchpoints, as: :destination_record, dependent: :destroy

# Account
has_many :touchpoints, dependent: :destroy
```

### Convenience method on Listing

```ruby
def touchpoint_for(creative: nil, screen_content: nil)
  qr = Channels::QrCode.find_or_create_by!(
    creative: creative, screen_content: screen_content
  )
  Touchpoint.find_or_create_by!(
    account: account,
    channelable: qr,
    destination_record: self
  ) do |tp|
    tp.label = address.truncate(40)
  end
end
```

---

## App UI (Touchpoints management)

### Touchpoints index (replaces QR codes index)

Shows all touchpoints across all channels with filtering:

```
Touchpoints
  [All] [QR Codes] [NFC Tags] [SMS Keywords]

  ┌─────────────────────────────────────────────┐
  │ 📱 QR Code · abc123                         │
  │ → 123 Main St · via Hero Ad                 │
  │ 47 scans                                    │
  ├─────────────────────────────────────────────┤
  │ 📡 NFC Tag · "Front Door"                   │
  │ → 456 Park Ave · Last tapped 2 hours ago    │
  │ [Change Destination]                        │
  ├─────────────────────────────────────────────┤
  │ 💬 SMS · MAIN123                            │
  │ → 123 Main St · 12 texts received           │
  │ [Change Destination]                        │
  └─────────────────────────────────────────────┘
```

### NFC Tags management

```
NFC Tags
  [+ Register Tag]

  ┌─────────────────────────────────────────────┐
  │ Tag: abc123     Label: "Front Door"         │
  │ Pointing to: 123 Main St                    │
  │ Last tapped: 2 hours ago                    │
  │ [Change Destination] [View Activity]        │
  └─────────────────────────────────────────────┘
```

---

## Build Order

### Phase 1: Touchpoint model + QR migration

```
1. Create Touchpoint model + Channels::QrCode model
2. Migration: new tables, drop qr_codes
3. Update Listing/Agent/Account associations
4. Update ScansController to use Touchpoint
5. Create TouchpointVisited event (replaces QrScanned)
6. Update QR helper for ad rendering
7. Update all specs
8. COMMIT
```

### Phase 2: NFC

```
9.  Create Channels::NfcTag model
10. Create TapsController
11. NFC tag management UI (register, assign, reassign)
12. Update Touchpoints index to show NFC tags
13. COMMIT
```

### Phase 3: SMS

```
14. Create Channels::SmsKeyword model
15. Add Twilio gem + configure credentials
16. Create Api::V1::Sms::InboundsController
17. SMS keyword management UI
18. Auto-create Lead from inbound SMS
19. Update Touchpoints index to show SMS keywords
20. COMMIT
```

### Phase 4: Docs + standard

```
21. Update CLAUDE.md, event catalog
22. Update lead-capture-channels analysis
23. Promote plan
24. COMMIT
```

---

## Verification

1. `make test` — green after each phase
2. `/s/:token` still resolves QR codes → redirect + analytics
3. `/t/:uid` resolves NFC tags → redirect + analytics
4. SMS text → Twilio webhook → auto-reply + Lead created
5. Touchpoints index shows all three channel types
6. NFC tag destination is reassignable from dashboard
7. TouchpointVisited event has `channel` attribute

---

## Files Summary

| Phase | New/Changed | Count |
|-------|-------------|-------|
| Phase 1 (QR migration) | Models, migration, controllers, events, specs, views, helpers | ~20 |
| Phase 2 (NFC) | Model, controller, views, specs | ~8 |
| Phase 3 (SMS) | Model, controller, Twilio config, views, specs | ~10 |
| Phase 4 (Docs) | CLAUDE.md, event catalog, analysis | 3 |
| **Total** | | **~41** |
