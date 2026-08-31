require_relative "production"

Rails.application.configure do
  # staging.replaytv.co is the base domain — tell Rails that
  # "staging.replaytv.co" has 2 dots in the TLD portion so
  # app.staging.replaytv.co parses subdomain as "app" not "app.staging"
  config.action_dispatch.tld_length = 2

  # Default host for all URL helpers (session_url, root_url, etc.)
  config.action_controller.default_url_options = {
    host: "staging.replaytv.co",
    protocol: "https"
  }

  # Default host for mailer links
  config.action_mailer.default_url_options = {
    host: "app.staging.replaytv.co",
    protocol: "https"
  }
end

# Route-level default_url_options — must be set outside the configure block
Rails.application.routes.default_url_options[:host] = "staging.replaytv.co"
Rails.application.routes.default_url_options[:protocol] = "https"
