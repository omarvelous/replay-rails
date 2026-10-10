require "rails_helper"

RSpec.describe RefreshPairingCode do
  let(:player) { create(:player) }

  describe "#call" do
    it "returns a pairing code" do
      result = described_class.new(player: player).call

      expect(result.success?).to be true
      expect(result.pairing_code).to be_present
      expect(result.expires_at).to be_present
    end

    it "returns the existing code when still valid" do
      player.refresh_pairing_code!
      existing_code = player.pairing_code

      result = described_class.new(player: player).call

      expect(result.pairing_code).to eq(existing_code)
    end

    it "generates a new code when expired" do
      player.update!(
        pairing_code: "OLDCODE",
        pairing_code_expires_at: 1.hour.ago
      )

      result = described_class.new(player: player).call

      expect(result.pairing_code).not_to eq("OLDCODE")
      expect(result.expires_at).to be > Time.current
    end
  end
end
