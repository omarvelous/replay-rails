require "rails_helper"

RSpec.describe "Playlists", type: :request do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  before { sign_in(user) }

  describe "GET /playlists" do
    it "returns a successful response" do
      get playlists_path
      expect(response).to be_successful
    end

    it "lists playlists for the current account" do
      playlist = create(:playlist, account: account, name: "Evening Rotation")
      other_playlist = create(:playlist, name: "Other Playlist")

      get playlists_path
      expect(response.body).to include("Evening Rotation")
      expect(response.body).not_to include("Other Playlist")
    end
  end

  describe "GET /playlists/new" do
    it "returns a successful response" do
      get new_playlist_path
      expect(response).to be_successful
    end
  end

  describe "POST /playlists" do
    let(:valid_params) do
      { playlist: { name: "Weekend Showcase", status: "draft" } }
    end

    context "with valid params" do
      it "creates a playlist scoped to the current account" do
        expect {
          post playlists_path, params: valid_params
        }.to change(account.playlists, :count).by(1)
      end

      it "redirects to the playlist" do
        post playlists_path, params: valid_params
        expect(response).to redirect_to(playlist_path(Playlist.last))
      end
    end

    context "with ads via nested attributes" do
      it "creates a playlist with ads" do
        ad = create(:ad, account: account)
        params = {
          playlist: {
            name: "With Ads",
            status: "draft",
            playlist_ads_attributes: [
              { ad_id: ad.id, position: 1, duration: 15 }
            ]
          }
        }

        expect {
          post playlists_path, params: params
        }.to change(PlaylistAd, :count).by(1)

        expect(Playlist.last.playlist_ads.first.duration).to eq(15)
      end
    end

    context "with invalid params" do
      it "does not create a playlist" do
        expect {
          post playlists_path, params: { playlist: { name: "" } }
        }.not_to change(Playlist, :count)
      end

      it "returns 422" do
        post playlists_path, params: { playlist: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /playlists/:id" do
    it "shows the playlist" do
      playlist = create(:playlist, account: account, name: "Evening Rotation")
      get playlist_path(playlist)
      expect(response).to be_successful
      expect(response.body).to include("Evening Rotation")
    end

    it "returns 404 for another account's playlist" do
      other_playlist = create(:playlist)
      get playlist_path(other_playlist)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /playlists/:id/edit" do
    it "returns a successful response" do
      playlist = create(:playlist, account: account)
      get edit_playlist_path(playlist)
      expect(response).to be_successful
    end
  end

  describe "PATCH /playlists/:id" do
    let(:playlist) { create(:playlist, account: account, name: "Old Name") }

    context "with valid params" do
      it "updates the playlist" do
        patch playlist_path(playlist), params: { playlist: { name: "New Name" } }
        expect(playlist.reload.name).to eq("New Name")
      end

      it "updates the status" do
        patch playlist_path(playlist), params: { playlist: { status: "published" } }
        expect(playlist.reload.status).to eq("published")
      end

      it "redirects to the playlist" do
        patch playlist_path(playlist), params: { playlist: { name: "New Name" } }
        expect(response).to redirect_to(playlist_path(playlist))
      end
    end

    context "with invalid params" do
      it "returns 422" do
        patch playlist_path(playlist), params: { playlist: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /playlists/:id" do
    it "destroys the playlist" do
      playlist = create(:playlist, account: account)
      expect {
        delete playlist_path(playlist)
      }.to change(account.playlists, :count).by(-1)
    end

    it "redirects to the index" do
      playlist = create(:playlist, account: account)
      delete playlist_path(playlist)
      expect(response).to redirect_to(playlists_path)
    end
  end
end
