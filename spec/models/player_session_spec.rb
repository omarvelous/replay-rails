require "rails_helper"

RSpec.describe PlayerSession do
  describe "associations" do
    it { is_expected.to belong_to(:player) }
  end

  describe "scopes" do
    it ".active returns sessions without revoked_at" do
      player = create(:player)
      active = player.player_sessions.create!(ip_address: "1.1.1.1")
      revoked = player.player_sessions.create!(ip_address: "2.2.2.2", revoked_at: Time.current)

      expect(described_class.active).to eq([ active ])
    end
  end

  describe "#revoke!" do
    it "sets revoked_at" do
      player = create(:player)
      session = player.player_sessions.create!(ip_address: "1.1.1.1")

      expect { session.revoke! }.to change { session.reload.revoked_at }.from(nil)
    end

    it "is excluded from active scope after revocation" do
      player = create(:player)
      session = player.player_sessions.create!(ip_address: "1.1.1.1")
      session.revoke!

      expect(described_class.active).not_to include(session)
    end
  end
end
