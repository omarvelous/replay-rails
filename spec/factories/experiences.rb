FactoryBot.define do
  factory :listing_experience, class: "Experiences::ListingExperience" do
    listing
    agent { nil }
  end

  factory :experience do
    account
    experienceable { association :listing_experience }
    name { "Open House Experience" }
    config { { sections: { photos: true, details: true, agent_card: true, qr_handoff: true, floor_plans: true } } }
  end
end
