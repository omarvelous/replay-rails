require "rails_helper"

RSpec.describe PasswordsMailer do
  describe "#reset" do
    let(:user) { create(:user, email_address: "user@example.com") }

    it "sends to the user's email" do
      mail = described_class.reset(user)
      expect(mail.to).to eq([ "user@example.com" ])
    end

    it "has reset subject" do
      mail = described_class.reset(user)
      expect(mail.subject).to include("Reset your password")
    end

    it "includes a reset link in the body" do
      mail = described_class.reset(user)
      html = mail.html_part.body.decoded
      expect(html).to include("password")
    end

    it "includes a text part with reset link" do
      mail = described_class.reset(user)
      text = mail.text_part.body.decoded
      expect(text).to include("password")
      expect(text).to include("reset")
    end
  end
end
