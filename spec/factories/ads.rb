FactoryBot.define do
  factory :ad do
    account
    adable { association :listing_ad, listing: association(:listing, account: instance.account) }
    headline { Faker::Marketing.buzzwords.capitalize }
    body { Faker::Lorem.sentence }
    layout { "hero" }
    theme { "dark" }
  end
end
