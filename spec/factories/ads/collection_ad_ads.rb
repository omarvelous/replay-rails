FactoryBot.define do
  factory :collection_ad_ad, class: "Ads::CollectionAdAd" do
    collection_ad
    ad
    position { 0 }
  end
end
