require "rails_helper"

RSpec.describe "Ad Playlists", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:ad) { create(:ad, account: account) }
  let(:playlist) { create(:playlist, account: account) }

  before { sign_in(user) }

  describe "GET /ads/:ad_id/playlists" do
    it "returns a successful response" do
      get ad_playlists_path(ad)
      expect(response).to be_successful
    end

    it "lists playlists containing the ad" do
      create(:playlist_ad, ad: ad, playlist: playlist)
      get ad_playlists_path(ad)
      expect(response.body).to include(playlist.name)
    end
  end

  describe "DELETE /ads/:ad_id/playlists/:id" do
    it "removes the ad from the playlist" do
      pa = create(:playlist_ad, ad: ad, playlist: playlist)
      expect {
        delete ad_playlist_path(ad, pa)
      }.to change(ad.playlist_ads, :count).by(-1)
    end

    it "redirects to the ad" do
      pa = create(:playlist_ad, ad: ad, playlist: playlist)
      delete ad_playlist_path(ad, pa)
      expect(response).to redirect_to(ad_path(ad))
    end
  end

  describe "tenant isolation" do
    it "returns 404 for another account's ad" do
      other_ad = create(:ad)
      get ad_playlists_path(other_ad)
      expect(response).to have_http_status(:not_found)
    end
  end
end
