FactoryBot.define do
  factory :listing_experience, class: "Experiences::ListingExperience" do
    listing
    agent { nil }
  end

  factory :experience do
    account
    name { "Open House Experience" }
    config { { sections: { photos: true, details: true, agent_card: true, qr_handoff: true, floor_plans: true } } }

    after(:build) do |experience|
      unless experience.experienceable
        listing = create(:listing, account: experience.account)
        experience.experienceable = create(:listing_experience, listing: listing)
      end
    end
  end
end
