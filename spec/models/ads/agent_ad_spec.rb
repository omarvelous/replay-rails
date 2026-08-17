require "rails_helper"

RSpec.describe Ads::AgentAd do
  subject(:agent_ad) { build(:agent_ad) }

  describe "associations" do
    it { is_expected.to belong_to(:agent) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:agent) }
  end

  describe "constants" do
    it "defines LAYOUTS" do
      expect(Ads::AgentAd::LAYOUTS).to eq(%w[profile split])
    end
  end

  describe "#default_headline" do
    it "returns the agent name" do
      agent = build(:agent, name: "Sarah Chen")
      agent_ad = build(:agent_ad, agent: agent)
      expect(agent_ad.default_headline).to eq("Sarah Chen")
    end
  end
end
