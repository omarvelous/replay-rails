require "rails_helper"

RSpec.describe PairingChannel, type: :channel do
  it "subscribes with a code" do
    subscribe(code: "A7B3K2")
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("pairing_A7B3K2")
  end

  it "does not stream without a code" do
    subscribe(code: nil)
    expect(subscription).to be_confirmed
    expect(subscription).not_to have_stream_from(anything)
  end
end
