require "rails_helper"

RSpec.describe "Api::Players::Heartbeats" do
  let(:player) { create(:player) }
  let(:screen) { create(:screen) }

  before do
    host! "play.replay.localhost"
    pair_player!(screen, player)
    sign_in_player(player)
  end

  describe "POST /v1/player/heartbeat" do
    it "updates last_heartbeat_at" do
      post "/api/v1/player/heartbeat"
      expect(response).to have_http_status(:no_content)

      player.reload
      expect(player.last_heartbeat_at).to be_within(5.seconds).of(Time.current)
      expect(player.ip_address).to be_present
    end

    it "updates session last_active_at" do
      post "/api/v1/player/heartbeat"
      expect(PlayerSession.last.last_active_at).to be_within(5.seconds).of(Time.current)
    end

    it "returns 401 with revoked session" do
      PlayerSession.last.revoke!
      post "/api/v1/player/heartbeat"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 410 when player is unpaired" do
      screen.unpair_player!
      post "/api/v1/player/heartbeat"
      expect(response).to have_http_status(:gone)
    end

    it "updates user_agent" do
      post "/api/v1/player/heartbeat", headers: { "User-Agent" => "NewBrowser/1.0" }
      expect(player.reload.user_agent).to eq("NewBrowser/1.0")
    end

    it "updates screen resolution from params" do
      post "/api/v1/player/heartbeat",
        params: { screen_width: 3840, screen_height: 2160 }.to_json,
        headers: { "Content-Type" => "application/json" }
      player.reload
      expect(player.screen_width).to eq(3840)
      expect(player.screen_height).to eq(2160)
    end
  end
end
