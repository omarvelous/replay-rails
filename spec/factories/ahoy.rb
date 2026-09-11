FactoryBot.define do
  factory :ahoy_visit, class: "Ahoy::Visit" do
    visit_token { SecureRandom.hex(16) }
    visitor_token { SecureRandom.hex(16) }
    started_at { Time.current }
  end

  factory :ahoy_event, class: "Ahoy::Event" do
    visit factory: %i[ahoy_visit]
    name { "test.event" }
    properties { {} }
    time { Time.current }
  end
end
