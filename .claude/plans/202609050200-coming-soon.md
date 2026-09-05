# Plan: Coming Soon Gate

## Problem

Production is live at replaytv.co but the product shouldn't be
public yet. Need a minimal "Coming Soon" page that gates the
entire production domain — all subdomains, all routes — until
launch. Controlled by environment variable.

## Approach

Rack middleware that intercepts all requests when
`ENV["COMING_SOON"] == "true"`. Serves a self-contained HTML
page with inline CSS. No Rails routing, no controllers, no
layouts involved. The middleware sits before Rails in the stack
so it's fast and simple.

Allowed through the gate:
- `GET /up` — health check (Render needs this)

Everything else gets the coming soon page.

---

## Implementation

### Middleware

```ruby
# app/middleware/coming_soon_middleware.rb
class ComingSoonMiddleware
  ALLOWED_PATHS = ["/up"].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    if !enabled? || allowed?(env)
      @app.call(env)
    else
      [200, { "Content-Type" => "text/html; charset=utf-8" }, [html]]
    end
  end

  private

    def enabled?
      ENV["COMING_SOON"] == "true"
    end

    def allowed?(env)
      ALLOWED_PATHS.include?(env["PATH_INFO"])
    end

    def html
      @html ||= File.read(
        File.join(__dir__, "coming_soon.html")
      )
    end
end
```

### Registration

```ruby
# config/application.rb
config.middleware.insert_before 0, "ComingSoonMiddleware"
```

Inserted at position 0 — before everything, including Rack::Attack.

### HTML

`app/middleware/coming_soon.html` — a complete standalone HTML
document:

- Full `<!DOCTYPE html>` with inline `<style>` tag
- Dark background (#030712) matching the Bold hero
- RePlay logo (inline SVG)
- "Coming Soon" headline
- One-liner: "Digital signage for real estate brokerages"
- No form, no email capture — just the brand and message
- Fully responsive, zero external dependencies
- No JavaScript required


---

## What's Gated

Everything on all subdomains:
- `replaytv.co` (marketing)
- `app.replaytv.co` (app login, dashboard)
- `admin.replaytv.co` (admin panel)
- `play.replaytv.co` (player)
- `api.replaytv.co` (API)
- `rply.tv` (QR scans — gated too)

## What's Allowed Through

- `GET /up` — health check

---

## Toggling

- **Enable:** Set `COMING_SOON=true` in Render production env vars
- **Disable:** Remove the env var or set to any other value
- Render restarts on env var change — no code deploy needed
- Middleware checks env var on every request (not cached at boot)
  so it responds immediately after restart

---

## Trade-offs

**Pros:**
- Zero Rails involvement — fastest possible response
- Gates everything uniformly, no route leaks
- Self-contained HTML, no layout/asset dependencies
- Toggle without deploy

**Cons:**
- Can't access app/admin/player on production while enabled
  (use staging for testing)
- QR scans on `rply.tv` are gated (won't work until launch)
- No email capture until gate is removed

---

## Build Order

1. Create middleware class
2. Create self-contained HTML file
3. Register middleware in `config/application.rb`
4. Spec: middleware serves coming soon when env var set
5. Spec: middleware passes through when env var not set
6. Spec: health check passes through when gated
7. Set `COMING_SOON=true` in Render production env vars
