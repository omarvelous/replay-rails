require "rails_helper"

RSpec.describe "Marketing::Pages" do
  before { host! "replay.localhost" }

  describe "GET / (marketing root)" do
    it "returns a successful response" do
      get "/"
      expect(response).to be_successful
    end

    it "includes the marketing headline" do
      get "/"
      expect(response.body).to include("working 24/7")
    end
  end

  describe "GET /features" do
    it "returns a successful response" do
      get "/features"
      expect(response).to be_successful
    end
  end

  describe "GET /pricing" do
    it "returns a successful response" do
      get "/pricing"
      expect(response).to be_successful
    end
  end

  describe "GET /about" do
    it "returns a successful response" do
      get "/about"
      expect(response).to be_successful
    end
  end
end
