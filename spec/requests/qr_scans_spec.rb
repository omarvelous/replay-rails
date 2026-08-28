require "rails_helper"

RSpec.describe "QrScans (nested under QrCode)" do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:qr_code) { create(:qr_code, account: account) }

  before { sign_in(user) }

  describe "GET /qr_codes/:qr_code_id/scans" do
    it "returns a successful response" do
      get qr_code_scans_path(qr_code)
      expect(response).to be_successful
    end

    it "lists scans for the QR code" do
      scan = create(:qr_scan, qr_code: qr_code, account: account)
      other_qr = create(:qr_code, account: account)
      other_scan = create(:qr_scan, qr_code: other_qr, account: account)

      get qr_code_scans_path(qr_code)
      expect(response.body).to include(scan.ip_address)
    end

    it "returns 404 for another account's QR code" do
      other_qr = create(:qr_code)
      get qr_code_scans_path(other_qr)
      expect(response).to have_http_status(:not_found)
    end
  end
end
