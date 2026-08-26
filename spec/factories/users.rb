FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    phone      { Faker::PhoneNumber.cell_phone_in_e164 }
    password   { "password123" }

    transient do
      account { nil }
      role { "owner" }
    end

    after(:create) do |user, evaluator|
      acct = evaluator.account || create(:account)
      create(:account_user, user: user, account: acct, role: evaluator.role)
    end
  end
end
