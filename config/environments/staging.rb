require_relative "production"

Rails.application.configure do
  # replaytv.dev — separate domain from production (replaytv.co).
  # No tld_length override needed (both are standard TLD length 1).
  # No default_url_options overrides needed (subdomain routing works
  # identically to production).

  config.action_mailer.default_url_options = {
    host: "app.replaytv.dev",
    protocol: "https"
  }
end
