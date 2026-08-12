FactoryBot.define do
  factory :collection_ad_ad do
    association :collection_ad
    association :ad
    position { 0 }
  end
end
