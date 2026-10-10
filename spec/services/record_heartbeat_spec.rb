require "rails_helper"

RSpec.describe RecordHeartbeat do
  let(:account) { create(:account) }
  let(:site) { create(:site, account: account) }
  let(:screen) { create(:screen, site: site) }
  let(:player) { create(:player, ip_address: "192.168.1.1", user_agent: "Old UA") }
  let(:session) { PlayerSession.create!(player: player) }

  before do
    create(:screen_player, screen: screen, player: player)
    player.reload
  end

  describe "#call" do
    it "updates the player heartbeat and session" do
      result = described_class.new(
        player: player, session: session,
        ip_address: "10.0.0.1", user_agent: "Old UA"
      ).call

      expect(result.success?).to be true
      expect(player.reload.last_heartbeat_at).to be_present
      expect(player.ip_address).to eq("10.0.0.1")
      expect(session.reload.last_active_at).to be_present
    end

    it "updates screen dimensions from params" do
      described_class.new(
        player: player, session: session,
        ip_address: "10.0.0.1", user_agent: "Old UA",
        params: { screen_width: 1920, screen_height: 1080 }
      ).call

      player.reload
      expect(player.screen_width).to eq(1920)
      expect(player.screen_height).to eq(1080)
    end

    it "returns failure when player has no screen" do
      unscreened = create(:player)
      unscreened_session = PlayerSession.create!(player: unscreened)

      result = described_class.new(
        player: unscreened, session: unscreened_session,
        ip_address: "10.0.0.1", user_agent: "UA"
      ).call

      expect(result.success?).to be false
      expect(result.error).to eq("unpaired")
    end
  end
end
