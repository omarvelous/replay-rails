require "rails_helper"

RSpec.describe Player, type: :model do
  subject(:player) { build(:player) }

  describe "associations" do
    it { is_expected.to have_many(:screen_players).dependent(:destroy) }
  end

  describe "token generation" do
    it "generates a token on create" do
      player = create(:player)
      expect(player.token).to be_present
      expect(player.token.length).to be >= 32
    end

    it "does not overwrite an existing token" do
      player = create(:player, token: "custom-token")
      expect(player.token).to eq("custom-token")
    end
  end

  describe "pairing code generation" do
    it "generates a 6-char uppercase code on create" do
      player = create(:player)
      expect(player.pairing_code).to match(/\A[A-Z0-9]{6}\z/)
    end

    it "sets expiry to 10 minutes from now" do
      player = create(:player)
      expect(player.pairing_code_expires_at).to be_within(5.seconds).of(10.minutes.from_now)
    end
  end

  describe "#paired?" do
    it "returns false when not paired" do
      player = create(:player)
      expect(player).not_to be_paired
    end

    it "returns true when actively paired to a screen" do
      player = create(:player)
      screen = create(:screen)
      create(:screen_player, player: player, screen: screen, active: true)
      expect(player.reload).to be_paired
    end
  end

  describe "#pairing_code_valid?" do
    it "returns true when code exists and not expired" do
      player = create(:player)
      expect(player.pairing_code_valid?).to be true
    end

    it "returns false when expired" do
      player = create(:player, pairing_code_expires_at: 1.minute.ago)
      expect(player.pairing_code_valid?).to be false
    end

    it "returns false when no code" do
      player = create(:player, pairing_code: nil)
      expect(player.pairing_code_valid?).to be false
    end
  end

  describe "#online?" do
    it "returns false when not paired" do
      player = create(:player, last_heartbeat_at: Time.current)
      expect(player).not_to be_online
    end

    it "returns false when heartbeat is stale" do
      player = create(:player, last_heartbeat_at: 5.minutes.ago)
      screen = create(:screen)
      create(:screen_player, player: player, screen: screen, active: true)
      expect(player.reload).not_to be_online
    end

    it "returns true when paired and heartbeat is recent" do
      player = create(:player, last_heartbeat_at: 30.seconds.ago)
      screen = create(:screen)
      create(:screen_player, player: player, screen: screen, active: true)
      expect(player.reload).to be_online
    end
  end

  describe "#refresh_pairing_code!" do
    it "generates a new code and resets expiry" do
      player = create(:player)
      old_code = player.pairing_code
      player.refresh_pairing_code!
      expect(player.pairing_code).not_to eq(old_code)
      expect(player.pairing_code_expires_at).to be_within(5.seconds).of(10.minutes.from_now)
    end
  end
end
