require "rails_helper"

RSpec.describe "Scans" do
  describe "GET /s/:token" do
    let(:account) { create(:account) }
    let(:listing) { create(:listing, account: account) }
    let(:site) { create(:site, account: account) }
    let(:screen) { create(:screen, site: site) }
    let(:ad) { create(:ad, account: account) }
    let(:qr_code) { create(:qr_code, account: account, destination_record: listing) }

    it "fires a qr.scanned Ahoy event and redirects to the destination" do
      get qr_scan_path(token: qr_code.token)

      event = Ahoy::Event.find_by(name: "qr.scanned")
      expect(event).to be_present
      expect(event.properties["qr_code_id"]).to eq(qr_code.id)
      expect(response).to redirect_to(go_listing_url(listing, subdomain: ""))
    end

    it "does not create a QrScan record" do
      expect {
        get qr_scan_path(token: qr_code.token)
      }.not_to change(QrScan, :count)
    end

    it "includes ad and screen in event properties" do
      get qr_scan_path(token: qr_code.token, a: ad.id, s: screen.id)
      event = Ahoy::Event.find_by(name: "qr.scanned")
      expect(event.properties["ad_id"]).to eq(ad.id)
      expect(event.properties["screen_id"]).to eq(screen.id)
    end

    it "includes screen_content_id in event properties" do
      get qr_scan_path(token: qr_code.token, sc: 42)
      event = Ahoy::Event.find_by(name: "qr.scanned")
      expect(event.properties["screen_content_id"]).to eq(42)
    end

    it "redirects to external URL when destination_url is set" do
      qr = create(:qr_code, account: account, destination_record: nil, destination_url: "https://example.com/tour")
      get qr_scan_path(token: qr.token)
      expect(response).to redirect_to("https://example.com/tour")
    end

    it "redirects to root when no destination" do
      qr = create(:qr_code, account: account, destination_record: nil, destination_url: nil)
      get qr_scan_path(token: qr.token)
      expect(response).to redirect_to(app_root_path)
    end

    it "returns 404 for inactive QR codes" do
      qr_code.update!(active: false)
      get qr_scan_path(token: qr_code.token)
      expect(response).to have_http_status(:not_found)
    end

    it "returns 404 for unknown tokens" do
      get qr_scan_path(token: "nonexistent")
      expect(response).to have_http_status(:not_found)
    end
  end
end
