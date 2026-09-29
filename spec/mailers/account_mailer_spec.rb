require "rails_helper"

RSpec.describe AccountMailer do
  describe "#welcome" do
    let(:account) { create(:account) }
    let(:user) { create(:user, account: account) }

    it "sends to the user's email" do
      mail = described_class.welcome(user, account)
      expect(mail.to).to eq([ user.email_address ])
    end

    it "has the correct subject" do
      mail = described_class.welcome(user, account)
      expect(mail.subject).to include("Welcome")
    end

    it "includes onboarding steps in HTML" do
      mail = described_class.welcome(user, account)
      html = mail.html_part.body.decoded
      expect(html).to include("Add a listing")
      expect(html).to include("Create an ad")
      expect(html).to include("Set up a screen")
    end

    it "includes a text part" do
      mail = described_class.welcome(user, account)
      text = mail.text_part.body.decoded
      expect(text).to include("Welcome")
      expect(text).to include("listing")
    end
  end
end
