FactoryBot.define do
  factory :qr_scan do
    association :qr_code
    association :account
    ip_address { Faker::Internet.ip_v4_address }
    user_agent { Faker::Internet.user_agent }
  end
end
