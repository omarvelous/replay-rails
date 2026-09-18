class RegisterPlayer
  Result = Struct.new(:success?, :player, :session, keyword_init: true)

  def initialize(ip_address:, user_agent:, params: {})
    @ip_address = ip_address
    @user_agent = user_agent
    @params = params
  end

  def call
    player = Player.create!(
      ip_address: @ip_address,
      user_agent: @user_agent,
      app_version: @params[:app_version],
      screen_width: @params[:screen_width],
      screen_height: @params[:screen_height],
      touch_capable: @params[:touch_capable]
    )
    ParseDeviceInfo.new(player: player).call

    player_session = player.player_sessions.create!(
      ip_address: @ip_address,
      user_agent: @user_agent
    )

    Result.new(success?: true, player: player, session: player_session)
  end
end
