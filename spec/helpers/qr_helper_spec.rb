require "rails_helper"

RSpec.describe QrHelper do
  let(:qr_code) { create(:qr_code) }

  describe "#qr_scan_full_url" do
    it "includes the scan path with the token" do
      url = helper.qr_scan_full_url(qr_code)
      expect(url).to include("/s/#{qr_code.token}")
    end

    it "does not append query params" do
      url = helper.qr_scan_full_url(qr_code)
      expect(url).not_to include("?")
    end

    context "when QR_SHORT_DOMAIN is set" do
      around do |example|
        original = ENV["QR_SHORT_DOMAIN"]
        ENV["QR_SHORT_DOMAIN"] = "rply.tv"
        example.run
      ensure
        ENV["QR_SHORT_DOMAIN"] = original
      end

      it "uses the short domain with https and no port" do
        url = helper.qr_scan_full_url(qr_code)
        expect(url).to eq("https://rply.tv/s/#{qr_code.token}")
      end
    end

    context "when QR_SHORT_DOMAIN is not set" do
      it "falls back to the request host" do
        url = helper.qr_scan_full_url(qr_code)
        expect(url).to include("/s/#{qr_code.token}")
        expect(url).not_to include("rply.tv")
      end
    end
  end

  describe "#qr_svg" do
    it "returns an SVG string" do
      svg = helper.qr_svg(qr_code)
      expect(svg).to include("<svg")
      expect(svg).to include("viewBox")
    end
  end
end
