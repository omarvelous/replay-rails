FactoryBot.define do
  factory :screen_content do
    screen
    contentable { association :playlist }
    active { true }

    trait :with_experience do
      contentable { association :experience }
    end
  end
end
