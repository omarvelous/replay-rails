class Ahoy::Store < Ahoy::DatabaseStore
  def track_visit(data)
    data[:account_id] = Current.account&.id
    super(data)
  end

  def track_event(data)
    props = (data[:properties] || {}).with_indifferent_access
    data[:account_id] = Current.account&.id || props[:account_id]
    super(data)
  end
end

# Rails 8 built-in auth uses Current.user, not Devise's current_user
Ahoy.user_method = ->(controller) { Current.user }

# Exclude admin subdomain from tracking
Ahoy.exclude_method = ->(controller, request) { request&.subdomain == "admin" }

Ahoy.api = true
Ahoy.visit_duration = 4.hours
Ahoy.cookie_domain = :all
Ahoy.mask_ips = true
Ahoy.geocode = false
Ahoy.server_side_visits = :when_needed
