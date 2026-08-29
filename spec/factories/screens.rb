FactoryBot.define do
  factory :screen do
    site
    name { "#{Faker::Space.constellation} Display" }
    orientation { %w[landscape portrait].sample }
  end
end
