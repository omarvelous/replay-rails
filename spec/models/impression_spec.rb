require "rails_helper"

RSpec.describe Impression do
  describe "associations" do
    it { is_expected.to belong_to(:ad) }
    it { is_expected.to belong_to(:screen) }
    it { is_expected.to belong_to(:player) }
    it { is_expected.to belong_to(:site) }
    it { is_expected.to belong_to(:playlist).optional }
    it { is_expected.to belong_to(:account) }
  end
end
