FactoryBot.define do
  factory :listing do
    account
    address { Faker::Address.full_address }
    price { Faker::Number.between(from: 200_000, to: 5_000_000) }
    beds { Faker::Number.between(from: 1, to: 6) }
    baths { Faker::Number.between(from: 1, to: 4) }
    sqft { Faker::Number.between(from: 500, to: 5_000) }
    status { "active" }
    property_type { "house" }
    listing_type { "for_sale" }

    trait :pending do
      status { "pending" }
    end

    trait :sold do
      status { "sold" }
    end

    trait :condo do
      property_type { "condo" }
    end

    trait :for_rent do
      listing_type { "for_rent" }
    end

    trait :for_lease do
      listing_type { "for_lease" }
    end
  end
end
