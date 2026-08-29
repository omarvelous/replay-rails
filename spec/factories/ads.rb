FactoryBot.define do
  factory :ad do
    headline { Faker::Marketing.buzzwords.capitalize }
    body { Faker::Lorem.sentence }
    layout { "hero" }
    theme { "dark" }
    account
    adable { association :listing_ad, listing: association(:listing, account: instance.account) }
  end
end
