require "rails_helper"

RSpec.describe ScreenHelper do
  let(:account) { create(:account) }
  let(:site) { create(:site, account: account) }
  let(:screen) { create(:screen, site: site) }

  describe "#screen_status" do
    it "returns :no_player when screen has no player" do
      expect(helper.screen_status(screen)).to eq(:no_player)
    end

    it "returns :offline when player is not online" do
      player = create(:player, last_heartbeat_at: 10.minutes.ago)
      screen.pair_player!(player)
      expect(helper.screen_status(screen)).to eq(:offline)
    end

    it "returns :online when player is online but no playlist" do
      player = create(:player, last_heartbeat_at: 30.seconds.ago)
      screen.pair_player!(player)
      expect(helper.screen_status(screen)).to eq(:online)
    end

    it "returns :live when player is online and playlist is active" do
      player = create(:player, last_heartbeat_at: 30.seconds.ago)
      screen.pair_player!(player)
      playlist = create(:playlist, account: account)
      expect(helper.screen_status(screen, active_playlist: playlist)).to eq(:live)
    end
  end

  describe "#screen_status_badge" do
    it "renders a badge for each status" do
      %i[no_player offline online live].each do |status|
        badge = helper.screen_status_badge(status)
        expect(badge).to include("rounded-full")
      end
    end
  end

  describe "#screen_heartbeat_text" do
    it "returns 'No player assigned' for :no_player" do
      expect(helper.screen_heartbeat_text(screen, :no_player)).to eq("No player assigned")
    end

    it "returns 'Never connected' for :offline with no heartbeat" do
      player = create(:player, last_heartbeat_at: nil)
      screen.pair_player!(player)
      expect(helper.screen_heartbeat_text(screen, :offline)).to eq("Never connected")
    end

    it "returns 'Last seen ...' for :offline with heartbeat" do
      player = create(:player, last_heartbeat_at: 10.minutes.ago)
      screen.pair_player!(player)
      expect(helper.screen_heartbeat_text(screen, :offline)).to include("Last seen")
    end

    it "returns 'Heartbeat ...' for :online" do
      player = create(:player, last_heartbeat_at: 30.seconds.ago)
      screen.pair_player!(player)
      expect(helper.screen_heartbeat_text(screen, :online)).to include("Heartbeat")
    end

    it "returns 'Heartbeat ...' for :live" do
      player = create(:player, last_heartbeat_at: 30.seconds.ago)
      screen.pair_player!(player)
      expect(helper.screen_heartbeat_text(screen, :live)).to include("Heartbeat")
    end
  end

  describe "#screen_heartbeat_icon_color" do
    it "returns a color class for each status" do
      expect(helper.screen_heartbeat_icon_color(:no_player)).to eq("text-gray-300")
      expect(helper.screen_heartbeat_icon_color(:offline)).to eq("text-red-400")
      expect(helper.screen_heartbeat_icon_color(:online)).to eq("text-blue-400")
      expect(helper.screen_heartbeat_icon_color(:live)).to eq("text-green-500")
    end
  end
end
