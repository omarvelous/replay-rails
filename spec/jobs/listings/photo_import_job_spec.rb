require "rails_helper"

RSpec.describe Listings::PhotoImportJob do
  let(:listing) { create(:listing) }

  describe "#perform" do
    it "downloads and attaches photos from URLs" do
      photo_url = "https://example.com/photo.jpg"
      jpg_data = File.read(Rails.root.join("spec/fixtures/files/test.jpg"))

      stub_request_for(photo_url, body: jpg_data, content_type: "image/jpeg")

      described_class.perform_now(listing.id, [photo_url])
      listing.reload
      expect(listing.photos).to be_attached
      expect(listing.photos.count).to eq(1)
    end

    it "attaches multiple photos" do
      urls = ["https://example.com/1.jpg", "https://example.com/2.jpg"]
      jpg_data = File.read(Rails.root.join("spec/fixtures/files/test.jpg"))

      urls.each { |url| stub_request_for(url, body: jpg_data, content_type: "image/jpeg") }

      described_class.perform_now(listing.id, urls)
      listing.reload
      expect(listing.photos.count).to eq(2)
    end

    it "skips URLs that fail to download" do
      good_url = "https://example.com/good.jpg"
      bad_url = "https://example.com/bad.jpg"
      jpg_data = File.read(Rails.root.join("spec/fixtures/files/test.jpg"))

      stub_request_for(good_url, body: jpg_data, content_type: "image/jpeg")
      stub_request_for(bad_url, status: "404")

      described_class.perform_now(listing.id, [good_url, bad_url])
      listing.reload
      expect(listing.photos.count).to eq(1)
    end

    it "does nothing with empty URLs" do
      described_class.perform_now(listing.id, [])
      listing.reload
      expect(listing.photos).not_to be_attached
    end
  end

  private

  def stub_request_for(url, body: "", content_type: "image/jpeg", status: "200")
    uri = URI.parse(url)
    response = instance_double(Net::HTTPResponse, body: body, code: status, content_type: content_type)
    allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(status == "200")
    allow(Net::HTTP).to receive(:get_response).with(uri).and_return(response)
  end
end
