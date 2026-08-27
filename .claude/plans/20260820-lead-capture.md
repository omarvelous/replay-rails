# Plan: Lead Capture v2

## The opportunity

Every QR scan is a hand-raise. Someone standing outside a storefront
window interested enough to pull out their phone. Right now, the scan
lands them on a listing page with agent contact info — but the next
step is on them (call, email). Most won't. A contact form on the
landing page captures that intent before they walk away.

Lead capture turns RePlay from a display tool into a lead generation
platform. That's the "QR-to-lead pipeline" from the product mission.

---

## Lead sources

Leads can originate from three surfaces:

| Surface | URL | Context | Has listing? | Has agent? |
|---------|-----|---------|:---:|:---:|
| **Listing page** | `/go/listings/:id` | "I'm interested in this property" | Yes (via scan chain) | Via primary agent |
| **Agent page** | `/go/agents/:id` | "I want to work with this agent" | No | Yes (from URL) |
| **Marketing site** | `/contact` or brand ad landing | "Tell me about your services" | No | No |

The form is the same on all three — a shared partial that receives
optional `listing_id` and `agent_id` as hidden fields. One controller,
one route, parent context as form data.

---

## Lead types

| Type | Source | Context |
|------|--------|---------|
| **Buyer inquiry** | Listing page | "I'm interested in this property" |
| **Renter inquiry** | Listing page (rental) | "I'd like to schedule a viewing" |
| **Seller inquiry** | Agent page, marketing site | "I want to sell my property" |
| **Open house RSVP** | Open house listing ad | "I'll be there Saturday" |
| **General inquiry** | Any page | "Tell me about your services" |
| **Agent recruitment** | Brokerage brand ad | "I'm interested in joining" |

All types available via dropdown on the form.

---

## The flow

```
Person walks by → sees ad on screen → scans QR code
    ↓
QR scan recorded (ad + screen attribution)
    ↓
Redirected to landing page with ?scan_id=123
  • /go/listings/:id  (listing ad QR)
  • /go/agents/:id    (agent ad QR)
  • /contact           (brand ad QR)
    ↓
Sees details + contact form
    ↓
Fills out form → POST /go/leads → Lead created
    ↓
Agent notified (email) → Lead appears in inbox
    ↓
Agent responds → Lead status: contacted → qualified → closed
```

---

## `Lead` model

Slim model. Listing is derived from the scan chain. Agent assignment
is tracked via `LeadAgent` join table. Lead itself only holds tenant
scoping, attribution, contact info, and status.

```ruby
class Lead < ApplicationRecord
  belongs_to :account
  belongs_to :qr_scan, optional: true

  has_many :lead_agents, dependent: :destroy
  has_many :agents, through: :lead_agents

  TYPES = %w[
    buyer_inquiry
    renter_inquiry
    seller_inquiry
    open_house_rsvp
    general_inquiry
    agent_recruitment
  ].freeze

  STATUSES = %w[ new contacted qualified closed ].freeze

  validates :name, presence: true
  validates :email, presence: true, unless: -> { phone.present? }
  validates :phone, presence: true, unless: -> { email.present? }
  validates :lead_type, inclusion: { in: TYPES }
  validates :status, inclusion: { in: STATUSES }
  validates :account, presence: true

  scope :unread, -> { where(status: "new") }
  scope :by_status, ->(s) { where(status: s) }

  def current_agent
    agents.order("lead_agents.created_at DESC").first
  end

  def listing
    qr_scan&.qr_code&.destination_record if qr_scan&.qr_code&.destination_record.is_a?(Listing)
  end
end
```

### Fields

| Column | Type | Purpose |
|--------|------|---------|
| `account_id` | FK | Tenant scoping |
| `qr_scan_id` | FK, optional | Attribution — the scan that brought them |
| `lead_type` | string | buyer_inquiry, general_inquiry, etc. |
| `status` | string, default "new" | new → contacted → qualified → closed |
| `name` | string | Contact name |
| `email` | string, optional | Email (required if no phone) |
| `phone` | string, optional | Phone (required if no email) |
| `message` | text, optional | Free-text message |
| `context` | jsonb, default {} | Extra data: source URL, user agent, listing_id (for non-scan leads) |

### Migration

```ruby
create_table :leads do |t|
  t.timestamps
  t.references :account, null: false, foreign_key: true
  t.references :qr_scan, foreign_key: true
  t.string  :lead_type, null: false, default: "general_inquiry"
  t.string  :status, null: false, default: "new"
  t.string  :name, null: false
  t.string  :email
  t.string  :phone
  t.text    :message
  t.jsonb   :context, default: {}
end
add_index :leads, [ :account_id, :status ]
add_index :leads, [ :account_id, :created_at ]
```

---

## `LeadAgent` join table

Tracks agent assignment with history. Current agent is the most
recent row. Reassignment = create a new row.

```ruby
class LeadAgent < ApplicationRecord
  belongs_to :lead
  belongs_to :agent
end
```

### Migration

```ruby
create_table :lead_agents do |t|
  t.timestamps
  t.references :lead, null: false, foreign_key: true
  t.references :agent, null: false, foreign_key: true
end
add_index :lead_agents, [ :lead_id, :created_at ]
```

### Reassignment

```ruby
# Reassign a lead — just create a new row
lead.lead_agents.create!(agent: new_agent)

# Who has it now?
lead.current_agent  # => most recent LeadAgent's agent

# Assignment history
lead.lead_agents.order(:created_at).includes(:agent)
# => [Agent A (Aug 1), Agent B (Aug 5), Agent C (Aug 12)]
```

---

## Attribution chain

A lead connects to the full attribution chain through its `qr_scan`:

```
Lead
  → qr_scan (the scan event)
    → qr_code (the QR that was scanned)
      → destination_record (the listing)
    → ad (the ad that displayed the QR)
    → screen (the physical screen)
      → site (the office location)
```

One column (`qr_scan_id`) gives you the complete picture: which listing,
which ad, which screen, which site, when.

For leads without a scan (direct URL visit, shared link), the listing
context is stored in `context` jsonb:

```ruby
@lead.context = {
  listing_id: @listing&.id,
  source_url: request.referer,
  ip_address: request.remote_ip,
  user_agent: request.user_agent
}
```

This keeps the schema clean — `listing_id` in context is a hint for
display, not a foreign key that needs referential integrity.

---

## Primary agent on listings

Leads initially route to the listing's primary agent. Add a `primary_at`
timestamp to `ListingAgent` — the most recent `primary_at` wins.

```ruby
# migration
add_column :listing_agents, :primary_at, :datetime

# app/models/listing_agent.rb
scope :primary, -> { where.not(primary_at: nil).order(primary_at: :desc) }

# app/models/listing.rb
def primary_agent
  listing_agents.primary.first&.agent || agents.first
end
```

Falls back to any agent on the listing, then to nil (the controller
falls back to the account owner for notification).

---

## Associations on existing models

```ruby
# app/models/agent.rb
has_many :lead_agents, dependent: :destroy
has_many :leads, through: :lead_agents

# app/models/account.rb
has_many :leads, dependent: :destroy

# app/models/qr_scan.rb
has_many :leads
```

---

## Routes

One top-level `/go/leads` route handles all lead sources. Parent
context (listing, agent) is passed as hidden form fields.

```ruby
# Marketing subdomain — public, no auth
constraints subdomain: "" do
  scope module: "marketing" do
    # ... existing pages
  end

  namespace :go do
    resources :listings, only: :show
    resources :agents, only: :show       # new public agent page
    resources :leads, only: :create      # single route for all lead sources
  end
end

# App subdomain — authenticated
constraints subdomain: "app" do
  scope module: "app" do
    # ... existing resources
    resources :leads, only: %i[ index show update ]
  end
end

# Admin subdomain — Administrate
constraints subdomain: "admin" do
  scope module: "admin", as: "admin" do
    # ... existing resources
    resources :leads
  end
end
```

---

## Contact form partial

A shared partial used on listing pages, agent pages, and the marketing
contact page. Each surface passes different hidden fields.

```erb
<%# app/views/go/shared/_lead_form.html.erb %>
<%# Locals: listing (optional), agent (optional), scan_id (optional) %>

<% if flash[:submitted] %>
  <div class="rounded-lg bg-green-50 border border-green-200 p-6 text-center">
    <p class="text-green-800 font-semibold">Thank you for your inquiry!</p>
    <p class="text-sm text-green-700 mt-1">
      An agent will be in touch shortly.
    </p>
  </div>
<% else %>
  <%= form_with url: go_leads_path, method: :post do |f| %>
    <%= f.hidden_field :listing_id, value: local_assigns[:listing]&.id %>
    <%= f.hidden_field :agent_id, value: local_assigns[:agent]&.id %>
    <%= f.hidden_field :scan_id, value: local_assigns[:scan_id] %>

    <div class="space-y-3">
      <div>
        <%= f.text_field :name, required: true, placeholder: "Your name",
            class: "block w-full rounded-lg ..." %>
      </div>
      <div class="grid grid-cols-2 gap-3">
        <div>
          <%= f.email_field :email, placeholder: "Email",
              class: "block w-full rounded-lg ..." %>
        </div>
        <div>
          <%= f.tel_field :phone, placeholder: "Phone",
              class: "block w-full rounded-lg ..." %>
        </div>
      </div>
      <div>
        <%= f.select :lead_type,
            [["I'm interested in buying", "buyer_inquiry"],
             ["I'm interested in renting", "renter_inquiry"],
             ["I want to sell my property", "seller_inquiry"],
             ["Open house RSVP", "open_house_rsvp"],
             ["General question", "general_inquiry"]],
            {}, class: "block w-full rounded-lg ..." %>
      </div>
      <div>
        <%= f.text_area :message, rows: 3,
            placeholder: "I'd like to schedule a viewing...",
            class: "block w-full rounded-lg ..." %>
      </div>
      <%= f.submit "Send inquiry",
          class: "w-full rounded-lg bg-indigo-600 px-4 py-3 text-sm font-semibold text-white ..." %>
    </div>
  <% end %>
<% end %>
```

### Usage on each surface

```erb
<%# Listing page — /go/listings/:id %>
<%= render "go/shared/lead_form",
    listing: @listing,
    agent: @listing.primary_agent,
    scan_id: params[:scan_id] %>

<%# Agent page — /go/agents/:id %>
<%= render "go/shared/lead_form",
    agent: @agent,
    scan_id: params[:scan_id] %>

<%# Marketing contact page %>
<%= render "go/shared/lead_form",
    scan_id: params[:scan_id] %>
```

---

## Passing scan context to the form

When the scan redirects to the landing page, pass the scan ID
as a query param so the form can attribute the lead:

```ruby
# scans_controller.rb — save scan to variable, pass scan_id on redirect
scan = qr.scans.create!(...)

if qr.destination_url.present?
  redirect_to qr.destination_url, allow_other_host: true
elsif qr.destination_record.present?
  redirect_to polymorphic_url([:go, qr.destination_record], subdomain: "", scan_id: scan.id),
              allow_other_host: true
else
  redirect_to app_root_path
end
```

---

## Public leads controller

One controller handles leads from all surfaces. Resolves the account
from whichever parent is present, then creates the initial agent
assignment via LeadAgent.

```ruby
# app/controllers/go/leads_controller.rb
module Go
  class LeadsController < ApplicationController
    skip_before_action :require_authentication

    def create
      listing = Listing.find_by(id: lead_params[:listing_id])
      agent = Agent.find_by(id: lead_params[:agent_id]) || listing&.primary_agent
      account = listing&.account || agent&.account

      if account.nil?
        head :unprocessable_content
        return
      end

      @lead = Lead.new(lead_params.except(:listing_id, :agent_id, :scan_id))
      @lead.account = account
      @lead.qr_scan = QrScan.find_by(id: lead_params[:scan_id])
      @lead.context = {
        listing_id: listing&.id,
        source_url: request.referer,
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      }

      if @lead.save
        @lead.lead_agents.create!(agent: agent) if agent
        LeadMailer.new_lead(@lead).deliver_later
        redirect_back_or_to root_path, flash: { submitted: true }
      else
        redirect_back_or_to root_path,
                            alert: @lead.errors.full_messages.to_sentence
      end
    end

    private

      def lead_params
        params.require(:lead).permit(
          :name, :email, :phone, :message, :lead_type,
          :listing_id, :agent_id, :scan_id
        )
      end
  end
end
```

### Account resolution

1. If `listing_id` present → `listing.account`
2. Else if `agent_id` present → `agent.account`
3. Else → reject (no orphan leads without a tenant)

For a truly generic "contact us" form (no listing, no agent), the
marketing page can pass a hidden account identifier. Phase F concern.

---

## Public agent landing page

New page at `/go/agents/:id` — the destination for agent ad QR codes
and agent QR codes.

```ruby
# app/controllers/go/agents_controller.rb
module Go
  class AgentsController < ApplicationController
    skip_before_action :require_authentication
    layout "public"

    def show
      @agent = Agent.find(params[:id])
      @listings = @agent.listings.where(status: "active").limit(6)
    end
  end
end
```

The page shows:
- Agent photo, name, phone, email
- Active listings (cards linking to `/go/listings/:id`)
- Lead form partial with `agent: @agent`

---

## Lead inbox (app subdomain)

### LeadsController

```ruby
# app/controllers/app/leads_controller.rb
module App
  class LeadsController < App::BaseController
    def index
      base = Current.account.leads.includes(:lead_agents, :agents)
      base = base.by_status(params[:status]) if params[:status].present?
      @pagy, @leads = pagy(base.order(created_at: :desc))
      @unread_count = Current.account.leads.unread.count
    end

    def show
      @lead = Current.account.leads.find(params[:id])
    end

    def update
      @lead = Current.account.leads.find(params[:id])
      @lead.update!(status: params[:lead][:status]) if params[:lead][:status].present?
      if params[:lead][:agent_id].present?
        @lead.lead_agents.create!(agent_id: params[:lead][:agent_id])
      end
      redirect_to @lead, notice: "Lead updated."
    end

    private

      def lead_params
        params.require(:lead).permit(:status)
      end
  end
end
```

### Index view

```
┌─────────────────────────────────────────────────────────┐
│  Leads (12)                    Filter: All ▾            │
├─────────────────────────────────────────────────────────┤
│  ● Jane Smith          buyer_inquiry     2 min ago      │
│    350 Fifth Ave · via Window Display                   │
│    "I'd like to schedule a viewing this weekend"        │
│                                                         │
│  ○ Tom Johnson         general_inquiry   1 hr ago       │
│    Jane Broker · via Agent QR                           │
│    "Looking to sell my 2BR in the area"                 │
└─────────────────────────────────────────────────────────┘

● = new (unread)   ○ = contacted   ◆ = qualified   ✓ = closed
```

### Show view

Full lead detail with:
- Contact info (name, email with mailto:, phone with tel:)
- Message
- Status selector (new → contacted → qualified → closed)
- Agent assignment (reassign dropdown — creates new LeadAgent)
- Assignment history timeline
- Attribution: which ad, which screen, which QR code (via qr_scan)
- Listing (derived from scan chain or context)

### Sidebar badge

Unread lead count in the sidebar next to "Leads":

```erb
<%= link_to leads_path, class: "..." do %>
  Leads
  <% if @unread_lead_count&.positive? %>
    <span class="ml-auto bg-red-500 text-white text-xs rounded-full w-5 h-5 grid place-items-center">
      <%= @unread_lead_count %>
    </span>
  <% end %>
<% end %>
```

Set `@unread_lead_count` in a `before_action` on `App::BaseController`.

---

## Email notification

```ruby
# app/mailers/lead_mailer.rb
class LeadMailer < ApplicationMailer
  def new_lead(lead)
    @lead = lead
    recipient = lead.current_agent&.email || lead.account.users.first.email_address

    mail(
      to: recipient,
      subject: "New inquiry: #{lead.listing&.address || 'General inquiry'}"
    )
  end
end
```

The email includes:
- Lead name, email, phone
- Message
- Listing details (if applicable, derived from scan chain)
- Link to the lead in the app inbox
- Quick-action: "Reply to #{lead.name}" (mailto: link)

---

## Email dev tooling

Two tools for developing and testing emails:

### Letter Opener Web

Intercepts all outgoing mail in development and shows it in a web
inbox. When you submit a lead form, the notification email appears
automatically — no SMTP, no external service.

```ruby
# Gemfile
gem "letter_opener_web", group: :development

# config/environments/development.rb
config.action_mailer.delivery_method = :letter_opener_web

# config/routes.rb
mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
```

Browse at `http://localhost:3000/letter_opener`. Shows HTML rendering,
text version, headers, and attachments.

### Action Mailer Previews

Built into Rails — browse email templates with sample data at
`/rails/mailers`. Hot-reloads on refresh for fast iteration on layout
and copy.

```ruby
# spec/mailers/previews/lead_mailer_preview.rb
class LeadMailerPreview < ActionMailer::Preview
  def new_lead
    lead = Lead.first || FactoryBot.create(:lead)
    LeadMailer.new_lead(lead)
  end
end
```

Browse at `http://localhost:3000/rails/mailers/lead_mailer/new_lead`.

### When to use which

- **Designing the template** → Mailer Previews (controlled data, hot reload)
- **Integration testing** → Letter Opener Web (real emails from real actions)

---

## Administrate dashboard

```ruby
# app/dashboards/lead_dashboard.rb
class LeadDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    account: Field::BelongsTo,
    qr_scan: Field::BelongsTo,
    lead_agents: Field::HasMany,
    lead_type: Field::String,
    status: Field::String,
    name: Field::String,
    email: Field::String,
    phone: Field::String,
    message: Field::Text,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze
end
```

---

## Build order

### Phase A — Schema
1. Add `primary_at` to `listing_agents`, `ListingAgent.primary` scope, `Listing#primary_agent` (RED/GREEN)
2. Lead model — spec, factory, migration (RED/GREEN)
3. LeadAgent model — spec, factory, migration (RED/GREEN)
4. Associations on Agent, Account, QrScan (RED/GREEN)

### Phase B — Public form + controller
5. Update `ScansController` to save scan to variable and pass `scan_id` on redirect
6. Shared lead form partial (`go/shared/_lead_form.html.erb`)
7. `Go::LeadsController#create` — single route, account resolved from params
8. Add form to `/go/listings/:id` with listing + agent hidden fields
9. Thank you state via flash after submission

### Phase C — Agent landing page
10. `Go::AgentsController#show` — public agent page
11. Agent page view with photo, listings, lead form
12. Route: `resources :agents, only: :show` under `go` namespace

### Phase D — App inbox
13. `App::LeadsController` — index, show, update (RED/GREEN)
14. Index view with status filter, unread badge
15. Show view with status selector, agent reassignment, attribution chain, assignment history
16. Sidebar link with unread count badge

### Phase E — Email notifications + dev tooling
17. Add `letter_opener_web` gem, configure delivery method, mount route
18. `LeadMailer#new_lead` with HTML email template
19. Mailer preview class (`LeadMailerPreview`)
20. Deliver on lead creation in `Go::LeadsController`

### Phase F — Admin + polish
21. `LeadDashboard` + `LeadAgentDashboard` for Administrate admin
22. Admin routes under admin subdomain
23. Lead counts on Listing show, Agent show pages
24. Seeds: create demo leads with agent assignments
25. Marketing contact page with general inquiry form (account resolution TBD)

---

## What changed from v1

- **Removed `listing_id` from Lead** — listing is derived from `qr_scan.qr_code.destination_record`. For non-scan leads, stored in `context` jsonb.
- **Removed `agent_id` from Lead** — replaced with `LeadAgent` join table for assignment history.
- **Added `LeadAgent`** — join table for agent assignment. Current agent = last row by `created_at`. Reassignment = create new row.
- **Single `/go/leads` route** — not nested under listings. Parent context passed as form params.
- **Shared form partial** — one partial works on all surfaces (listing, agent, marketing).
- **Added agent landing page** — `/go/agents/:id` as QR destination.

---

## What's deferred

- **Marketing contact form** — needs account resolution without listing/agent parent. Options: hardcoded default account, subdomain-based lookup, or account slug in URL.
- **SMS notifications** — requires Twilio or similar service
- **In-app notification badge** — real-time via ActionCable
- **Lead reply from inbox** — compose and send email from within RePlay
- **Lead scoring** — automatic qualification based on behavior
- **CRM integration** — push leads to Salesforce, HubSpot, etc.
- **Custom form builder** — let users create their own inquiry forms
- **Open house RSVP** — form with event date confirmation
- **Agent recruitment form** — "Join our brokerage" landing page
- **Lead analytics dashboard** — conversion rates by ad, screen, listing
- **Auto-assignment rules** — route leads by area, listing, round-robin
- **GDPR/privacy** — consent checkbox, data retention policies
