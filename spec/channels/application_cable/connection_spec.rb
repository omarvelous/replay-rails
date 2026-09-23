require "rails_helper"

RSpec.describe ApplicationCable::Connection do
  let(:user) { create(:user) }
  let(:player) { create(:player) }

  it "identifies the user from a session cookie" do
    session = user.sessions.create!(user_agent: "RSpec", ip_address: "127.0.0.1")
    cookies.signed[:session_id] = session.id

    connect "/cable"

    expect(connection.current_user).to eq(user)
  end

  it "identifies the player from a player session cookie" do
    player_session = player.player_sessions.create!(ip_address: "127.0.0.1")
    cookies.signed[:player_session_id] = player_session.id

    connect "/cable"

    expect(connection.current_player).to eq(player)
  end

  it "allows anonymous connections" do
    connect "/cable"

    expect(connection.current_user).to be_nil
    expect(connection.current_player).to be_nil
  end
end
