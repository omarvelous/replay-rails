require "rails_helper"

RSpec.describe RegisterPlayer do
  describe "#call" do
    it "creates a player" do
      result = described_class.new(
        ip_address: "1.1.1.1",
        user_agent: "Mozilla/5.0",
        params: {}
      ).call

      expect(result).to be_success
      expect(result.player).to be_persisted
    end

    it "creates a player session" do
      result = described_class.new(
        ip_address: "1.1.1.1",
        user_agent: "Mozilla/5.0",
        params: {}
      ).call

      expect(result.session).to be_persisted
      expect(result.session.player).to eq(result.player)
      expect(result.session.ip_address).to eq("1.1.1.1")
    end

    it "generates a pairing code" do
      result = described_class.new(
        ip_address: "1.1.1.1",
        user_agent: "Mozilla/5.0",
        params: {}
      ).call

      expect(result.player.pairing_code).to match(/\A[A-Z0-9]{6}\z/)
    end

    it "accepts device info params" do
      result = described_class.new(
        ip_address: "1.1.1.1",
        user_agent: "Mozilla/5.0",
        params: { screen_width: 1920, screen_height: 1080, touch_capable: true, app_version: "1.0" }
      ).call

      player = result.player
      expect(player.screen_width).to eq(1920)
      expect(player.screen_height).to eq(1080)
      expect(player.touch_capable).to be true
      expect(player.app_version).to eq("1.0")
    end

    it "parses device info from user agent" do
      result = described_class.new(
        ip_address: "1.1.1.1",
        user_agent: "Mozilla/5.0 (Linux; Android 11; AFTSSS Build/NS6294) AppleWebKit/537.36",
        params: {}
      ).call

      expect(result.player.device_type).to be_present
    end
  end
end
