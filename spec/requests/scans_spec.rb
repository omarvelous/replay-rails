require "rails_helper"

RSpec.describe "Scans" do
  describe "GET /s/:token" do
    let(:account) { create(:account) }
    let(:listing) { create(:listing, account: account) }
    let(:site) { create(:site, account: account) }
    let(:screen) { create(:screen, site: site) }
    let(:ad) { create(:ad, account: account) }
    let(:qr_code) { create(:qr_code, account: account, destination_record: listing) }

    it "records a scan and redirects to the destination" do
      expect {
        get qr_scan_path(token: qr_code.token)
      }.to change(QrScan, :count).by(1)
      expect(response).to redirect_to(go_listing_url(listing, subdomain: ""))
    end

    it "records ad and screen from params" do
      get qr_scan_path(token: qr_code.token, a: ad.id, s: screen.id)
      scan = QrScan.last
      expect(scan.ad).to eq(ad)
      expect(scan.screen).to eq(screen)
    end

    it "records a qualified scan when both ad and screen present" do
      get qr_scan_path(token: qr_code.token, a: ad.id, s: screen.id)
      expect(QrScan.qualified.count).to eq(1)
    end

    it "records an unqualified scan when params are missing" do
      get qr_scan_path(token: qr_code.token)
      scan = QrScan.last
      expect(scan.ad).to be_nil
      expect(scan.screen).to be_nil
      expect(QrScan.unqualified.count).to eq(1)
    end

    it "records ip address" do
      get qr_scan_path(token: qr_code.token)
      expect(QrScan.last.ip_address).to be_present
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
