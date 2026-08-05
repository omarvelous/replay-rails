FactoryBot.define do
  factory :playlist_ad do
    association :playlist
    association :ad
    duration { 10 }
  end
end
