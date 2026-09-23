require "rails_helper"

RSpec.describe "Api::Players" do
  before { host! "play.replay.localhost" }

  describe "POST /v1/players" do
    it "registers a player and returns JSON with session_id and public_id" do
      expect {
        post "/api/v1/players", as: :json
      }.to change(Player, :count).by(1)

      expect(response).to have_http_status(:created)
      data = response.parsed_body["data"]
      expect(data["session_id"]).to be_present
      expect(data["public_id"]).to be_present
      expect(data["pairing_code"]).to match(/\A[A-Z0-9]{6}\z/)
      expect(data["expires_at"]).to be_present
    end

    it "accepts device info params" do
      post "/api/v1/players",
        params: { screen_width: 1920, screen_height: 1080, touch_capable: true, app_version: "1.0.0" },
        as: :json

      player = Player.last
      expect(player.screen_width).to eq(1920)
      expect(player.screen_height).to eq(1080)
      expect(player.touch_capable).to be true
      expect(player.app_version).to eq("1.0.0")
    end

    it "parses user agent into device fields" do
      post "/api/v1/players",
        headers: { "User-Agent" => "Mozilla/5.0 (Linux; Android 11; AFTSSS Build/NS6294) AppleWebKit/537.36" },
        as: :json

      player = Player.last
      expect(player.device_type).to be_present
    end
  end

  describe "GET /v1/player" do
    let(:player) { create(:player) }

    it "returns paired: false when not paired" do
      sign_in_player(player)
      get "/api/v1/player"
      expect(response).to be_successful
      data = response.parsed_body["data"]
      expect(data["paired"]).to be false
    end

    it "returns paired: true when paired" do
      screen = create(:screen)
      pair_player!(screen, player)
      sign_in_player(player)

      get "/api/v1/player"
      expect(response).to be_successful
      data = response.parsed_body["data"]
      expect(data["paired"]).to be true
    end

    it "returns 401 without session" do
      get "/api/v1/player"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /v1/player/pairing_code" do
    let(:player) { create(:player) }

    before { sign_in_player(player) }

    it "returns the existing code if still valid" do
      existing_code = player.pairing_code

      post "/api/v1/player/pairing_code", as: :json

      expect(response).to have_http_status(:created)
      data = response.parsed_body["data"]
      expect(data["pairing_code"]).to eq(existing_code)
      expect(data["expires_at"]).to be_present
    end

    it "generates a new code if the current one has expired" do
      player.update!(pairing_code_expires_at: 1.minute.ago)
      old_code = player.pairing_code

      post "/api/v1/player/pairing_code", as: :json

      expect(response).to have_http_status(:created)
      data = response.parsed_body["data"]
      expect(data["pairing_code"]).to match(/\A[A-Z0-9]{6}\z/)
      expect(data["pairing_code"]).not_to eq(old_code)
      expect(data["expires_at"]).to be_present
    end

    it "does not create a new player" do
      player # ensure created

      expect {
        post "/api/v1/player/pairing_code", as: :json
      }.not_to change(Player, :count)
    end

    it "returns 401 with revoked session" do
      PlayerSession.last.revoke!
      post "/api/v1/player/pairing_code", as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
