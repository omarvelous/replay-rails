require "rails_helper"

RSpec.describe AnalyticsRollupJob do
  it "performs without error" do
    expect { described_class.perform_now }.not_to raise_error
  end

  it "creates rollup entries from ahoy events" do
    account = create(:account)
    visit = Ahoy::Visit.create!(visit_token: SecureRandom.hex, visitor_token: SecureRandom.hex, started_at: Time.current)
    Ahoy::Event.create!(visit: visit, name: "content.impressed", properties: {}, time: Time.current, account_id: account.id)

    described_class.perform_now

    expect(Rollup.where(name: "Impressions").count).to be_positive
  end
end
