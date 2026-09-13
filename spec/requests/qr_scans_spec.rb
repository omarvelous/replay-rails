require "rails_helper"

RSpec.describe "QR Scan Events (nested under QrCode)" do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:qr_code) { create(:qr_code, account: account) }

  before { sign_in(user) }

  describe "GET /qr_codes/:qr_code_id/scans" do
    it "returns a successful response" do
      get qr_code_scans_path(qr_code)
      expect(response).to be_successful
    end

    it "lists scan events for the QR code" do
      visit = create(:ahoy_visit)
      Ahoy::Event.create!(visit: visit, name: "qr.scanned", time: Time.current,
        properties: { "qr_code_id" => qr_code.id, "ad_id" => 1, "screen_id" => 2 })

      get qr_code_scans_path(qr_code)
      expect(response).to be_successful
    end

    it "returns 404 for another account's QR code" do
      other_qr = create(:qr_code)
      get qr_code_scans_path(other_qr)
      expect(response).to have_http_status(:not_found)
    end
  end
end
