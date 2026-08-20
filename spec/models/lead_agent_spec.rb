require "rails_helper"

RSpec.describe LeadAgent do
  subject(:lead_agent) { build(:lead_agent) }

  describe "associations" do
    it { is_expected.to belong_to(:lead) }
    it { is_expected.to belong_to(:agent) }
  end
end
