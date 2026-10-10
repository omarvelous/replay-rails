FactoryBot.define do
  factory :qr_code do
    account
    destination_record { association :listing, account: instance.account }
    label { "Property details" }
  end
end
