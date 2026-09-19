require "rails_helper"

RSpec.describe PairingChannel do
  it "subscribes with a valid pairing code" do
    player = create(:player)
    subscribe(code: player.pairing_code)
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("pairing_#{player.pairing_code}")
  end

  it "rejects subscription with an invalid code" do
    subscribe(code: "BADCODE")
    expect(subscription).to be_rejected
  end

  it "rejects subscription with an expired code" do
    player = create(:player)
    player.update!(pairing_code_expires_at: 1.minute.ago)
    subscribe(code: player.pairing_code)
    expect(subscription).to be_rejected
  end

  it "rejects subscription without a code" do
    subscribe(code: nil)
    expect(subscription).to be_rejected
  end
end
