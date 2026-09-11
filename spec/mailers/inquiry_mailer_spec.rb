require "rails_helper"

RSpec.describe InquiryMailer do
  describe "#notification" do
    let(:inquiry) { create(:inquiry, name: "Jane Doe", email: "jane@example.com", inquiry_type: "demo_request", company: "ABC Realty", message: "Interested in a demo") }

    it "sends to hello@replaytv.co" do
      mail = described_class.notification(inquiry)
      expect(mail.to).to eq([ "hello@replaytv.co" ])
    end

    it "includes inquiry type and name in subject" do
      mail = described_class.notification(inquiry)
      expect(mail.subject).to include("Demo request")
      expect(mail.subject).to include("Jane Doe")
    end

    it "includes inquiry details in the body" do
      mail = described_class.notification(inquiry)
      body = mail.body.encoded
      expect(body).to include("Jane Doe")
      expect(body).to include("jane@example.com")
      expect(body).to include("ABC Realty")
      expect(body).to include("Interested in a demo")
    end

    it "works with general inquiry type" do
      inquiry.update!(inquiry_type: "general")
      mail = described_class.notification(inquiry)
      expect(mail.subject).to include("General")
    end
  end
end
