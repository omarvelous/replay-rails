require_relative "production"

Rails.application.configure do
  # replaytv.dev — separate domain from production (replaytv.co).
  # No tld_length override needed (both are standard TLD length 1).
  # Override default_url_options inherited from production (replay.com).

  config.hosts = [
    "replaytv.dev",
    /.*\.replaytv\.dev/
  ]

  config.action_controller.default_url_options = {
    host: "replaytv.dev",
    protocol: "https"
  }

  config.action_mailer.default_url_options = {
    host: "app.replaytv.dev",
    protocol: "https"
  }

  config.action_cable.allowed_request_origins = [
    /https:\/\/.*\.replaytv\.dev/
  ]

  config.host_authorization = {
    exclude: ->(request) {
      request.path == "/up" ||
        request.headers["X-Forwarded-Host"]&.match?(/\A(play\.)?replaytv\.dev\z/)
    }
  }
end
