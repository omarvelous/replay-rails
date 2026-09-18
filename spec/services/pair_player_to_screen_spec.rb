require "rails_helper"

RSpec.describe PairPlayerToScreen do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:site) { create(:site, account: account) }
  let(:screen) { create(:screen, site: site) }
  let(:player) { create(:player) }

  describe "#call" do
    it "pairs the player to the screen" do
      result = described_class.new(screen: screen, code: player.pairing_code, paired_by: user).call

      expect(result).to be_success
      expect(screen.reload.player).to eq(player)
    end

    it "clears the pairing code" do
      described_class.new(screen: screen, code: player.pairing_code, paired_by: user).call

      player.reload
      expect(player.pairing_code).to be_nil
      expect(player.pairing_code_expires_at).to be_nil
    end

    it "records who paired the device" do
      described_class.new(screen: screen, code: player.pairing_code, paired_by: user).call

      expect(screen.reload.active_player_assignment.paired_by).to eq(user)
    end

    it "unpairs the previous player from the screen" do
      old_player = create(:player)
      pair_player!(screen, old_player, paired_by: user)

      described_class.new(screen: screen, code: player.pairing_code, paired_by: user).call

      expect(screen.reload.player).to eq(player)
      expect(old_player.reload.active_assignment).to be_nil
    end

    it "unpairs the player from any other screen" do
      other_screen = create(:screen, site: site)
      pair_player!(other_screen, player, paired_by: user)
      player.refresh_pairing_code!

      described_class.new(screen: screen, code: player.pairing_code, paired_by: user).call

      expect(other_screen.reload.player).to be_nil
      expect(screen.reload.player).to eq(player)
    end

    it "revokes existing sessions and creates a new one" do
      old_session = player.player_sessions.create!(ip_address: "1.1.1.1")

      described_class.new(screen: screen, code: player.pairing_code, paired_by: user).call

      expect(old_session.reload.revoked_at).to be_present
      expect(player.player_sessions.active.count).to eq(1)
      expect(player.player_sessions.active.last).not_to eq(old_session)
    end

    it "broadcasts the pairing event with session_id" do
      code = player.pairing_code

      allow(ActionCable.server).to receive(:broadcast)

      described_class.new(screen: screen, code: code, paired_by: user).call

      expect(ActionCable.server).to have_received(:broadcast).with(
        "pairing_#{code}",
        hash_including(paired: true, session_id: PlayerSession.last.id)
      )
    end

    context "with invalid code" do
      it "returns failure for unknown code" do
        result = described_class.new(screen: screen, code: "BADCODE", paired_by: user).call

        expect(result).not_to be_success
        expect(result.error).to include("not found")
      end

      it "returns failure for expired code" do
        player.update!(pairing_code_expires_at: 1.minute.ago)

        result = described_class.new(screen: screen, code: player.pairing_code, paired_by: user).call

        expect(result).not_to be_success
        expect(result.error).to include("expired")
      end

      it "does not pair on failure" do
        described_class.new(screen: screen, code: "BADCODE", paired_by: user).call

        expect(screen.reload.player).to be_nil
      end
    end
  end
end
