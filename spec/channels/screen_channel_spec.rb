require "rails_helper"

RSpec.describe ScreenChannel do
  it "subscribes with a valid paired player token" do
    player = create(:player)
    screen = create(:screen)
    screen.pair_player!(player)

    subscribe(token: player.token)
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("screen_#{screen.id}")
  end

  it "rejects with an invalid token" do
    subscribe(token: "bad-token")
    expect(subscription).to be_rejected
  end

  it "rejects when player is not paired" do
    player = create(:player)
    subscribe(token: player.token)
    expect(subscription).to be_rejected
  end
end
