FactoryBot.define do
  factory :listing_agent do
    listing
    agent
    role { "listing_agent" }
  end
end
