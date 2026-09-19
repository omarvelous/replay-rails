require "rails_helper"

RSpec.describe "Go::Experiences" do
  before { host! "replay.localhost" }

  describe "GET /go/experiences/:id" do
    let(:account) { create(:account) }
    let(:experience) { create(:experience, account: account) }

    it "renders the public landing page without authentication" do
      get go_experience_path(experience)
      expect(response).to be_successful
    end

    it "uses the public layout" do
      get go_experience_path(experience)
      expect(response.body).to include("RePlay")
      expect(response.body).not_to include("data-controller=\"slideshow")
    end

    it "displays the listing details" do
      get go_experience_path(experience)
      expect(response.body).to include(ERB::Util.html_escape(experience.listing.address))
    end

    it "displays the experience's agent" do
      agent = experience.default_agent
      if agent
        get go_experience_path(experience)
        expect(response.body).to include(ERB::Util.html_escape(agent.name))
      end
    end

    it "renders the lead form" do
      get go_experience_path(experience)
      expect(response.body).to include("Send inquiry")
    end

    it "returns 404 for non-existent experience" do
      get go_experience_path(id: SecureRandom.uuid)
      expect(response).to have_http_status(:not_found)
    end
  end
end
