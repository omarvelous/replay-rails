FactoryBot.define do
  factory :site do
    account
    name { Faker::Company.name }
    address { Faker::Address.full_address }
  end
end
