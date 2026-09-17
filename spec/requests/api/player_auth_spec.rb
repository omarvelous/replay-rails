require "rails_helper"

RSpec.describe "Player Authentication" do
  let(:player) { create(:player) }
  let(:screen) { create(:screen) }

  before do
    host! "api.replay.localhost"
    pair_player!(screen, player)
  end

  describe "bearer token auth" do
    it "authenticates with Authorization: Bearer header" do
      get "/v1/player", headers: { "Authorization" => "Bearer #{player.token}" }
      expect(response).to be_successful
    end

    it "returns 401 with invalid bearer token" do
      get "/v1/player", headers: { "Authorization" => "Bearer invalid" }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "cookie auth" do
    it "authenticates with signed player_token cookie" do
      sign_in_player(player)
      get "/v1/player"
      expect(response).to be_successful
    end

    it "returns 401 with no credentials" do
      get "/v1/player"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "bearer takes precedence over cookie" do
    let(:other_player) { create(:player) }

    it "uses bearer when both are present" do
      sign_in_player(other_player)
      get "/v1/player", headers: { "Authorization" => "Bearer #{player.token}" }
      expect(response).to be_successful
      expect(response.parsed_body["data"]["paired"]).to be true
    end
  end

  describe "registration" do
    it "returns public_id in the response" do
      post "/v1/players", as: :json
      data = response.parsed_body["data"]
      expect(data["public_id"]).to be_present
    end

    it "returns the token for bearer auth fallback" do
      post "/v1/players", as: :json
      data = response.parsed_body["data"]
      expect(data["token"]).to be_present
    end
  end
end
