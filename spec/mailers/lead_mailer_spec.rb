require "rails_helper"

RSpec.describe LeadMailer do
  describe "#new_lead" do
    let(:account) { create(:account) }
    let(:user) { create(:user, account: account) }
    let(:agent) { create(:agent, account: account, email: "agent@example.com") }
    let(:lead) { create(:lead, account: account, name: "Jane Doe", email: "jane@example.com", message: "I would like a viewing") }

    before { lead.lead_agents.create!(agent: agent) }

    it "sends to the current agent" do
      mail = described_class.new_lead(lead)
      expect(mail.to).to eq([ "agent@example.com" ])
    end

    it "falls back to account owner when no agent assigned" do
      user # ensure user exists
      lead_without_agent = create(:lead, account: account, name: "No Agent Lead", email: "noagent@example.com")
      mail = described_class.new_lead(lead_without_agent)
      expect(mail.to).to eq([ user.email_address ])
    end

    it "sets a relevant subject" do
      mail = described_class.new_lead(lead)
      expect(mail.subject).to include("New inquiry")
    end

    it "includes the lead name in the body" do
      mail = described_class.new_lead(lead)
      expect(mail.body.encoded).to include("Jane Doe")
    end

    it "includes the message in the body" do
      mail = described_class.new_lead(lead)
      expect(mail.body.encoded).to include("I would like a viewing")
    end

    it "includes a mailto link" do
      mail = described_class.new_lead(lead)
      expect(mail.body.encoded).to include("mailto:jane@example.com")
    end
  end
end
