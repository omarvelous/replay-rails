require "rails_helper"

RSpec.describe QrScan, type: :model do
  subject(:qr_scan) { build(:qr_scan) }

  describe "associations" do
    it { is_expected.to belong_to(:qr_code) }
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:source).optional }
  end

  describe "source attribution" do
    it "records a polymorphic source" do
      ad = create(:ad)
      scan = create(:qr_scan, source: ad)
      expect(scan.source).to eq(ad)
      expect(scan.source_type).to eq("Ad")
    end

    it "allows nil source for organic scans" do
      scan = create(:qr_scan, source: nil)
      expect(scan.source).to be_nil
    end
  end
end
