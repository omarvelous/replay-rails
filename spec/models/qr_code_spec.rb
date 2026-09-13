require "rails_helper"

RSpec.describe QrCode do
  subject(:qr_code) { build(:qr_code) }

  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:destination_record).optional }
    it { is_expected.to have_many(:scans).class_name("QrScan").dependent(:destroy) }
  end

  describe "validations" do
    it "validates token uniqueness" do
      create(:qr_code)
      expect(qr_code).to validate_uniqueness_of(:token)
    end
  end

  describe "token generation" do
    it "generates a token before create" do
      qr = build(:qr_code)
      qr.token = nil
      qr.save!
      expect(qr.token).to be_present
    end

    it "does not overwrite an existing token" do
      qr = build(:qr_code, token: "custom-token")
      qr.save!
      expect(qr.token).to eq("custom-token")
    end
  end

  describe "#scan_events" do
    it "returns qr.scanned Ahoy events for this QR code" do
      qr = create(:qr_code)
      visit = create(:ahoy_visit)
      matching = Ahoy::Event.create!(visit: visit, name: "qr.scanned", time: Time.current, properties: { "qr_code_id" => qr.id })
      Ahoy::Event.create!(visit: visit, name: "qr.scanned", time: Time.current, properties: { "qr_code_id" => 9999 })

      expect(qr.scan_events).to eq([ matching ])
    end
  end

  describe "#scan_count" do
    it "returns count of qr.scanned events" do
      qr = create(:qr_code)
      visit = create(:ahoy_visit)
      2.times { Ahoy::Event.create!(visit: visit, name: "qr.scanned", time: Time.current, properties: { "qr_code_id" => qr.id }) }

      expect(qr.scan_count).to eq(2)
    end
  end

  describe "#qualified_scan_events" do
    it "returns scan events with both ad_id and screen_id" do
      qr = create(:qr_code)
      visit = create(:ahoy_visit)
      qualified = Ahoy::Event.create!(visit: visit, name: "qr.scanned", time: Time.current, properties: { "qr_code_id" => qr.id, "ad_id" => 1, "screen_id" => 2 })
      Ahoy::Event.create!(visit: visit, name: "qr.scanned", time: Time.current, properties: { "qr_code_id" => qr.id, "ad_id" => 1 })
      Ahoy::Event.create!(visit: visit, name: "qr.scanned", time: Time.current, properties: { "qr_code_id" => qr.id })

      expect(qr.qualified_scan_events).to eq([ qualified ])
    end
  end

  describe "#destination?" do
    it "returns true when destination_record is present" do
      qr = build(:qr_code, destination_record: build(:listing))
      expect(qr.destination?).to be true
    end

    it "returns true when destination_url is present" do
      qr = build(:qr_code, destination_record: nil, destination_url: "https://example.com")
      expect(qr.destination?).to be true
    end

    it "returns false when neither is present" do
      qr = build(:qr_code, destination_record: nil, destination_url: nil)
      expect(qr.destination?).to be false
    end
  end
end
