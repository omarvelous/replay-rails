FactoryBot.define do
  factory :metric_snapshot do
    account
    metric_name { "impressions" }
    value { 100 }
    starts_at { Date.yesterday.beginning_of_day }
    ends_at { Date.yesterday.end_of_day }
  end
end
