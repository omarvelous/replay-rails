module AuthenticationHelpers
  def sign_in(user)
    # Create a session record and set the signed cookie directly.
    # In production, cookies are shared across subdomains via domain: :all.
    # In tests, Rack::Test isolates cookies per host, so we set it directly.
    session = user.sessions.create!(
      user_agent: "RSpec",
      ip_address: "127.0.0.1"
    )
    jar = ActionDispatch::Request.new(Rails.application.env_config.deep_dup).cookie_jar
    jar.signed[:session_id] = { value: session.id, httponly: true }
    cookies[:session_id] = jar[:session_id]
  end
  def sign_in_player(player)
    jar = ActionDispatch::Request.new(Rails.application.env_config.deep_dup).cookie_jar
    jar.signed[:player_token] = { value: player.token, httponly: true }
    cookies[:player_token] = jar[:player_token]
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end
