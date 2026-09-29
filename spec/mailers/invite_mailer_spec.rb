require "rails_helper"

RSpec.describe InviteMailer do
  describe "#invite" do
    let(:account) { create(:account) }
    let(:inviter) { create(:user, account: account) }
    let(:invite) { create(:invite, account: account, invited_by: inviter, email: "newagent@example.com", role: "agent") }

    it "sends to the invite email" do
      mail = described_class.invite(invite)
      expect(mail.to).to eq([ "newagent@example.com" ])
    end

    it "has the correct subject" do
      mail = described_class.invite(invite)
      expect(mail.subject).to include("invited")
    end

    it "includes the accept URL with token" do
      mail = described_class.invite(invite)
      html = mail.html_part.body.decoded
      expect(html).to include(invite.token)
    end

    it "includes a text part" do
      mail = described_class.invite(invite)
      text = mail.text_part.body.decoded
      expect(text).to include("invited")
      expect(text).to include(invite.token)
    end
  end

  describe "#accepted" do
    let(:account) { create(:account) }
    let(:inviter) { create(:user, account: account) }
    let(:invitee) { create(:user) }
    let(:invite) { create(:invite, account: account, invited_by: inviter, email: invitee.email_address, role: "agent") }

    before { invite.update!(accepted_at: Time.current) }

    it "sends to the inviter" do
      mail = described_class.accepted(invite)
      expect(mail.to).to eq([ inviter.email_address ])
    end

    it "has the correct subject" do
      mail = described_class.accepted(invite)
      expect(mail.subject).to include("accepted")
    end

    it "includes the invitee name in HTML" do
      mail = described_class.accepted(invite)
      html = mail.html_part.body.decoded
      expect(html).to include(invite.email)
    end

    it "includes a text part" do
      mail = described_class.accepted(invite)
      text = mail.text_part.body.decoded
      expect(text).to include("accepted")
      expect(text).to include(invite.email)
    end
  end
end
