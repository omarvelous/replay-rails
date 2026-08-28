require "rails_helper"

RSpec.describe VersionCleanupJob do
  describe "#perform" do
    it "deletes versions older than the retention period" do
      old_version = PaperTrail::Version.create!(
        item_type: "Listing", item_id: 1, event: "update",
        created_at: 91.days.ago
      )
      recent_version = PaperTrail::Version.create!(
        item_type: "Listing", item_id: 1, event: "update",
        created_at: 1.day.ago
      )

      described_class.new.perform(retention_days: 90)

      expect(PaperTrail::Version.exists?(old_version.id)).to be false
      expect(PaperTrail::Version.exists?(recent_version.id)).to be true
    end

    it "uses 90 days as default retention" do
      old_version = PaperTrail::Version.create!(
        item_type: "Listing", item_id: 1, event: "create",
        created_at: 100.days.ago
      )

      described_class.new.perform

      expect(PaperTrail::Version.exists?(old_version.id)).to be false
    end
  end
end
