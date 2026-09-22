require "rails_helper"

RSpec.describe Listings::ImportService do
  def fixture(name)
    File.read(Rails.root.join("spec/fixtures/html/#{name}"))
  end

  def stub_fetch(url, body:, code: "200")
    uri = URI.parse(url)
    response = instance_double(Net::HTTPResponse, body: body, code: code)
    allow(response).to receive(:is_a?) do |klass|
      case klass.name
      when "Net::HTTPSuccess" then code == "200"
      when "Net::HTTPRedirection" then code.start_with?("3")
      else false
      end
    end

    http = instance_double(Net::HTTP)
    allow(http).to receive(:use_ssl=)
    allow(http).to receive(:open_timeout=)
    allow(http).to receive(:read_timeout=)
    allow(http).to receive(:request).and_return(response)
    allow(Net::HTTP).to receive(:new).with(uri.host, uri.port).and_return(http)
  end

  describe ".call" do
    context "with a StreetEasy URL" do
      let(:url) { "https://streeteasy.com/building/350-fifth-ave/42b" }

      before { stub_fetch(url, body: fixture("streeteasy_listing.html")) }

      it "uses the StreetEasy extractor" do
        result = described_class.call(url: url)
        expect(result[:address]).to eq("350 Fifth Ave, Apt 42B")
        expect(result[:source_url]).to eq(url)
      end

      it "returns floor_plan_urls from the StreetEasy extractor" do
        result = described_class.call(url: url)
        expect(result[:floor_plan_urls]).to include("https://images.streeteasy.com/floorplan/42B.jpg")
      end
    end

    context "with a generic listing URL" do
      let(:url) { "https://example.com/listing/456" }

      before { stub_fetch(url, body: fixture("listing_with_json_ld.html")) }

      it "uses the StructuredData extractor" do
        result = described_class.call(url: url)
        expect(result[:address]).to eq("456 Park Ave, Brooklyn, NY, 11217")
        expect(result[:source_url]).to eq(url)
      end
    end

    context "with an invalid URL" do
      it "raises an error for malformed URLs" do
        expect { described_class.call(url: "not a url") }
          .to raise_error(Listings::ImportService::InvalidUrlError)
      end
    end

    context "when the fetch fails" do
      let(:url) { "https://example.com/listing/gone" }

      before { stub_fetch(url, body: "", code: "404") }

      it "raises a fetch error" do
        expect { described_class.call(url: url) }
          .to raise_error(Listings::ImportService::FetchError)
      end
    end

    context "when no data is extracted" do
      let(:url) { "https://example.com/empty-page" }

      before { stub_fetch(url, body: "<html><body>No listing data here</body></html>") }

      it "returns a hash with nil values and the source_url" do
        result = described_class.call(url: url)
        expect(result[:address]).to be_nil
        expect(result[:price]).to be_nil
        expect(result[:source_url]).to eq(url)
      end
    end
  end

  describe ".call_with_html" do
    it "parses pasted HTML with StructuredData extractor" do
      result = described_class.call_with_html(html: fixture("listing_with_json_ld.html"))
      expect(result[:address]).to eq("456 Park Ave, Brooklyn, NY, 11217")
      expect(result[:price]).to eq(2_450_000)
      expect(result[:source_url]).to be_nil
    end

    it "selects StreetEasy extractor when URL matches" do
      result = described_class.call_with_html(
        html: fixture("streeteasy_listing.html"),
        url: "https://streeteasy.com/building/test/1a"
      )
      expect(result[:address]).to eq("350 Fifth Ave, Apt 42B")
      expect(result[:source_url]).to eq("https://streeteasy.com/building/test/1a")
    end

    it "falls back to StructuredData for unknown URLs" do
      result = described_class.call_with_html(
        html: fixture("listing_with_json_ld.html"),
        url: "https://example.com/listing/123"
      )
      expect(result[:address]).to eq("456 Park Ave, Brooklyn, NY, 11217")
    end
  end
end
