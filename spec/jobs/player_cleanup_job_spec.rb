require "rails_helper"

RSpec.describe PlayerCleanupJob do
  describe "#perform" do
    it "deletes players never paired after 24 hours" do
      stale = create(:player, created_at: 25.hours.ago)
      recent = create(:player, created_at: 1.hour.ago)

      described_class.new.perform

      expect(Player.exists?(stale.id)).to be false
      expect(Player.exists?(recent.id)).to be true
    end

    it "does not delete players that have been paired" do
      paired = create(:player, created_at: 25.hours.ago)
      screen = create(:screen)
      screen.pair_player!(paired)
      screen.unpair_player!

      described_class.new.perform

      expect(Player.exists?(paired.id)).to be true
    end

    it "uses 24 hours as default retention" do
      stale = create(:player, created_at: 30.hours.ago)

      described_class.new.perform

      expect(Player.exists?(stale.id)).to be false
    end
  end
end
