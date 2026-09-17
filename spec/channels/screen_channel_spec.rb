require "rails_helper"

RSpec.describe ScreenChannel do
  it "subscribes with a valid paired player" do
    player = create(:player)
    screen = create(:screen)
    pair_player!(screen, player)

    stub_connection current_player: player.reload
    subscribe
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("screen_#{screen.id}")
  end

  it "rejects without a player" do
    stub_connection current_player: nil
    subscribe
    expect(subscription).to be_rejected
  end

  it "rejects when player is not paired" do
    player = create(:player)
    stub_connection current_player: player
    subscribe
    expect(subscription).to be_rejected
  end
end
