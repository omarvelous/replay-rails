require "rails_helper"

RSpec.describe "Play::Heartbeats" do
  let(:player) { create(:player) }
  let(:screen) { create(:screen) }

  before do
    host! "play.replay.localhost"
    pair_player!(screen, player)
    sign_in_player(player)
  end

  describe "POST /player/heartbeat" do
    it "returns 204 and updates heartbeat" do
      post "/player/heartbeat"
      expect(response).to have_http_status(:no_content)
      expect(player.reload.last_heartbeat_at).to be_within(5.seconds).of(Time.current)
    end

    it "updates session last_active_at" do
      post "/player/heartbeat"
      expect(PlayerSession.last.last_active_at).to be_within(5.seconds).of(Time.current)
    end

    it "returns 410 when unpaired" do
      screen.unpair_player!
      post "/player/heartbeat"
      expect(response).to have_http_status(:gone)
    end

    it "redirects to pairing without session" do
      PlayerSession.last.revoke!
      post "/player/heartbeat"
      expect(response).to redirect_to(new_player_path)
    end
  end
end
