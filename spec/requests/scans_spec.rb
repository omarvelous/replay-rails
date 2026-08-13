require "rails_helper"

RSpec.describe "Scans", type: :request do
  describe "GET /s/:token" do
    let(:account) { create(:account) }
    let(:listing) { create(:listing, account: account) }
    let(:qr_code) { create(:qr_code, account: account, destination_record: listing) }

    it "records a scan and redirects to the destination" do
      expect {
        get qr_scan_path(token: qr_code.token)
      }.to change(QrScan, :count).by(1)
      expect(response).to redirect_to(go_listing_path(listing))
    end

    it "records source from params" do
      ad = create(:ad, account: account)
      get qr_scan_path(token: qr_code.token, src: "Ad.#{ad.id}")
      scan = QrScan.last
      expect(scan.source_type).to eq("Ad")
      expect(scan.source_id).to eq(ad.id)
    end

    it "allows scans with no source" do
      get qr_scan_path(token: qr_code.token)
      scan = QrScan.last
      expect(scan.source_type).to be_nil
    end

    it "records ip and user agent" do
      get qr_scan_path(token: qr_code.token)
      scan = QrScan.last
      expect(scan.ip_address).to be_present
      expect(scan.user_agent).to be_present
    end

    it "redirects to external URL when destination_url is set" do
      qr = create(:qr_code, account: account, destination_record: nil, destination_url: "https://example.com/tour")
      get qr_scan_path(token: qr.token)
      expect(response).to redirect_to("https://example.com/tour")
    end

    it "redirects to root when no destination" do
      qr = create(:qr_code, account: account, destination_record: nil, destination_url: nil)
      get qr_scan_path(token: qr.token)
      expect(response).to redirect_to(root_path)
    end

    it "returns 404 for inactive QR codes" do
      qr_code.update!(active: false)
      expect { get qr_scan_path(token: qr_code.token) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "returns 404 for unknown tokens" do
      expect { get qr_scan_path(token: "nonexistent") }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
