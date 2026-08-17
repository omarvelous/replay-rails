FactoryBot.define do
  factory :agent_ad, class: "Ads::AgentAd" do
    association :agent
  end
end
