require "rails_helper"

RSpec.describe PublicIdentifiable do
  # Test with Listing as a concrete model that includes the concern
  subject(:record) { create(:listing) }

  describe "public_id generation" do
    it "generates a UUID public_id on create" do
      expect(record.public_id).to be_present
      expect(record.public_id).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
    end

    it "does not overwrite an existing public_id" do
      custom = SecureRandom.uuid
      listing = create(:listing, public_id: custom)
      expect(listing.public_id).to eq(custom)
    end

    it "generates unique public_ids" do
      other = create(:listing)
      expect(record.public_id).not_to eq(other.public_id)
    end
  end

  describe "validations" do
    it "validates uniqueness of public_id" do
      duplicate = build(:listing, public_id: record.public_id)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:public_id]).to include("has already been taken")
    end
  end

  describe "#to_param" do
    it "returns the public_id" do
      expect(record.to_param).to eq(record.public_id)
    end
  end

  describe ".find_by_param!" do
    it "finds a record by public_id" do
      found = Listing.find_by_param!(record.public_id)
      expect(found).to eq(record)
    end

    it "raises RecordNotFound for an invalid UUID" do
      expect {
        Listing.find_by_param!(SecureRandom.uuid)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises RecordNotFound for a non-UUID string" do
      expect {
        Listing.find_by_param!("not-a-uuid")
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
