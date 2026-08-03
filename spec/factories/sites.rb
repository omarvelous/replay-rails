FactoryBot.define do
  factory :site do
    name { Faker::Company.name }
    address { Faker::Address.full_address }
    association :account
  end
end
