require "rails_helper"

RSpec.describe "Go::Listings" do
  before { host! "replay.localhost" }

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

    it "renders a swipeable photo gallery" do
      listing = create(:listing)
      listing.photos.attach(
        io: StringIO.new("fake-image"),
        filename: "photo1.jpg",
        content_type: "image/jpeg"
      )
      listing.photos.attach(
        io: StringIO.new("fake-image2"),
        filename: "photo2.jpg",
        content_type: "image/jpeg"
      )
      get go_listing_path(listing)
      expect(response.body).to include("photo-gallery")
    end

    it "displays listing description when present" do
      listing = create(:listing, description: "Stunning three-bedroom apartment")
      get go_listing_path(listing)
      expect(response.body).to include("Stunning three-bedroom apartment")
    end

    it "displays listing type badge" do
      listing = create(:listing, listing_type: "for_sale")
      get go_listing_path(listing)
      expect(response.body).to include("For Sale")
    end

    it "displays get directions link" do
      listing = create(:listing, address: "350 Fifth Ave")
      get go_listing_path(listing)
      expect(response.body).to include("maps.google.com")
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
