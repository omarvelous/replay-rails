class Ahoy::Store < Ahoy::DatabaseStore
  def track_visit(data)
    return if exclude_request?
    data[:account_id] = Current.account&.id
    super(data)
  end

  def track_event(data)
    return if exclude_request?
    props = data[:properties] || {}
    data[:account_id] = Current.account&.id || props[:account_id] || props["account_id"]
    super(data)
  end

  def exclude_request?
    request&.subdomain == "admin"
  end
end

# Rails 8 built-in auth uses Current.user, not current_user
Ahoy.user_method = ->(controller) { Current.user }

Ahoy.api = true
Ahoy.visit_duration = 4.hours
Ahoy.cookie_domain = :all
Ahoy.mask_ips = true
Ahoy.geocode = false
Ahoy.server_side_visits = :when_needed
