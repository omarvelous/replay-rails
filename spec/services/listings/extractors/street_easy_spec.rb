require "rails_helper"

RSpec.describe Listings::Extractors::StreetEasy do
  def fixture(name)
    File.read(Rails.root.join("spec/fixtures/html/#{name}"))
  end

  let(:html) { fixture("streeteasy_listing.html") }

  subject(:result) { described_class.new(html).call }

  describe "#call" do
    context "with a StreetEasy listing page" do
      it "extracts address from the building title" do
        expect(result[:address]).to eq("350 Fifth Ave, Apt 42B")
      end

      it "extracts price from JSON-LD" do
        expect(result[:price]).to eq(1_250_000)
      end

      it "extracts beds from the details section" do
        expect(result[:beds]).to eq(2)
      end

      it "extracts baths from the details section" do
        expect(result[:baths]).to eq(1)
      end

      it "extracts sqft from the details section" do
        expect(result[:sqft]).to eq(1200)
      end

      it "extracts description from the listing description" do
        expect(result[:description]).to include("Stunning Midtown co-op")
      end

      it "extracts carousel photo URLs" do
        expect(result[:photo_urls]).to eq([
          "https://images.streeteasy.com/photos/1.jpg",
          "https://images.streeteasy.com/photos/2.jpg",
          "https://images.streeteasy.com/photos/3.jpg"
        ])
      end

      it "extracts floor plan URLs" do
        expect(result[:floor_plan_urls]).to eq([
          "https://images.streeteasy.com/floorplan/42B.jpg"
        ])
      end
    end

    context "with missing details" do
      let(:html) do
        <<~HTML
          <!DOCTYPE html>
          <html>
          <head><title>Listing - StreetEasy</title></head>
          <body>
            <h1 class="building-title">100 Broadway, Unit 5A</h1>
          </body>
          </html>
        HTML
      end

      it "falls back to StructuredData for missing fields" do
        expect(result[:address]).to eq("100 Broadway, Unit 5A")
        expect(result[:price]).to be_nil
        expect(result[:beds]).to be_nil
        expect(result[:photo_urls]).to eq([])
      end
    end
  end
end
