require "rails_helper"

RSpec.describe QrHelper do
  let(:qr_code) { create(:qr_code) }

  describe "#qr_svg" do
    it "returns an SVG string" do
      svg = helper.qr_svg(qr_code)
      expect(svg).to include("<svg")
      expect(svg).to include("viewBox")
    end

    it "includes the scan path in the QR URL" do
      svg = helper.qr_svg(qr_code)
      expect(svg).to be_present
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
        svg = helper.qr_svg(qr_code)
        expect(svg).to include("<svg")
      end
    end

    it "appends ad and screen params when provided" do
      ad = create(:ad)
      account = qr_code.account
      site = create(:site, account: account)
      screen = create(:screen, site: site)

      svg = helper.qr_svg(qr_code, ad: ad, screen: screen)
      expect(svg).to include("<svg")
    end
  end
end
