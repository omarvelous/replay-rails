require "rails_helper"

RSpec.describe "Marketing::Pages", type: :request do
  describe "GET / (marketing root)" do
    it "returns a successful response" do
      get marketing_root_url(host: "replay.lvh.me")
      expect(response).to be_successful
    end

    it "includes the marketing headline" do
      get marketing_root_url(host: "replay.lvh.me")
      expect(response.body).to include("Your window, working 24/7")
    end
  end

  describe "GET /features" do
    it "returns a successful response" do
      get features_url(host: "replay.lvh.me")
      expect(response).to be_successful
    end
  end

  describe "GET /pricing" do
    it "returns a successful response" do
      get pricing_url(host: "replay.lvh.me")
      expect(response).to be_successful
    end
  end

  describe "GET /about" do
    it "returns a successful response" do
      get about_url(host: "replay.lvh.me")
      expect(response).to be_successful
    end
  end
end
