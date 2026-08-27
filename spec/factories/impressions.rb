FactoryBot.define do
  factory :impression do
    ad
    screen
    player
    site
    account
    playlist { nil }
    position { 1 }
    duration { 10 }
  end
end
