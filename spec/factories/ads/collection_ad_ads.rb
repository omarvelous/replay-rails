FactoryBot.define do
  factory :collection_ad_ad, class: "Ads::CollectionAdAd" do
    association :collection_ad
    association :ad
    position { 0 }
  end
end
