FactoryBot.define do
  factory :qr_scan do
    qr_code
    account
    ad { nil }
    screen { nil }
    ip_address { Faker::Internet.ip_v4_address }
    user_agent { Faker::Internet.user_agent }
  end
end
