FactoryBot.define do
  factory :playlist_ad do
    playlist
    ad
    duration { 10 }
  end
end
