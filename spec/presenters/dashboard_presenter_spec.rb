require "rails_helper"

RSpec.describe DashboardPresenter do
  let(:account) { create(:account) }
  let(:site) { create(:site, account: account) }
  let(:presenter) { described_class.new(account: account) }

  describe "#screens_total" do
    it "counts screens for the account" do
      create_list(:screen, 3, site: site)
      expect(presenter.screens_total).to eq(3)
    end
  end

  describe "#screens_online" do
    it "counts screens with recent heartbeats" do
      online_screen = create(:screen, site: site)
      offline_screen = create(:screen, site: site)
      no_player_screen = create(:screen, site: site)

      online_player = create(:player, last_heartbeat_at: 1.minute.ago)
      offline_player = create(:player, last_heartbeat_at: 5.minutes.ago)

      pair_player!(online_screen, online_player)
      pair_player!(offline_screen, offline_player)

      expect(presenter.screens_online).to eq(1)
    end
  end

  describe "#impressions_month" do
    it "counts content.impressed events for the account" do
      visit = create(:ahoy_visit)
      Ahoy::Event.create!(visit: visit, name: "content.impressed", time: 1.day.ago, properties: { "account_pid" => account.public_id })
      Ahoy::Event.create!(visit: visit, name: "content.impressed", time: 1.day.ago, properties: { "account_pid" => account.public_id })
      Ahoy::Event.create!(visit: visit, name: "qr.scanned", time: 1.day.ago, properties: { "account_pid" => account.public_id })

      expect(presenter.impressions_month).to eq(2)
    end

    it "excludes events older than the period" do
      visit = create(:ahoy_visit)
      Ahoy::Event.create!(visit: visit, name: "content.impressed", time: 31.days.ago, properties: { "account_pid" => account.public_id })

      expect(presenter.impressions_month).to eq(0)
    end
  end

  describe "#scans_month" do
    it "counts qr.scanned events for the account" do
      visit = create(:ahoy_visit)
      Ahoy::Event.create!(visit: visit, name: "qr.scanned", time: 1.day.ago, properties: { "account_pid" => account.public_id })

      expect(presenter.scans_month).to eq(1)
    end
  end

  describe "#leads_month" do
    it "counts leads created within the period" do
      create(:lead, account: account, created_at: 1.day.ago)
      create(:lead, account: account, created_at: 31.days.ago)

      expect(presenter.leads_month).to eq(1)
    end
  end

  describe "#leads_unread" do
    it "counts unread leads" do
      create(:lead, account: account, status: "new")
      create(:lead, account: account, status: "contacted")

      expect(presenter.leads_unread).to eq(1)
    end
  end

  describe "#recent_leads" do
    it "returns the 5 most recent leads" do
      create_list(:lead, 7, account: account)

      expect(presenter.recent_leads.size).to eq(5)
      expect(presenter.recent_leads).to eq(account.leads.order(created_at: :desc).limit(5))
    end
  end

  describe "#chart_impressions" do
    it "returns impressions grouped by day" do
      visit = create(:ahoy_visit)
      Ahoy::Event.create!(visit: visit, name: "content.impressed", time: Date.yesterday.noon, properties: { "account_pid" => account.public_id })
      Ahoy::Event.create!(visit: visit, name: "content.impressed", time: Date.yesterday.noon, properties: { "account_pid" => account.public_id })
      Ahoy::Event.create!(visit: visit, name: "content.impressed", time: Date.current.noon, properties: { "account_pid" => account.public_id })

      result = presenter.chart_impressions
      expect(result[Date.yesterday]).to eq(2)
      expect(result[Date.current]).to eq(1)
    end
  end

  describe "#chart_leads" do
    it "returns leads grouped by day" do
      create(:lead, account: account, created_at: Date.yesterday.noon)
      create(:lead, account: account, created_at: Date.current.noon)

      result = presenter.chart_leads
      expect(result[Date.yesterday]).to eq(1)
      expect(result[Date.current]).to eq(1)
    end
  end

  describe "custom period" do
    it "respects the configured period" do
      short = described_class.new(account: account, period: 7.days)
      create(:lead, account: account, created_at: 5.days.ago)
      create(:lead, account: account, created_at: 10.days.ago)

      expect(short.leads_month).to eq(1)
    end
  end
end
