require "rails_helper"

RSpec.describe AdminAccountUser do
  subject(:admin_account_user) { described_class.new }

  describe "#role" do
    it "returns owner" do
      expect(admin_account_user.role).to eq("owner")
    end
  end

  describe "#at_least?" do
    it "returns true for any role" do
      expect(admin_account_user.at_least?("agent")).to be true
      expect(admin_account_user.at_least?("manager")).to be true
      expect(admin_account_user.at_least?("owner")).to be true
    end
  end
end
