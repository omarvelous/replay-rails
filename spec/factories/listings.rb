FactoryBot.define do
  factory :listing do
    account
    address { Faker::Address.full_address }
    price { Faker::Number.between(from: 200_000, to: 5_000_000) }
    beds { Faker::Number.between(from: 1, to: 6) }
    baths { Faker::Number.between(from: 1, to: 4) }
    sqft { Faker::Number.between(from: 500, to: 5_000) }
    status { %w[active pending sold].sample }
    property_type { Listing::PROPERTY_TYPES.sample }
    listing_type { Listing::LISTING_TYPES.sample }
  end
end
