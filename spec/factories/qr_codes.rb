FactoryBot.define do
  factory :qr_code do
    association :account
    association :destination_record, factory: :listing
    label { "Property details" }
  end
end
