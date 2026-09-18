class RecordHeartbeat
  Result = Struct.new(:success?, :error, keyword_init: true)

  def initialize(player:, session:, ip_address:, user_agent:, params: {})
    @player = player
    @session = session
    @ip_address = ip_address
    @user_agent = user_agent
    @params = params
  end

  def call
    return Result.new(success?: false, error: "unpaired") unless @player.screen

    ua_changed = @player.user_agent != @user_agent

    @session.update!(last_active_at: Time.current)
    @player.update!(
      last_heartbeat_at: Time.current,
      ip_address: @ip_address,
      user_agent: @user_agent,
      screen_width: @params[:screen_width] || @player.screen_width,
      screen_height: @params[:screen_height] || @player.screen_height
    )

    UpdateDeviceInfo.new(player: @player).call if ua_changed

    Result.new(success?: true)
  end
end
