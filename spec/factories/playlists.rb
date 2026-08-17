FactoryBot.define do
  factory :playlist do
    name { "#{Faker::Marketing.buzzwords.capitalize} Playlist" }
    status { "draft" }
    account
  end
end
