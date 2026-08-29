FactoryBot.define do
  factory :agent do
    account
    name { Faker::Name.name }
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.cell_phone_in_e164 }
    user { nil }
  end
end
