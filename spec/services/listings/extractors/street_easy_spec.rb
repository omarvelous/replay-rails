require "rails_helper"

RSpec.describe Listings::Extractors::StreetEasy do
  def fixture(name)
    File.read(Rails.root.join("spec/fixtures/html/#{name}"))
  end

  subject(:result) { described_class.new(html).call }

  let(:html) { fixture("streeteasy_listing.html") }

  describe "#call" do
    context "with a StreetEasy listing page" do
      it "extracts address from JSON-LD mainEntity" do
        expect(result[:address]).to eq("60 Cedar Street #15G, Brooklyn, NY, 11221")
      end

      it "extracts price from JSON-LD offers" do
        expect(result[:price]).to eq(4850)
      end

      it "extracts beds from description text" do
        expect(result[:beds]).to eq(2)
      end

      it "extracts baths from description text" do
        expect(result[:baths]).to eq(1)
      end

      it "extracts sqft from description text" do
        expect(result[:sqft]).to eq(950)
      end

      it "extracts description from JSON-LD" do
        expect(result[:description]).to include("Spacious 2 bedroom")
      end

      it "extracts photo URLs from og:image tags" do
        expect(result[:photo_urls]).to eq([
          "https://photos.zillowstatic.com/fp/abc123-full.webp",
          "https://photos.zillowstatic.com/fp/def456-full.webp",
          "https://photos.zillowstatic.com/fp/ghi789-full.webp"
        ])
      end

      it "extracts property type from mainEntity @type" do
        expect(result[:property_type]).to eq("apartment")
      end

      it "detects rental listing type from additionalProperty" do
        expect(result[:listing_type]).to eq("for_rent")
      end
    end

    context "with minimal HTML" do
      let(:html) do
        <<~HTML
          <!DOCTYPE html>
          <html>
          <head>
            <meta property="og:title" content="100 Broadway #5A in Tribeca, Manhattan | StreetEasy" />
          </head>
          <body></body>
          </html>
        HTML
      end

      it "falls back to og:title for address" do
        expect(result[:address]).to eq("100 Broadway #5A")
      end

      it "returns nil for missing fields" do
        expect(result[:price]).to be_nil
        expect(result[:beds]).to be_nil
        expect(result[:photo_urls]).to eq([])
      end
    end

    context "with real StreetEasy HTML" do
      let(:cedar_tower) { "tmp/streeteasy.com/building/the-cedar-tower/15g.html" }
      let(:melrose) { "tmp/streeteasy.com/building/123-melrose-street-brooklyn/677.html" }

      it "parses Cedar Tower listing", if: File.exist?(Rails.root.join("tmp/streeteasy.com/building/the-cedar-tower/15g.html")) do
        result = described_class.new(File.read(Rails.root.join(cedar_tower))).call
        expect(result[:address]).to include("60 Cedar Street")
        expect(result[:price]).to eq(4850)
        expect(result[:description]).to be_present
        expect(result[:photo_urls].size).to be >= 10
        expect(result[:property_type]).to eq("apartment")
        expect(result[:listing_type]).to eq("for_rent")
      end

      it "parses Melrose Street listing", if: File.exist?(Rails.root.join("tmp/streeteasy.com/building/123-melrose-street-brooklyn/677.html")) do
        result = described_class.new(File.read(Rails.root.join(melrose))).call
        expect(result[:address]).to include("123 Melrose Street")
        expect(result[:price]).to eq(4950)
        expect(result[:description]).to be_present
        expect(result[:photo_urls].size).to be >= 10
        expect(result[:property_type]).to eq("apartment")
      end
    end
  end
end
