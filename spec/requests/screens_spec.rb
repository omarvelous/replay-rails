require "rails_helper"

RSpec.describe "Screens" do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:site) { create(:site, account: account) }

  before { sign_in(user) }

  describe "GET /screens" do
    it "returns a successful response" do
      get screens_path
      expect(response).to be_successful
    end

    it "lists all screens for the account" do
      create(:screen, site: site, name: "Lobby Display")
      other_account_screen = create(:screen)

      get screens_path
      expect(response.body).to include("Lobby Display")
      expect(response.body).not_to include(other_account_screen.name)
    end

    it "filters by site_id when provided" do
      create(:screen, site: site, name: "Lobby Display")
      other_site = create(:site, account: account)
      create(:screen, site: other_site, name: "Other Display")

      get screens_path(site_id: site.id)
      expect(response.body).to include("Lobby Display")
      expect(response.body).not_to include("Other Display")
    end
  end

  describe "GET /screens/new" do
    it "returns a successful response" do
      get new_screen_path(site_id: site.id)
      expect(response).to be_successful
    end
  end

  describe "POST /screens" do
    let(:valid_params) { { screen: { site_id: site.id, name: "Window Display", orientation: "landscape" } } }

    context "with valid params" do
      it "creates a screen scoped to the site" do
        expect {
          post screens_path, params: valid_params
        }.to change(site.screens, :count).by(1)
      end

      it "redirects to the screen" do
        post screens_path, params: valid_params
        expect(response).to redirect_to(screen_path(Screen.last))
      end
    end

    context "with invalid params" do
      it "does not create a screen" do
        expect {
          post screens_path, params: { screen: { site_id: site.id, name: "" } }
        }.not_to change(Screen, :count)
      end

      it "returns 422" do
        post screens_path, params: { screen: { site_id: site.id, name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /screens/:id" do
    it "shows the screen" do
      screen = create(:screen, site: site, name: "Lobby Display")
      get screen_path(screen)
      expect(response).to be_successful
      expect(response.body).to include("Lobby Display")
    end
  end

  describe "GET /screens/:id/edit" do
    it "returns a successful response" do
      screen = create(:screen, site: site)
      get edit_screen_path(screen)
      expect(response).to be_successful
    end
  end

  describe "PATCH /screens/:id" do
    let(:screen) { create(:screen, site: site, name: "Old Name") }

    context "with valid params" do
      it "updates the screen" do
        patch screen_path(screen), params: { screen: { name: "New Name" } }
        expect(screen.reload.name).to eq("New Name")
      end

      it "redirects to the screen" do
        patch screen_path(screen), params: { screen: { name: "New Name" } }
        expect(response).to redirect_to(screen_path(screen))
      end
    end

    context "with invalid params" do
      it "returns 422" do
        patch screen_path(screen), params: { screen: { name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /screens/:id" do
    it "destroys the screen" do
      screen = create(:screen, site: site)
      expect {
        delete screen_path(screen)
      }.to change(site.screens, :count).by(-1)
    end

    it "redirects to the site" do
      screen = create(:screen, site: site)
      delete screen_path(screen)
      expect(response).to redirect_to(site_path(site))
    end
  end

  describe "tenant isolation" do
    it "returns 404 for another account's screen" do
      other_screen = create(:screen)
      get screen_path(other_screen)
      expect(response).to have_http_status(:not_found)
    end
  end
end
