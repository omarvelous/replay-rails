require "rails_helper"

RSpec.describe "QrCodes" do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  it_behaves_like "tenant isolated resource", :qr_code, :qr_code_path

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
    it "shows the QR code with scan count from Ahoy events" do
      listing = create(:listing, account: account)
      qr = create(:qr_code, account: account, destination_record: listing, label: "Test QR")
      visit = create(:ahoy_visit)
      Ahoy::Event.create!(visit: visit, name: "qr.scanned", time: Time.current, properties: { "qr_code_id" => qr.id })

      get qr_code_path(qr)
      expect(response).to be_successful
      expect(response.body).to include("Test QR")
      expect(response.body).to include("1 scan")
    end

    it "returns 404 for another account's QR code" do
      other_qr = create(:qr_code)
      get qr_code_path(other_qr)
      expect(response).to have_http_status(:not_found)
    end
  end
end
