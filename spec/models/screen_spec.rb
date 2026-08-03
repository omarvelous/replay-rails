require "rails_helper"

RSpec.describe Screen, type: :model do
  subject(:screen) { build(:screen) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_inclusion_of(:orientation).in_array(%w[landscape portrait]) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:site) }
  end
end
