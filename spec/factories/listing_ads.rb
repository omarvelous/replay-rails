FactoryBot.define do
  factory :listing_ad do
    association :listing
    badge { "just_listed" }

    trait :open_house do
      badge { "open_house" }
      event_date { 1.week.from_now.to_date }
      event_start_time { Time.zone.parse("13:00") }
      event_end_time { Time.zone.parse("15:00") }
    end

    trait :price_reduction do
      badge { "price_reduction" }
      original_price { 1_500_000 }
    end

    trait :just_sold do
      badge { "just_sold" }
      sold_price { 1_200_000 }
      sold_date { 1.week.ago.to_date }
    end

    trait :coming_soon do
      badge { "coming_soon" }
    end
  end
end
