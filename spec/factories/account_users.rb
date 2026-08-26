FactoryBot.define do
  factory :account_user do
    account
    user
    role { "owner" }

    trait :manager do
      role { "manager" }
    end

    trait :agent do
      role { "agent" }
    end
  end
end
