require "rails_helper"

RSpec.describe ScreenPlayer do
  describe "associations" do
    it { is_expected.to belong_to(:screen) }
    it { is_expected.to belong_to(:player) }
    it { is_expected.to belong_to(:paired_by).optional }
  end

  describe "scopes" do
    it ".active returns only active pairings" do
      active = create(:screen_player, active: true)
      create(:screen_player, active: false)
      expect(described_class.active).to eq([ active ])
    end

    it ".history returns only inactive pairings" do
      create(:screen_player, active: true)
      inactive = create(:screen_player, active: false)
      expect(described_class.history).to eq([ inactive ])
    end
  end

  describe "#unpair!" do
    it "deactivates the pairing and sets unpaired_at" do
      sp = create(:screen_player)
      sp.unpair!
      expect(sp.active).to be false
      expect(sp.unpaired_at).to be_present
    end
  end
end
