require "rails_helper"

RSpec.describe Lead do
  subject(:lead) { build(:lead) }

  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:listing).optional }
    it { is_expected.to belong_to(:qr_scan).optional }
    it { is_expected.to have_many(:lead_agents).dependent(:destroy) }
    it { is_expected.to have_many(:agents).through(:lead_agents) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:account) }
    it { is_expected.to validate_inclusion_of(:lead_type).in_array(Lead::TYPES) }
    it { is_expected.to validate_inclusion_of(:status).in_array(Lead::STATUSES) }

    it "requires email when phone is blank" do
      lead = build(:lead, email: nil, phone: nil)
      expect(lead).not_to be_valid
      expect(lead.errors[:email]).to be_present
    end

    it "is valid with email and no phone" do
      lead = build(:lead, email: "test@example.com", phone: nil)
      expect(lead).to be_valid
    end

    it "is valid with phone and no email" do
      lead = build(:lead, email: nil, phone: "555-1234")
      expect(lead).to be_valid
    end
  end

  describe "scopes" do
    it ".unread returns leads with status new" do
      unread = create(:lead, status: "new")
      create(:lead, status: "contacted")
      expect(described_class.unread).to eq([ unread ])
    end

    it ".by_status filters by status" do
      contacted = create(:lead, status: "contacted")
      create(:lead, status: "new")
      expect(described_class.by_status("contacted")).to eq([ contacted ])
    end
  end

  describe "#current_agent" do
    it "returns the most recently assigned agent" do
      lead = create(:lead)
      account = lead.account
      agent_a = create(:agent, account: account)
      agent_b = create(:agent, account: account)

      lead.lead_agents.create!(agent: agent_a)
      lead.lead_agents.create!(agent: agent_b)

      expect(lead.current_agent).to eq(agent_b)
    end

    it "returns nil when no agents are assigned" do
      lead = create(:lead)
      expect(lead.current_agent).to be_nil
    end
  end

  describe "#listing" do
    it "returns the listing when set directly" do
      account = create(:account)
      listing = create(:listing, account: account)
      lead = create(:lead, account: account, listing: listing)

      expect(lead.listing).to eq(listing)
    end

    it "returns nil when no listing is set" do
      lead = create(:lead, listing: nil)
      expect(lead.listing).to be_nil
    end
  end

  describe "constants" do
    it "defines TYPES" do
      expect(Lead::TYPES).to include("buyer_inquiry", "general_inquiry")
    end

    it "defines STATUSES" do
      expect(Lead::STATUSES).to eq(%w[new contacted qualified closed])
    end
  end
end
