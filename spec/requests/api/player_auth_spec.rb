require "rails_helper"

RSpec.describe "Player Authentication" do
  let(:player) { create(:player) }
  let(:screen) { create(:screen) }

  before do
    host! "api.replay.localhost"
    pair_player!(screen, player)
  end

  describe "cookie auth" do
    it "authenticates with signed player_session_id cookie" do
      sign_in_player(player)
      get "/v1/player"
      expect(response).to be_successful
    end

    it "returns 401 with no credentials" do
      get "/v1/player"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with revoked session" do
      sign_in_player(player)
      PlayerSession.last.revoke!
      get "/v1/player"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "registration" do
    it "returns session_id and public_id" do
      post "/v1/players", as: :json
      data = response.parsed_body["data"]
      expect(data["session_id"]).to be_present
      expect(data["public_id"]).to be_present
    end

    it "creates a PlayerSession" do
      expect {
        post "/v1/players", as: :json
      }.to change(PlayerSession, :count).by(1)
    end
  end
end
