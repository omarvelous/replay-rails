require_relative "production"

Rails.application.configure do
  # staging.replaytv.co is the base domain — tell Rails that
  # "staging.replaytv.co" has 2 dots in the TLD portion so
  # app.staging.replaytv.co parses subdomain as "app" not "app.staging"
  config.action_dispatch.tld_length = 2

  # Ensure URL helpers generate links with the full staging domain
  # e.g., app.staging.replaytv.co instead of app.replaytv.co
  Rails.application.routes.default_url_options[:host] = "staging.replaytv.co"

  config.action_mailer.default_url_options = {
    host: "app.staging.replaytv.co",
    protocol: "https"
  }
end
