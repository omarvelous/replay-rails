require "rails_helper"

RSpec.describe "ScreenPlayers", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:site) { create(:site, account: account) }
  let(:screen) { create(:screen, site: site) }

  before { sign_in(user) }

  describe "GET /screens/:screen_id/screen_player/new" do
    it "returns a successful response" do
      get new_screen_screen_player_path(screen)
      expect(response).to be_successful
    end
  end

  describe "POST /screens/:screen_id/screen_player" do
    let(:player) { create(:player) }

    it "pairs the player to the screen" do
      post screen_screen_player_path(screen), params: { code: player.pairing_code }
      expect(screen.reload).to be_paired
      expect(screen.player).to eq(player)
    end

    it "records the user who paired" do
      post screen_screen_player_path(screen), params: { code: player.pairing_code }
      expect(screen.reload.active_player_assignment.paired_by).to eq(user)
    end

    it "redirects to the screen with notice" do
      post screen_screen_player_path(screen), params: { code: player.pairing_code }
      expect(response).to redirect_to(screen_path(screen))
      expect(flash[:notice]).to be_present
    end

    it "redirects with alert for unknown code" do
      post screen_screen_player_path(screen), params: { code: "XXXXXX" }
      expect(response).to redirect_to(new_screen_screen_player_path(screen))
      expect(flash[:alert]).to include("not found")
    end

    it "redirects with alert for expired code" do
      player.update!(pairing_code_expires_at: 1.minute.ago)
      post screen_screen_player_path(screen), params: { code: player.pairing_code }
      expect(response).to redirect_to(new_screen_screen_player_path(screen))
      expect(flash[:alert]).to include("expired")
    end
  end

  describe "DELETE /screens/:screen_id/screen_player" do
    it "unpairs the player" do
      player = create(:player)
      screen.pair_player!(player)

      delete screen_screen_player_path(screen)
      expect(screen.reload).not_to be_paired
    end

    it "redirects to the screen" do
      player = create(:player)
      screen.pair_player!(player)

      delete screen_screen_player_path(screen)
      expect(response).to redirect_to(screen_path(screen))
    end
  end

  describe "tenant isolation" do
    it "returns 404 for another account's screen" do
      other_screen = create(:screen)
      get new_screen_screen_player_path(other_screen)
      expect(response).to have_http_status(:not_found)
    end
  end
end
