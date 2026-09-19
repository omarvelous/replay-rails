class Ahoy::Store < Ahoy::DatabaseStore; end

# Exclude admin subdomain from tracking
Ahoy.exclude_method = ->(controller, request) { request&.subdomain == "admin" }

Ahoy.api = true
Ahoy.visit_duration = 4.hours
Ahoy.cookie_domain = :all
Ahoy.mask_ips = true
Ahoy.geocode = false
Ahoy.server_side_visits = :when_needed
