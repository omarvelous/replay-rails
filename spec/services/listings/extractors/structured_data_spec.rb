require "rails_helper"

RSpec.describe Listings::Extractors::StructuredData do
  def fixture(name)
    File.read(Rails.root.join("spec/fixtures/html/#{name}"))
  end

  describe "#call" do
    context "with JSON-LD structured data" do
      let(:result) { described_class.new(fixture("listing_with_json_ld.html")).call }

      it "extracts address" do
        expect(result[:address]).to include("456 Park Ave")
      end

      it "extracts price" do
        expect(result[:price]).to eq(2_450_000)
      end

      it "extracts beds" do
        expect(result[:beds]).to eq(3)
      end

      it "extracts baths" do
        expect(result[:baths]).to eq(2)
      end

      it "extracts sqft" do
        expect(result[:sqft]).to eq(1800)
      end

      it "extracts description" do
        expect(result[:description]).to include("Sun-filled brownstone")
      end

      it "extracts photo URLs" do
        expect(result[:photo_urls]).to include("https://example.com/photos/1.jpg")
        expect(result[:photo_urls].size).to eq(3)
      end
    end

    context "with OG tags only (no JSON-LD)" do
      let(:result) { described_class.new(fixture("listing_with_og_only.html")).call }

      it "extracts description from og:description" do
        expect(result[:description]).to include("Stunning 2-bedroom")
      end

      it "extracts all og:image photos" do
        expect(result[:photo_urls]).to eq([
          "https://example.com/photos/og-main.jpg",
          "https://example.com/photos/og-2.jpg",
          "https://example.com/photos/og-3.jpg"
        ])
      end
    end

    context "with empty HTML" do
      let(:result) { described_class.new("<html><body></body></html>").call }

      it "returns a hash with nil values" do
        expect(result[:address]).to be_nil
        expect(result[:price]).to be_nil
        expect(result[:photo_urls]).to eq([])
      end
    end
  end
end
