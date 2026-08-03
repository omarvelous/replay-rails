FactoryBot.define do
  factory :listing_agent do
    association :listing
    association :agent
    role { "listing_agent" }
  end
end
