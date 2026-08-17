FactoryBot.define do
  factory :screen_player do
    screen
    player
    active { true }
  end
end
