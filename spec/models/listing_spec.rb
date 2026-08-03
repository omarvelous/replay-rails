require "rails_helper"

RSpec.describe Listing, type: :model do
  subject(:listing) { build(:listing) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:address) }
    it { is_expected.to validate_presence_of(:price) }
    it { is_expected.to validate_numericality_of(:price).is_greater_than(0) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[active pending sold]) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:account) }
  end
end
