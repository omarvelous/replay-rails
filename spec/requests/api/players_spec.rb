require "rails_helper"

RSpec.describe "Api::Players" do
  before { host! "api.replay.localhost" }

  describe "POST /v1/players" do
    it "registers a player and returns JSON" do
      expect {
        post "/v1/players", as: :json
      }.to change(Player, :count).by(1)

      expect(response).to have_http_status(:created)
      data = response.parsed_body["data"]
      expect(data["token"]).to be_present
      expect(data["pairing_code"]).to match(/\A[A-Z0-9]{6}\z/)
      expect(data["expires_in"]).to eq(600)
    end

    it "accepts device info params" do
      post "/v1/players",
        params: { screen_width: 1920, screen_height: 1080, touch_capable: true, app_version: "1.0.0" },
        as: :json

      player = Player.last
      expect(player.screen_width).to eq(1920)
      expect(player.screen_height).to eq(1080)
      expect(player.touch_capable).to be true
      expect(player.app_version).to eq("1.0.0")
    end

    it "parses user agent into device fields" do
      post "/v1/players",
        headers: { "User-Agent" => "Mozilla/5.0 (Linux; Android 11; AFTSSS Build/NS6294) AppleWebKit/537.36" },
        as: :json

      player = Player.last
      expect(player.device_type).to be_present
    end
  end

  describe "GET /v1/players/:token" do
    let(:player) { create(:player) }

    it "returns paired: false when not paired" do
      get "/v1/players/#{player.token}"
      expect(response).to be_successful
      data = response.parsed_body["data"]
      expect(data["paired"]).to be false
    end

    it "returns paired: true when paired" do
      screen = create(:screen)
      screen.pair_player!(player)

      get "/v1/players/#{player.token}"
      expect(response).to be_successful
      data = response.parsed_body["data"]
      expect(data["paired"]).to be true
    end

    it "returns 401 for invalid token" do
      get "/v1/players/invalid"
      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body["error"]["message"]).to be_present
    end
  end

  describe "POST /v1/players/:token/pairing_code" do
    let(:player) { create(:player) }

    it "returns the existing code if still valid" do
      existing_code = player.pairing_code

      post "/v1/players/#{player.token}/pairing_code", as: :json

      expect(response).to have_http_status(:created)
      data = response.parsed_body["data"]
      expect(data["pairing_code"]).to eq(existing_code)
      expect(data["expires_in"]).to be_between(1, 600)
    end

    it "generates a new code if the current one has expired" do
      player.update!(pairing_code_expires_at: 1.minute.ago)
      old_code = player.pairing_code

      post "/v1/players/#{player.token}/pairing_code", as: :json

      expect(response).to have_http_status(:created)
      data = response.parsed_body["data"]
      expect(data["pairing_code"]).to match(/\A[A-Z0-9]{6}\z/)
      expect(data["pairing_code"]).not_to eq(old_code)
      expect(data["expires_in"]).to eq(600)
    end

    it "does not create a new player" do
      player # ensure created

      expect {
        post "/v1/players/#{player.token}/pairing_code", as: :json
      }.not_to change(Player, :count)
    end

    it "returns 401 for invalid token" do
      post "/v1/players/invalid/pairing_code", as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
