class Ahoy::Store < Ahoy::DatabaseStore
  def track_visit(data)
    data[:account_id] = Current.account&.id
    super(data)
  end

  def track_event(data)
    data[:account_id] = Current.account&.id
    super(data)
  end
end

Ahoy.api = true
Ahoy.visit_duration = 4.hours
Ahoy.cookie_domain = :all
Ahoy.track_visits_immediately = true
Ahoy.server_side_visits = :when_needed
Ahoy.mask_ips = true
Ahoy.geocode = false
