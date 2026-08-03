# Standard: Security & Environment

## Content Security Policy

Use the Rails CSP initializer (`config/initializers/content_security_policy.rb`) to define a Content Security Policy.

- Start restrictive: `default-src :self`
- Relax as needed for specific resources (e.g., CDN fonts, external scripts)
- Use `policy.report_uri` in production to monitor violations before enforcing

```ruby
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :https
    policy.style_src   :self, :https
  end
end
```

## Parameter Filtering

Filter sensitive parameters from logs using `config.filter_parameters`. The following are filtered by default in this project:

```ruby
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt,
  :certificate, :otp, :ssn, :cvv, :cvc
]
```

Always verify new sensitive fields (API keys, secrets, PII) are added to this list.

## Environment Variables

- Use `.env.example` to document all required environment variables with placeholder values
- Never commit `.env` files — they are in `.gitignore`
- Use `Rails.application.credentials` for production secrets (database URLs, API keys)
- Access env vars via `ENV.fetch("VAR_NAME")` (raises on missing) or `ENV["VAR_NAME"]` (returns nil)

## Rate Limiting

Apply rate limits on authentication endpoints to prevent brute-force attacks. Rails 8 provides built-in `rate_limit` at the controller level:

```ruby
class SessionsController < ApplicationController
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
    redirect_to new_session_url, alert: "Try again later."
  }
end

class PasswordsController < ApplicationController
  rate_limit to: 10, within: 3.minutes, only: %i[create update], with: -> {
    redirect_to new_password_url, alert: "Try again later."
  }
end
```

Apply rate limits to:
- Login (`SessionsController#create`)
- Password reset (`PasswordsController#create`, `PasswordsController#update`)
- Any endpoint accepting user-submitted data at high volume

## HTTPS

Enforce SSL in production to protect data in transit:

```ruby
# config/environments/production.rb
config.force_ssl = true
```

This redirects all HTTP requests to HTTPS and sets the `Strict-Transport-Security` header.
