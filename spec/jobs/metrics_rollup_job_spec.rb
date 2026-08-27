require "rails_helper"

RSpec.describe MetricsRollupJob do
  let(:account) { create(:account) }
  let(:date) { Date.yesterday }
  let(:range) { date.beginning_of_day..date.end_of_day }

  describe "#perform" do
    it "creates impression snapshots grouped by account" do
      site = create(:site, account: account)
      screen = create(:screen, site: site)
      player = create(:player)
      screen.pair_player!(player)
      ad = create(:ad, account: account)

      create(:impression, ad: ad, screen: screen, player: player, site: site,
             account: account, created_at: date.beginning_of_day + 1.hour)

      described_class.new.perform(date)

      snapshot = MetricSnapshot.find_by(account: account, metric_name: "impressions")
      expect(snapshot).to be_present
      expect(snapshot.value).to eq(1)
      expect(snapshot.starts_at).to be_within(1.second).of(date.beginning_of_day)
      expect(snapshot.ends_at).to be_within(1.second).of(date.end_of_day)
    end

    it "creates scan snapshots grouped by account" do
      qr_code = create(:qr_code, account: account)
      create(:qr_scan, qr_code: qr_code, account: account,
             ad: create(:ad, account: account), screen: create(:screen),
             created_at: date.beginning_of_day + 2.hours)

      described_class.new.perform(date)

      snapshot = MetricSnapshot.find_by(account: account, metric_name: "scans")
      expect(snapshot).to be_present
      expect(snapshot.value).to eq(1)
    end

    it "creates lead snapshots grouped by account" do
      create(:lead, account: account, created_at: date.beginning_of_day + 3.hours)

      described_class.new.perform(date)

      snapshot = MetricSnapshot.find_by(account: account, metric_name: "leads")
      expect(snapshot).to be_present
      expect(snapshot.value).to eq(1)
    end

    it "skips accounts with no activity" do
      described_class.new.perform(date)

      expect(MetricSnapshot.where(account: account)).to be_empty
    end

    it "uses bulk insert — 6 queries total" do
      create(:lead, account: account, created_at: date.beginning_of_day + 1.hour)

      expect {
        described_class.new.perform(date)
      }.to change(MetricSnapshot, :count).by(1)
    end
  end
end
