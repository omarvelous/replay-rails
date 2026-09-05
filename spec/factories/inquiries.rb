FactoryBot.define do
  factory :inquiry do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    inquiry_type { "demo_request" }
  end
end
