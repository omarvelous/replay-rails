require "rails_helper"

RSpec.describe "Playlist Ads", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:playlist) { create(:playlist, account: account) }
  let(:ad) { create(:ad, account: account) }

  before { sign_in(user) }

  describe "GET /playlists/:playlist_id/ads/new" do
    it "returns a successful response" do
      get new_playlist_ad_path(playlist)
      expect(response).to be_successful
    end
  end

  describe "POST /playlists/:playlist_id/ads" do
    let(:valid_params) { { playlist_ad: { ad_id: ad.id, position: 1, duration: 15 } } }

    context "with valid params" do
      it "adds an ad to the playlist" do
        expect {
          post playlist_ads_path(playlist), params: valid_params
        }.to change(playlist.playlist_ads, :count).by(1)
      end

      it "redirects to the playlist" do
        post playlist_ads_path(playlist), params: valid_params
        expect(response).to redirect_to(playlist_path(playlist))
      end
    end

    context "with invalid params" do
      it "returns 422 when ad is missing" do
        post playlist_ads_path(playlist), params: { playlist_ad: { ad_id: "", position: 1, duration: 10 } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /playlists/:playlist_id/ads/:id/edit" do
    it "returns a successful response" do
      pa = create(:playlist_ad, playlist: playlist, ad: ad)
      get edit_playlist_ad_path(playlist, pa)
      expect(response).to be_successful
    end
  end

  describe "PATCH /playlists/:playlist_id/ads/:id" do
    let(:playlist_ad) { create(:playlist_ad, playlist: playlist, ad: ad, duration: 10) }

    it "updates the playlist ad" do
      patch playlist_ad_path(playlist, playlist_ad), params: { playlist_ad: { duration: 20 } }
      expect(playlist_ad.reload.duration).to eq(20)
    end

    it "redirects to the playlist" do
      patch playlist_ad_path(playlist, playlist_ad), params: { playlist_ad: { duration: 20 } }
      expect(response).to redirect_to(playlist_path(playlist))
    end
  end

  describe "DELETE /playlists/:playlist_id/ads/:id" do
    it "removes the ad from the playlist" do
      pa = create(:playlist_ad, playlist: playlist, ad: ad)
      expect {
        delete playlist_ad_path(playlist, pa)
      }.to change(playlist.playlist_ads, :count).by(-1)
    end

    it "redirects to the playlist" do
      pa = create(:playlist_ad, playlist: playlist, ad: ad)
      delete playlist_ad_path(playlist, pa)
      expect(response).to redirect_to(playlist_path(playlist))
    end
  end

  describe "tenant isolation" do
    it "returns 404 for another account's playlist" do
      other_playlist = create(:playlist)
      get new_playlist_ad_path(other_playlist)
      expect(response).to have_http_status(:not_found)
    end
  end
end
