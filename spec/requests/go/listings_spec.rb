require "rails_helper"

RSpec.describe "Go::Listings", type: :request do
  describe "GET /go/listings/:id" do
    it "returns a successful response without authentication" do
      listing = create(:listing)
      get go_listing_path(listing)
      expect(response).to be_successful
    end

    it "displays listing details" do
      listing = create(:listing, address: "350 Fifth Ave", price: 2_500_000)
      get go_listing_path(listing)
      expect(response.body).to include("350 Fifth Ave")
      expect(response.body).to include("$2,500,000")
    end

    it "displays agents for the listing" do
      listing = create(:listing)
      agent = create(:agent, account: listing.account, name: "Jane Broker")
      create(:listing_agent, listing: listing, agent: agent)
      get go_listing_path(listing)
      expect(response.body).to include("Jane Broker")
    end
  end
end
