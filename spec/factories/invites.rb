FactoryBot.define do
  factory :invite do
    account
    invited_by factory: :user
    sequence(:email) { |n| "invited#{n}@example.com" }
    role { "agent" }
  end
end
