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
  end
end
