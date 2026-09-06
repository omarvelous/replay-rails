require "rails_helper"

RSpec.describe "Redirect tracking", type: :request do
  let(:account) { create(:account) }
  let(:listing) { create(:listing, account: account) }
  let(:qr_code) { create(:qr_code, account: account, destination_record: listing) }

  before { host! "replay.localhost" }

  it "redirects to the listing go page on QR scan" do
    get "/s/#{qr_code.token}"
    expect(response).to have_http_status(:redirect)
    expect(response.location).to include("/go/listings/")
  end
end
