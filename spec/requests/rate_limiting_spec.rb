require "rails_helper"

RSpec.describe "Rate limiting" do
  before do
    Rack::Attack.enabled = true
    Rack::Attack.reset!
  end

  after do
    Rack::Attack.enabled = false
  end

  describe "lead form throttling" do
    let(:account) { create(:account) }
    let(:listing) { create(:listing, account: account) }

    before { host! "replay.localhost" }

    it "allows requests under the limit" do
      3.times do
        post go_leads_path, params: {
          lead: { name: "Test", email: "t@example.com",
                  lead_type: "general_inquiry", listing_id: listing.id }
        }
      end
      expect(response).not_to have_http_status(:too_many_requests)
    end

    it "returns 429 when limit is exceeded" do
      11.times do
        post go_leads_path, params: {
          lead: { name: "Test", email: "t@example.com",
                  lead_type: "general_inquiry", listing_id: listing.id }
        }
      end
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "login throttling" do
    it "returns 429 after too many login attempts per IP" do
      11.times do
        post session_path, params: {
          email_address: "test@example.com",
          password: "wrong"
        }
      end
      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "signup throttling" do
    it "returns 429 after too many signup attempts" do
      6.times do |i|
        post accounts_path, params: {
          account: {},
          user: { first_name: "Test", last_name: "User",
                  email_address: "test#{i}@example.com",
                  phone: "+12125550001", password: "password123",
                  password_confirmation: "password123" }
        }
      end
      expect(response).to have_http_status(:too_many_requests)
    end
  end
end
