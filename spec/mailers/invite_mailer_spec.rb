require "rails_helper"

RSpec.describe InviteMailer do
  describe "#invite" do
    let(:account) { create(:account) }
    let(:inviter) { create(:user, account: account) }
    let(:invite) { create(:invite, account: account, invited_by: inviter, email: "newagent@example.com", role: "agent") }

    it "sends to the invite email" do
      mail = described_class.invite(invite)
      expect(mail.to).to eq(["newagent@example.com"])
    end

    it "has the correct subject" do
      mail = described_class.invite(invite)
      expect(mail.subject).to include("invited")
    end

    it "includes the accept URL with token" do
      mail = described_class.invite(invite)
      body = mail.body.encoded
      expect(body).to include(invite.token)
    end
  end
end
