FactoryBot.define do
  factory :lead do
    account
    name { Faker::Name.name }
    email { Faker::Internet.email }
    lead_type { "general_inquiry" }
    status { "new" }
  end
end
