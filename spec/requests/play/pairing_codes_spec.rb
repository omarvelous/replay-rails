require "rails_helper"

RSpec.describe "Play::PairingCodes" do
  let(:player) { create(:player) }

  before do
    host! "play.replay.localhost"
    sign_in_player(player)
  end

  describe "POST /player/pairing_code" do
    it "returns the existing code if still valid" do
      existing_code = player.pairing_code

      post "/player/pairing_code", as: :json
      expect(response).to have_http_status(:created)

      data = response.parsed_body
      expect(data["pairing_code"]).to eq(existing_code)
      expect(data["expires_at"]).to be_present
    end

    it "generates a new code if expired" do
      player.update!(pairing_code_expires_at: 1.minute.ago)
      old_code = player.pairing_code

      post "/player/pairing_code", as: :json
      expect(response).to have_http_status(:created)

      data = response.parsed_body
      expect(data["pairing_code"]).not_to eq(old_code)
      expect(data["pairing_code"]).to match(/\A[A-Z0-9]{6}\z/)
    end

    it "redirects to pairing without session" do
      PlayerSession.last.revoke!
      post "/player/pairing_code", as: :json
      expect(response).to redirect_to(new_player_path)
    end
  end
end
