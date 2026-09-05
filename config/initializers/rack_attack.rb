class Rack::Attack
  # Use in-memory store for rate limit tracking.
  # For multi-process production (Puma workers), switch to Rails.cache or Redis.
  cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Throttle rules ###

  # Lead form: 10 submissions per hour per IP
  throttle("leads/ip", limit: 10, period: 1.hour) do |req|
    req.ip if req.path == "/go/leads" && req.post?
  end

  # QR scans: 60 per minute per IP
  throttle("scans/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/s/") && req.get?
  end

  # Player registration: 5 per hour per IP
  throttle("player/register/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/players" && req.post?
  end

  # Inquiry/demo request: 5 per hour per IP
  throttle("inquiries/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/inquiries" && req.post?
  end

  # Account signup: 5 per hour per IP
  throttle("signup/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/accounts" && req.post?
  end

  # Invite creation: 5 per hour per IP
  throttle("invites/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/invites" && req.post?
  end

  # Login: 10 per 15 minutes per IP
  throttle("login/ip", limit: 10, period: 15.minutes) do |req|
    req.ip if req.path == "/session" && req.post?
  end

  # Login: 5 per 15 minutes per email
  throttle("login/email", limit: 5, period: 15.minutes) do |req|
    if req.path == "/session" && req.post?
      req.params.dig("email_address")&.downcase&.strip
    end
  end

  # Password reset: 3 per hour per email
  throttle("password/email", limit: 3, period: 1.hour) do |req|
    if req.path == "/passwords" && req.post?
      req.params.dig("email_address")&.downcase&.strip
    end
  end

  ### Throttle response ###

  self.throttled_responder = lambda do |_env|
    [
      429,
      { "Content-Type" => "text/plain", "Retry-After" => "60" },
      [ "Rate limit exceeded. Please try again later." ]
    ]
  end

  ### Logging ###

  ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _id, payload|
    Rails.logger.warn("[Rack::Attack] Throttled #{payload[:request].ip} on #{payload[:request].path}")
  end
end
