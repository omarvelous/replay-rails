FactoryBot.define do
  factory :ad do
    headline { Faker::Marketing.buzzwords.capitalize }
    body { Faker::Lorem.sentence }
    layout { "hero" }
    theme { "dark" }
    association :account
    association :adable, factory: :listing_ad
  end
end
