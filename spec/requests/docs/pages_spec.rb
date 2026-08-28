require "rails_helper"

RSpec.describe "Docs::Pages" do
  before { host! "replay.localhost" }

  describe "GET /docs" do
    it "returns a successful response" do
      get "/docs"
      expect(response).to be_successful
    end

    it "does not require authentication" do
      get "/docs"
      expect(response).not_to redirect_to(new_session_url(subdomain: "app"))
    end

    it "lists doc categories" do
      get "/docs"
      expect(response.body).to include("Getting Started")
    end
  end

  describe "GET /docs/:slug" do
    it "returns a successful response for a valid page" do
      get "/docs/getting-started"
      expect(response).to be_successful
    end

    it "renders the page title" do
      get "/docs/getting-started"
      expect(response.body).to include("Quick Start Guide")
    end

    it "returns 404 for a nonexistent page" do
      get "/docs/nonexistent-page"
      expect(response).to have_http_status(:not_found)
    end
  end
end
