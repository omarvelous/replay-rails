require "rails_helper"

RSpec.describe "PlaylistAds", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:playlist) { create(:playlist, account: account) }
  let(:ad) { create(:ad, account: account) }

  before { sign_in(user) }

  describe "GET /playlist_ads (from playlist)" do
    it "returns ads for a playlist" do
      create(:playlist_ad, playlist: playlist, ad: ad)
      get playlist_ads_path(playlist_id: playlist.id)
      expect(response).to be_successful
      expect(response.body).to include(ad.headline)
    end
  end

  describe "GET /playlist_ads (from ad)" do
    it "returns playlists for an ad" do
      create(:playlist_ad, playlist: playlist, ad: ad)
      get playlist_ads_path(ad_id: ad.id)
      expect(response).to be_successful
      expect(response.body).to include(playlist.name)
    end
  end

  describe "GET /playlist_ads/new" do
    it "returns a successful response with playlist context" do
      get new_playlist_ad_path(playlist_id: playlist.id)
      expect(response).to be_successful
    end
  end

  describe "POST /playlist_ads" do
    let(:valid_params) { { playlist_ad: { playlist_id: playlist.id, ad_id: ad.id, position: 1, duration: 15 } } }

    context "with valid params" do
      it "creates a playlist ad" do
        expect {
          post playlist_ads_path, params: valid_params
        }.to change(PlaylistAd, :count).by(1)
      end

      it "redirects to the playlist" do
        post playlist_ads_path(playlist_id: playlist.id), params: valid_params
        expect(response).to redirect_to(playlist_path(playlist))
      end
    end

    context "with invalid params" do
      it "returns 422 when ad is missing" do
        post playlist_ads_path, params: { playlist_ad: { playlist_id: playlist.id, ad_id: "", position: 1, duration: 10 } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /playlist_ads/:id/edit" do
    it "returns a successful response" do
      pa = create(:playlist_ad, playlist: playlist, ad: ad)
      get edit_playlist_ad_path(pa)
      expect(response).to be_successful
    end
  end

  describe "PATCH /playlist_ads/:id" do
    let(:playlist_ad) { create(:playlist_ad, playlist: playlist, ad: ad, duration: 10) }

    it "updates the playlist ad" do
      patch playlist_ad_path(playlist_ad), params: { playlist_ad: { duration: 20 } }
      expect(playlist_ad.reload.duration).to eq(20)
    end

    it "redirects to the playlist" do
      patch playlist_ad_path(playlist_ad), params: { playlist_ad: { duration: 20 } }
      expect(response).to redirect_to(playlist_path(playlist))
    end
  end

  describe "DELETE /playlist_ads/:id" do
    it "destroys the playlist ad" do
      pa = create(:playlist_ad, playlist: playlist, ad: ad)
      expect {
        delete playlist_ad_path(pa)
      }.to change(PlaylistAd, :count).by(-1)
    end

    it "redirects to the playlist" do
      pa = create(:playlist_ad, playlist: playlist, ad: ad)
      delete playlist_ad_path(pa)
      expect(response).to redirect_to(playlist_path(playlist))
    end
  end

  describe "tenant isolation" do
    it "returns 404 for another account's playlist" do
      other_playlist = create(:playlist)
      get playlist_ads_path(playlist_id: other_playlist.id)
      expect(response).to have_http_status(:not_found)
    end
  end
end
