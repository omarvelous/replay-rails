FactoryBot.define do
  factory :screen_player do
    association :screen
    association :player
    active { true }
  end
end
