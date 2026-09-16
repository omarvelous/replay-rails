require "rails_helper"

RSpec.describe ParseDeviceInfo do
  describe "#call" do
    it "parses browser info from user agent" do
      player = create(:player, user_agent: "Mozilla/5.0 (Windows NT 10.0) AppleWebKit/537.36 Chrome/120.0")

      described_class.new(player: player).call

      player.reload
      expect(player.browser_name).to be_present
      expect(player.os_name).to be_present
      expect(player.device_type).to eq("browser_desktop")
    end

    it "detects Fire TV from user agent" do
      player = create(:player, user_agent: "Mozilla/5.0 (Linux; Android 11; AFTSSS Build/NS6294)")

      described_class.new(player: player).call

      expect(player.reload.device_type).to eq("fire_tv")
    end

    it "detects Android TV" do
      player = create(:player, user_agent: "Mozilla/5.0 (Linux; Android TV; Nexus Player)")

      described_class.new(player: player).call

      expect(player.reload.device_type).to eq("android_tv")
    end

    it "detects Raspberry Pi" do
      player = create(:player, user_agent: "Mozilla/5.0 (X11; Linux armv7l; Raspbian)")

      described_class.new(player: player).call

      expect(player.reload.device_type).to eq("raspberry_pi")
    end

    it "marks provisioned devices" do
      player = create(:player, user_agent: "Mozilla/5.0", app_version: "1.0.0")

      described_class.new(player: player).call

      expect(player.reload.device_type).to eq("provisioned")
    end

    it "skips parsing when user_agent is blank" do
      player = create(:player, user_agent: nil)

      described_class.new(player: player).call

      expect(player.reload.device_type).to be_nil
    end
  end
end
