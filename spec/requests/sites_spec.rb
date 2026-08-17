require "rails_helper"

RSpec.describe "Sites" do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  before { sign_in(user) }

  describe "GET /sites" do
    it "returns a successful response" do
      get sites_path
      expect(response).to be_successful
    end

    it "lists sites for the current account" do
      site = create(:site, account: account, name: "Main Office")
      other_account_site = create(:site, name: "Other Office")

      get sites_path
      expect(response.body).to include("Main Office")
      expect(response.body).not_to include("Other Office")
    end
  end

  describe "GET /sites/new" do
    it "returns a successful response" do
      get new_site_path
      expect(response).to be_successful
    end
  end

  describe "POST /sites" do
    let(:valid_params) { { site: { name: "Downtown Office", address: "123 Main St" } } }

    context "with valid params" do
      it "creates a site scoped to the current account" do
        expect {
          post sites_path, params: valid_params
        }.to change(account.sites, :count).by(1)
      end

      it "redirects to the site" do
        post sites_path, params: valid_params
        expect(response).to redirect_to(site_path(Site.last))
      end
    end

    context "with invalid params" do
      it "does not create a site" do
        expect {
          post sites_path, params: { site: { name: "" } }
        }.not_to change(Site, :count)
      end

      it "returns 422" do
        post sites_path, params: { site: { name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /sites/:id" do
    it "shows the site" do
      site = create(:site, account: account, name: "Main Office")
      get site_path(site)
      expect(response).to be_successful
      expect(response.body).to include("Main Office")
    end

    it "returns 404 for another account's site" do
      other_site = create(:site)
      get site_path(other_site)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /sites/:id/edit" do
    it "returns a successful response" do
      site = create(:site, account: account)
      get edit_site_path(site)
      expect(response).to be_successful
    end
  end

  describe "PATCH /sites/:id" do
    let(:site) { create(:site, account: account, name: "Old Name") }

    context "with valid params" do
      it "updates the site" do
        patch site_path(site), params: { site: { name: "New Name" } }
        expect(site.reload.name).to eq("New Name")
      end

      it "redirects to the site" do
        patch site_path(site), params: { site: { name: "New Name" } }
        expect(response).to redirect_to(site_path(site))
      end
    end

    context "with invalid params" do
      it "returns 422" do
        patch site_path(site), params: { site: { name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /sites/:id" do
    it "destroys the site" do
      site = create(:site, account: account)
      expect {
        delete site_path(site)
      }.to change(account.sites, :count).by(-1)
    end

    it "redirects to the index" do
      site = create(:site, account: account)
      delete site_path(site)
      expect(response).to redirect_to(sites_path)
    end
  end

  describe "authentication" do
    it "redirects unauthenticated users" do
      delete session_path
      get sites_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
