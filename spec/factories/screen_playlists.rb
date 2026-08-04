FactoryBot.define do
  factory :screen_playlist do
    association :screen
    association :playlist
    active { true }
  end
end
