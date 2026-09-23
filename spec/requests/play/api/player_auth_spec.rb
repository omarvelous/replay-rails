require "rails_helper"

RSpec.describe "Player Authentication" do
  let(:player) { create(:player) }
  let(:screen) { create(:screen) }

  before do
    host! "play.replay.localhost"
    pair_player!(screen, player)
  end

  describe "bearer auth" do
    it "authenticates with a signed session token" do
      player_session = player.player_sessions.create!(ip_address: "1.1.1.1")
      token = Rails.application.message_verifier(:player_session).generate(player_session.id)

      get "/api/v1/player", headers: { "Authorization" => "Bearer #{token}" }
      expect(response).to be_successful
    end

    it "returns 401 with an invalid bearer token" do
      get "/api/v1/player", headers: { "Authorization" => "Bearer invalid" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with a revoked session bearer token" do
      player_session = player.player_sessions.create!(ip_address: "1.1.1.1")
      token = Rails.application.message_verifier(:player_session).generate(player_session.id)
      player_session.revoke!

      get "/api/v1/player", headers: { "Authorization" => "Bearer #{token}" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "cookie auth" do
    it "authenticates with signed player_session_id cookie" do
      sign_in_player(player)
      get "/api/v1/player"
      expect(response).to be_successful
    end

    it "returns 401 with no credentials" do
      get "/api/v1/player"
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with revoked session" do
      sign_in_player(player)
      PlayerSession.last.revoke!
      get "/api/v1/player"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "registration" do
    it "returns token and public_id" do
      post "/api/v1/players", as: :json
      data = response.parsed_body["data"]
      expect(data["token"]).to be_present
      expect(data["public_id"]).to be_present
    end

    it "creates a PlayerSession" do
      expect {
        post "/api/v1/players", as: :json
      }.to change(PlayerSession, :count).by(1)
    end
  end
end
