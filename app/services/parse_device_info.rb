class ParseDeviceInfo
  def initialize(player:)
    @player = player
  end

  def call
    return unless @player.user_agent.present?

    client = DeviceDetector.new(@player.user_agent)

    @player.update!(
      device_model: client.device_name.presence,
      device_manufacturer: client.device_brand.presence,
      os_name: client.os_name.presence,
      os_version: client.os_full_version.presence,
      browser_name: client.name.presence,
      browser_version: client.full_version.presence,
      device_type: infer_device_type(client)
    )
  end

  private

  def infer_device_type(client)
    ua = @player.user_agent

    return "fire_tv" if ua.include?("AFT")
    return "android_tv" if ua.include?("Android TV")
    return "raspberry_pi" if ua.include?("Raspbian") || ua.include?("raspberry")
    return "provisioned" if @player.app_version.present?

    case client.device_type
    when "desktop" then "browser_desktop"
    when "smartphone" then "browser_mobile"
    when "tablet" then "browser_tablet"
    when "tv" then "browser_tv"
    else "unknown"
    end
  end
end
