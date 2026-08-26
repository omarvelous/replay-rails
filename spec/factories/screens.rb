FactoryBot.define do
  factory :screen do
    name { "#{Faker::Space.constellation} Display" }
    orientation { %w[landscape portrait].sample }
    site
  end
end
