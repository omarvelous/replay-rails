FactoryBot.define do
  factory :agent do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.cell_phone_in_e164 }
    account
    user { nil }
  end
end
