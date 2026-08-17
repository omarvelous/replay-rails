require "rails_helper"

RSpec.describe Ads::CollectionAdAd, type: :model do
  subject(:collection_ad_ad) { build(:collection_ad_ad) }

  describe "associations" do
    it { is_expected.to belong_to(:collection_ad) }
    it { is_expected.to belong_to(:ad) }
  end
end
