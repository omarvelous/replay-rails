FactoryBot.define do
  factory :ad do
    headline { Faker::Marketing.buzzwords.capitalize }
    body { Faker::Lorem.sentence }
    layout { "hero" }
    theme { "dark" }
    account
    adable factory: %i[listing_ad]
  end
end
