FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    phone      { Faker::PhoneNumber.cell_phone_in_e164 }
    password   { "password123" }
    account
  end
end
