FactoryBot.define do
  factory :experience do
    account
    listing
    name { "#{listing.address} Open House" }
    config { { sections: { photos: true, details: true, agent_card: true, qr_handoff: true, floor_plans: true } } }
  end
end
