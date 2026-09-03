require_relative "production"

Rails.application.configure do
  # replaytv.dev — separate domain from production (replaytv.co).
  # No tld_length override needed (both are standard TLD length 1).
  # Override default_url_options inherited from production (replay.com).

  config.action_controller.default_url_options = {
    host: "replaytv.dev",
    protocol: "https"
  }

  config.action_mailer.default_url_options = {
    host: "app.replaytv.dev",
    protocol: "https"
  }
end
