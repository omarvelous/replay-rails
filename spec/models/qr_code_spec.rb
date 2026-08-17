require "rails_helper"

RSpec.describe QrCode, type: :model do
  subject(:qr_code) { build(:qr_code) }

  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:destination_record).optional }
    it { is_expected.to have_many(:scans).class_name("QrScan").dependent(:destroy) }
  end

  describe "validations" do
    it "validates token uniqueness" do
      create(:qr_code)
      expect(subject).to validate_uniqueness_of(:token)
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
