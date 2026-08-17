FactoryBot.define do
  factory :screen_playlist do
    screen
    playlist
    active { true }
  end
end
