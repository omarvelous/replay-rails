require "rails_helper"

RSpec.describe Inquiry do
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_inclusion_of(:inquiry_type).in_array(Inquiry::TYPES) }
  end

  describe "constants" do
    it "defines TYPES" do
      expect(Inquiry::TYPES).to include("demo_request", "general")
    end
  end
end
