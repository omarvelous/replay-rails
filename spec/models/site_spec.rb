require "rails_helper"

RSpec.describe Site, type: :model do
  subject(:site) { build(:site) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:account) }
  end
end
