FactoryBot.define do
  factory :playlist_ad do
    association :playlist
    association :ad
    position { 1 }
    duration { 10 }
  end
end
