require "rails_helper"

RSpec.describe "Api::Players::Heartbeats" do
  let(:player) { create(:player) }
  let(:screen) { create(:screen) }

  before do
    host! "api.replay.localhost"
    screen.pair_player!(player)
  end

  describe "POST /players/:token/heartbeat" do
    it "updates last_heartbeat_at" do
      post "/players/#{player.token}/heartbeat"
      expect(response).to be_successful

      player.reload
      expect(player.last_heartbeat_at).to be_within(5.seconds).of(Time.current)
      expect(player.ip_address).to be_present
    end

    it "returns 401 for invalid token" do
      post "/players/invalid/heartbeat"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 410 when player is unpaired" do
      screen.unpair_player!

      post "/players/#{player.token}/heartbeat"

      expect(response).to have_http_status(:gone)
      expect(response.parsed_body["error"]).to eq("unpaired")
    end

    it "updates user_agent" do
      post "/players/#{player.token}/heartbeat", headers: { "User-Agent" => "NewBrowser/1.0" }
      expect(player.reload.user_agent).to eq("NewBrowser/1.0")
    end

    it "updates screen resolution from params" do
      post "/players/#{player.token}/heartbeat",
        params: { screen_width: 3840, screen_height: 2160 }.to_json,
        headers: { "Content-Type" => "application/json" }
      player.reload
      expect(player.screen_width).to eq(3840)
      expect(player.screen_height).to eq(2160)
    end
  end
end
