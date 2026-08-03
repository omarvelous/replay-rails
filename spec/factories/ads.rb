FactoryBot.define do
  factory :ad do
    headline { Faker::Marketing.buzzwords.capitalize }
    body { Faker::Lorem.sentence }
    association :account
    listing { nil }
  end
end
