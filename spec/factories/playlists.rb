FactoryBot.define do
  factory :playlist do
    account
    name { "#{Faker::Marketing.buzzwords.capitalize} Playlist" }
    status { "draft" }
  end
end
