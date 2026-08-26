FactoryBot.define do
  factory :qr_code do
    account
    destination_record factory: %i[listing]
    label { "Property details" }
  end
end
