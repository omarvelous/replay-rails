require "rails_helper"

RSpec.describe "QrCodes" do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  before { sign_in(user) }

  describe "GET /qr_codes" do
    it "returns a successful response" do
      get qr_codes_path
      expect(response).to be_successful
    end

    it "lists QR codes for the current account" do
      listing = create(:listing, account: account, address: "350 Fifth Ave")
      qr = create(:qr_code, account: account, destination_record: listing, label: "Fifth Ave QR")
      other_qr = create(:qr_code, label: "Other account QR")

      get qr_codes_path
      expect(response.body).to include("Fifth Ave QR")
      expect(response.body).not_to include("Other account QR")
    end
  end

  describe "GET /qr_codes/:id" do
    it "shows the QR code with scan history" do
      listing = create(:listing, account: account)
      qr = create(:qr_code, account: account, destination_record: listing, label: "Test QR")
      create(:qr_scan, qr_code: qr, account: account)

      get qr_code_path(qr)
      expect(response).to be_successful
      expect(response.body).to include("Test QR")
    end

    it "returns 404 for another account's QR code" do
      other_qr = create(:qr_code)
      get qr_code_path(other_qr)
      expect(response).to have_http_status(:not_found)
    end
  end
end
