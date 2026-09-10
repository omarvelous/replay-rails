require "rails_helper"

RSpec.describe "Go::Experiences" do
  before { host! "replay.localhost" }

  describe "GET /go/experiences/:id" do
    let(:account) { create(:account) }
    let(:experience) { create(:experience, account: account) }

    it "renders the kiosk view without authentication" do
      get go_experience_path(experience)
      expect(response).to be_successful
    end

    it "includes the listing address" do
      get go_experience_path(experience)
      expect(response.body).to include(experience.listing.address)
    end

    it "returns 404 for non-existent experience" do
      get go_experience_path(id: 999999)
      expect(response).to have_http_status(:not_found)
    end
  end
end
