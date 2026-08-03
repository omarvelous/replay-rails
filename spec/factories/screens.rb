FactoryBot.define do
  factory :screen do
    name { "#{Faker::Space.constellation} Display" }
    orientation { %w[landscape portrait].sample }
    association :site
  end
end
