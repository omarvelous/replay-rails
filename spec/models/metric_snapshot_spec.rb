require "rails_helper"

RSpec.describe MetricSnapshot do
  describe "associations" do
    it { is_expected.to belong_to(:account) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:metric_name) }
    it { is_expected.to validate_presence_of(:value) }
    it { is_expected.to validate_presence_of(:starts_at) }
    it { is_expected.to validate_presence_of(:ends_at) }
  end
end
