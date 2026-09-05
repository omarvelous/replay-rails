require "rails_helper"

RSpec.describe "Inquiries" do
  before { host! "replay.localhost" }

  describe "POST /inquiries" do
    let(:valid_params) do
      { inquiry: { name: "Jane Doe", email: "jane@example.com", phone: "555-1234",
                   company: "ABC Realty", inquiry_type: "demo_request",
                   interest: "both", message: "Interested in a demo" } }
    end

    it "creates an inquiry and redirects with notice" do
      expect {
        post inquiries_path, params: valid_params
      }.to change(Inquiry, :count).by(1)

      expect(response).to redirect_to(demo_path)
      expect(flash[:notice]).to include("Thanks")
    end

    it "sends a notification email" do
      post inquiries_path, params: valid_params
      expect(ActionMailer::MailDeliveryJob).to have_been_enqueued
    end

    it "rejects blank name" do
      post inquiries_path, params: { inquiry: { name: "", email: "j@example.com", inquiry_type: "demo_request" } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects blank email" do
      post inquiries_path, params: { inquiry: { name: "Jane", email: "", inquiry_type: "demo_request" } }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects submissions with honeypot filled" do
      post inquiries_path, params: valid_params.merge(website: "http://spam.com")
      expect(Inquiry.count).to eq(0)
      expect(response).to redirect_to(demo_path)
    end
  end
end
