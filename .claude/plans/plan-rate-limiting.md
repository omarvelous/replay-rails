# Plan: Rate Limiting & Spam Prevention

## Current state

Every public endpoint is wide open — no throttling, no bot
protection, no abuse prevention. The following are unauthenticated
and accept writes from any IP:

| Endpoint | Method | Risk |
|----------|--------|------|
| `POST /go/leads` | Lead form | Spam leads fill the inbox |
| `GET /s/:token` | QR scan redirect | Inflated scan metrics |
| `POST /register` (play subdomain) | Player registration | Exhaust pairing codes |
| `POST /accounts` (app subdomain) | Account signup | Account spam |
| `POST /session` (app subdomain) | Login | Credential stuffing |
| `POST /passwords` (app subdomain) | Password reset | Email bombing |

Read-only public pages (`/go/listings/:id`, `/go/agents/:id`,
marketing pages) are lower risk — standard CDN/Rack caching
handles those.

---

## Two layers of protection

### 1. Rack::Attack (request throttling)

Rate limits at the Rack middleware level — before the request
reaches Rails. Fast, low overhead, based on IP address.

### 2. Honeypot field (bot filtering)

Hidden form field that bots fill but humans don't. Applied to
the lead form specifically. No CAPTCHA — CAPTCHAs hurt conversion
on mobile (the primary lead form surface).

---

## Rack::Attack configuration

### Gem

```ruby
# Gemfile
gem "rack-attack"
```

Rails 8 includes Rack::Attack as a commented-out default in some
templates, but it's not in this project's Gemfile yet.

### Initializer

```ruby
# config/initializers/rack_attack.rb

class Rack::Attack
  ### Throttle rules ###

  # Lead form: 10 submissions per hour per IP
  # Legitimate users submit 1-2 forms. 10 catches repeated spam
  # while allowing a family sharing a phone.
  throttle("leads/ip", limit: 10, period: 1.hour) do |req|
    req.ip if req.path == "/go/leads" && req.post?
  end

  # QR scans: 60 per minute per IP
  # A person scanning multiple QR codes in a storefront window
  # might hit 5-10 per minute. 60 is generous but stops scraping.
  throttle("scans/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/s/") && req.get?
  end

  # Player registration: 5 per hour per IP
  # A device registers once. 5 handles factory resets and testing.
  throttle("player/register/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/register" && req.post?
  end

  # Account signup: 5 per hour per IP
  # One signup per person. 5 handles retries on validation errors.
  throttle("signup/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/accounts" && req.post?
  end

  # Login: 10 per 15 minutes per IP
  # Prevents credential stuffing while allowing multiple users
  # on a shared office network.
  throttle("login/ip", limit: 10, period: 15.minutes) do |req|
    req.ip if req.path == "/session" && req.post?
  end

  # Login: 5 per 15 minutes per email
  # Tighter limit per-email to stop targeted brute force.
  throttle("login/email", limit: 5, period: 15.minutes) do |req|
    if req.path == "/session" && req.post?
      req.params.dig("email_address")&.downcase&.strip
    end
  end

  # Password reset: 3 per hour per email
  # Prevents email bombing a specific address.
  throttle("password/email", limit: 3, period: 1.hour) do |req|
    if req.path == "/passwords" && req.post?
      req.params.dig("email_address")&.downcase&.strip
    end
  end

  ### Blocklist rules ###

  # Block known bad IPs (populated from admin or automated detection)
  blocklist("block bad ips") do |req|
    Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 20, findtime: 1.minute, bantime: 1.hour) do
      req.path == "/session" && req.post?
    end
  end

  ### Throttle response ###

  self.throttled_responder = lambda do |_env|
    [
      429,
      { "Content-Type" => "text/plain", "Retry-After" => "60" },
      ["Rate limit exceeded. Please try again later."]
    ]
  end
end
```

### Rate limit summary

| Endpoint | Limit | Period | Key |
|----------|-------|--------|-----|
| Lead form | 10 | 1 hour | IP |
| QR scans | 60 | 1 min | IP |
| Player register | 5 | 1 hour | IP |
| Account signup | 5 | 1 hour | IP |
| Login | 10 | 15 min | IP |
| Login | 5 | 15 min | email |
| Password reset | 3 | 1 hour | email |

### Cache store

Rack::Attack needs a cache store for tracking request counts.
Rails 8 uses Solid Cache (DB-backed). For Rack::Attack, use
the Rails cache directly:

```ruby
# config/initializers/rack_attack.rb
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
```

`MemoryStore` is fine for single-process dev/deployment. For
multi-process (Puma workers), use the Rails cache:

```ruby
Rack::Attack.cache.store = Rails.cache
```

Solid Cache works but adds DB queries per request. For production,
consider Redis or Memcached for the Rack::Attack store specifically.
For now, `MemoryStore` keeps it simple.

---

## Honeypot field

A hidden field on the lead form that bots auto-fill but humans
never see. No JavaScript required, no CAPTCHA UX penalty.

### Form change

```erb
<%# app/views/go/leads/_form.html.erb — add inside the form %>
<div aria-hidden="true" style="position: absolute; left: -9999px; top: -9999px;">
  <%= f.text_field :website, tabindex: "-1", autocomplete: "off" %>
</div>
```

- `position: absolute; left: -9999px` — invisible to humans
- `tabindex: "-1"` — can't be focused via keyboard
- `autocomplete: "off"` — browsers won't fill it
- `aria-hidden: "true"` — screen readers skip it
- Named `website` — bots love filling "website" fields

### Controller change

```ruby
# app/controllers/go/leads_controller.rb

def create
  # Honeypot check — bots fill the hidden website field
  if params[:lead][:website].present?
    head :ok
    return
  end

  # ... existing lead creation logic
end
```

Silent discard — return 200 so bots think the submission worked.
No error message, no redirect, no feedback that reveals the trap.

### Permit the param

Add `:website` to the permitted params so Rails doesn't filter it
before we can check it:

```ruby
def lead_params
  params.require(:lead).permit(
    :name, :email, :phone, :message, :lead_type,
    :listing_id, :agent_id, :scan_id, :website
  )
end
```

But don't pass it to `Lead.new` — strip it after checking:

```ruby
@lead = Lead.new(lead_params.except(:listing_id, :agent_id, :scan_id, :website))
```

---

## Testing

### Rack::Attack specs

Rack::Attack is middleware — test it with request specs by hitting
the endpoint repeatedly:

```ruby
# spec/requests/rate_limiting_spec.rb
require "rails_helper"

RSpec.describe "Rate limiting" do
  before do
    Rack::Attack.enabled = true
    Rack::Attack.reset!
  end

  after do
    Rack::Attack.enabled = false
  end

  describe "lead form throttling" do
    let(:account) { create(:account) }
    let(:listing) { create(:listing, account: account) }

    it "allows requests under the limit" do
      host! "replay.localhost"
      3.times do
        post go_leads_path, params: {
          lead: { name: "Test", email: "t@example.com",
                  lead_type: "general_inquiry", listing_id: listing.id }
        }
        expect(response).not_to have_http_status(:too_many_requests)
      end
    end

    it "returns 429 when limit is exceeded" do
      host! "replay.localhost"
      11.times do
        post go_leads_path, params: {
          lead: { name: "Test", email: "t@example.com",
                  lead_type: "general_inquiry", listing_id: listing.id }
        }
      end
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "login throttling" do
    it "returns 429 after too many login attempts" do
      11.times do
        post session_path, params: {
          email_address: "test@example.com",
          password: "wrong"
        }
      end
      expect(response).to have_http_status(:too_many_requests)
    end
  end
end
```

### Honeypot specs

```ruby
# spec/requests/go/leads_spec.rb — add to existing spec

context "with honeypot filled (bot)" do
  it "silently discards the submission" do
    post go_leads_path, params: {
      lead: { name: "Bot", email: "bot@spam.com",
              lead_type: "general_inquiry",
              listing_id: listing.id, website: "https://spam.com" }
    }
    expect(response).to have_http_status(:ok)
    expect(Lead.count).to eq(0)
  end
end
```

---

## Development / Test considerations

### Disable in test by default

Rack::Attack should be disabled in test unless explicitly testing
rate limits. Throttling in specs causes flaky tests.

```ruby
# config/environments/test.rb
Rack::Attack.enabled = false
```

Rate limiting specs enable it explicitly with `before { Rack::Attack.enabled = true }`.

### Development

Keep Rack::Attack enabled in development so you can verify it works
when testing manually. The limits are high enough not to interfere
with normal development.

---

## What this does NOT do

- **CAPTCHA** — hurts conversion on mobile, the primary lead form surface. Honeypot is sufficient for v1.
- **reCAPTCHA v3** — invisible scoring could be added later if spam bypasses the honeypot. No JS dependency for now.
- **IP reputation** — services like MaxMind or Cloudflare IP reputation checks. Adds a dependency and latency.
- **Geographic blocking** — blocking IPs from specific countries. Depends on target market.
- **Request signing** — HMAC-signed form tokens to prevent replay. Overkill for this stage.
- **WAF** — web application firewall (Cloudflare, AWS WAF). Infrastructure-level concern, not app-level.

---

## Build order

### Phase 1 — Rack::Attack
1. Add `rack-attack` gem
2. Create initializer with throttle rules
3. Configure cache store (`MemoryStore`)
4. Disable in test environment by default
5. Custom 429 response
6. Rate limiting request specs (RED/GREEN)

### Phase 2 — Honeypot
7. Add hidden `website` field to lead form
8. Add honeypot check to `Go::LeadsController#create`
9. Permit + strip the param
10. Honeypot spec (RED/GREEN)

### Phase 3 — Monitoring
11. Log throttled requests for visibility:
    ```ruby
    ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _id, payload|
      Rails.logger.warn("[Rack::Attack] Throttled #{payload[:request].ip} on #{payload[:request].path}")
    end
    ```
12. Add throttle events to admin dashboard stats (future — when analytics exists)

---

## Dependencies

None — can be built independently. No dependency on RBAC, leads,
or any other feature. Should be done before launch.
