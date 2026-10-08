require "rails_helper"

RSpec.describe AdsHelper do
  describe "#ad_theme_style" do
    it "returns empty string for dark theme" do
      expect(helper.ad_theme_style("dark")).to eq("")
    end

    it "returns CSS overrides for light theme" do
      result = helper.ad_theme_style("light")
      expect(result).to include("--ad-bg: #f9fafb")
      expect(result).to include("--ad-text: #111827")
    end

    it "resolves accent placeholder for brand theme" do
      result = helper.ad_theme_style("brand", accent: "#ff0000")
      expect(result).to include("--ad-bg: #ff0000")
    end

    it "uses default accent when not specified" do
      result = helper.ad_theme_style("brand")
      expect(result).to include("--ad-bg: #2f6bff")
    end
  end

  describe "#ad_preview_iframe_url" do
    it "returns iframe URL with base64-encoded ad data" do
      ad = create(:ad)
      url = helper.ad_preview_iframe_url(ad)
      expect(url).to start_with("http://play.replay.localhost:3100/preview.html#")
    end
  end

  describe "#edit_typed_ad_path" do
    it "returns the typed edit path for a listing ad" do
      ad = create(:ad)
      expect(helper.edit_typed_ad_path(ad)).to eq(edit_ads_listing_ad_path(ad))
    end

    it "falls back to generic edit path when typed route is missing" do
      ad = create(:ad)
      allow(helper).to receive(:respond_to?).and_call_original
      allow(helper).to receive(:respond_to?).with("edit_ads_listing_ad_path", true).and_return(false)
      expect(helper.edit_typed_ad_path(ad)).to eq(edit_ad_path(ad))
    end
  end
end
