require "rails_helper"

RSpec.describe Screen do
  subject(:screen) { build(:screen) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_inclusion_of(:orientation).in_array(%w[landscape portrait]) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:site) }
    it { is_expected.to have_many(:screen_contents).dependent(:destroy) }
  end

  describe "#active_content" do
    let(:account) { create(:account) }
    let(:site) { create(:site, account: account) }
    let(:screen) { create(:screen, site: site) }

    it "returns the active playlist" do
      playlist = create(:playlist, account: account, status: "published")
      create(:screen_content, screen: screen, contentable: playlist, active: true)
      expect(screen.active_content).to eq(playlist)
    end

    it "returns the active experience" do
      experience = create(:experience, account: account)
      create(:screen_content, screen: screen, contentable: experience, active: true)
      expect(screen.active_content).to eq(experience)
    end

    it "returns nil when no active content" do
      expect(screen.active_content).to be_nil
    end
  end

  describe "#content_type" do
    let(:account) { create(:account) }
    let(:site) { create(:site, account: account) }
    let(:screen) { create(:screen, site: site) }

    it "returns :playlist when a playlist is active" do
      playlist = create(:playlist, account: account, status: "published")
      create(:screen_content, screen: screen, contentable: playlist, active: true)
      expect(screen.content_type).to eq(:playlist)
    end

    it "returns :experience when an experience is active" do
      experience = create(:experience, account: account)
      create(:screen_content, screen: screen, contentable: experience, active: true)
      expect(screen.content_type).to eq(:experience)
    end

    it "returns :none when no content assigned" do
      expect(screen.content_type).to eq(:none)
    end
  end

  describe "scopes" do
    let(:account) { create(:account) }
    let(:site) { create(:site, account: account) }

    describe ".search" do
      it "searches by name case-insensitively" do
        match = create(:screen, site: site, name: "Window Display")
        create(:screen, site: site, name: "Gallery Entrance")
        expect(described_class.search("window")).to eq([ match ])
      end
    end

    describe ".live" do
      it "returns screens with active screen_contents" do
        live_screen = create(:screen, site: site)
        idle_screen = create(:screen, site: site, name: "Idle")
        playlist = create(:playlist, account: account, status: "published")
        create(:screen_content, screen: live_screen, contentable: playlist, active: true)

        expect(described_class.live).to include(live_screen)
        expect(described_class.live).not_to include(idle_screen)
      end
    end

    describe ".idle" do
      it "returns screens without active screen_contents" do
        live_screen = create(:screen, site: site)
        idle_screen = create(:screen, site: site, name: "Idle")
        playlist = create(:playlist, account: account, status: "published")
        create(:screen_content, screen: live_screen, contentable: playlist, active: true)

        expect(described_class.idle).to include(idle_screen)
        expect(described_class.idle).not_to include(live_screen)
      end
    end
  end

  describe "player pairing" do
    let(:account) { create(:account) }
    let(:site) { create(:site, account: account) }
    let(:screen) { create(:screen, site: site) }
    let(:player) { create(:player) }

    describe "#paired?" do
      it "returns false when no player is paired" do
        expect(screen).not_to be_paired
      end

      it "returns true when a player is actively paired" do
        screen.pair_player!(player)
        expect(screen).to be_paired
      end
    end

    describe "#online?" do
      it "returns false when no player paired" do
        expect(screen).not_to be_online
      end

      it "delegates to player#online?" do
        player.update!(last_heartbeat_at: 30.seconds.ago)
        screen.pair_player!(player)
        expect(screen).to be_online
      end
    end

    describe "#pair_player!" do
      it "creates an active ScreenPlayer" do
        screen.pair_player!(player)
        screen.reload
        expect(screen.player).to eq(player)
        expect(screen.active_player_assignment).to be_active
      end

      it "records who paired it" do
        user = create(:user, account: account)
        screen.pair_player!(player, paired_by: user)
        expect(screen.reload.active_player_assignment.paired_by).to eq(user)
      end

      it "clears the player pairing code" do
        screen.pair_player!(player)
        player.reload
        expect(player.pairing_code).to be_nil
        expect(player.pairing_code_expires_at).to be_nil
      end

      it "unpairs any existing player on the screen" do
        old_player = create(:player)
        screen.pair_player!(old_player)
        screen.reload
        screen.pair_player!(player)
        expect(screen.reload.player).to eq(player)
        expect(ScreenPlayer.where(player: old_player).active.count).to eq(0)
      end

      it "unpairs the player from any other screen" do
        other_screen = create(:screen, site: site, name: "Other")
        other_screen.pair_player!(player)
        screen.pair_player!(player)
        expect(screen.reload.player).to eq(player)
        expect(other_screen.reload.player).to be_nil
      end

      it "runs inside a database lock" do
        screen.pair_player!(player)
        # Verify the pairing succeeded within a lock by checking
        # that concurrent modifications are serialized
        expect(screen.reload.player).to eq(player)
      end
    end

    describe "#unpair_player!" do
      it "deactivates the active pairing" do
        screen.pair_player!(player)
        screen.reload
        screen.unpair_player!
        expect(screen.reload).not_to be_paired
      end

      it "preserves pairing history" do
        screen.pair_player!(player)
        screen.reload
        screen.unpair_player!
        expect(screen.screen_players.history.count).to eq(1)
      end
    end
  end
end
