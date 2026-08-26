require "rails_helper"

RSpec.describe Playlist do
  subject(:playlist) { build(:playlist) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[draft published archived]) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_many(:playlist_ads).dependent(:destroy) }
    it { is_expected.to have_many(:ads).through(:playlist_ads) }
  end

  describe "scopes" do
    describe ".search" do
      it "searches by name case-insensitively" do
        match = create(:playlist, name: "Evening Showcase")
        create(:playlist, name: "Morning Loop")
        expect(described_class.search("evening")).to eq([ match ])
      end
    end

    describe ".by_status" do
      it "filters by status" do
        published = create(:playlist, status: "published")
        create(:playlist, status: "draft")
        expect(described_class.by_status("published")).to eq([ published ])
      end
    end
  end
end
