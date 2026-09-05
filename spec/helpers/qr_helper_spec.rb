require "rails_helper"

RSpec.describe QrHelper do
  let(:qr_code) { create(:qr_code) }

  describe "#qr_scan_full_url" do
    it "includes the scan path with the token" do
      url = helper.qr_scan_full_url(qr_code)
      expect(url).to include("/s/#{qr_code.token}")
    end

    it "appends ad and screen params" do
      ad = create(:ad)
      site = create(:site, account: qr_code.account)
      screen = create(:screen, site: site)

      url = helper.qr_scan_full_url(qr_code, ad: ad, screen: screen)
      expect(url).to include("a=#{ad.id}")
      expect(url).to include("s=#{screen.id}")
    end

    context "when QR_BASE_URL is set" do
      around do |example|
        original = ENV["QR_BASE_URL"]
        ENV["QR_BASE_URL"] = "https://rply.tv"
        example.run
      ensure
        ENV["QR_BASE_URL"] = original
      end

      it "uses the custom base URL" do
        url = helper.qr_scan_full_url(qr_code)
        expect(url).to start_with("https://rply.tv/s/")
      end
    end

    context "when QR_BASE_URL is not set" do
      it "falls back to the default host" do
        url = helper.qr_scan_full_url(qr_code)
        expect(url).to include("/s/#{qr_code.token}")
        expect(url).not_to start_with("https://rply.tv")
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
