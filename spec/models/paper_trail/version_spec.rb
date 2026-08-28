require "rails_helper"

RSpec.describe PaperTrail::Version do
  describe "core resources" do
    it "tracks Listing changes" do
      listing = create(:listing)
      listing.update!(price: 999_999)
      expect(listing.versions.count).to eq(2) # create + update
    end

    it "tracks Ad changes" do
      ad = create(:ad)
      ad.update!(headline: "Updated Headline")
      expect(ad.versions.count).to eq(2)
    end

    it "tracks Playlist changes" do
      playlist = create(:playlist)
      playlist.update!(name: "Updated Playlist")
      expect(playlist.versions.count).to eq(2)
    end

    it "tracks Lead changes" do
      lead = create(:lead)
      lead.update!(status: "contacted")
      expect(lead.versions.count).to eq(2)
    end
  end

  describe "remaining resources" do
    it "tracks Agent changes" do
      agent = create(:agent)
      agent.update!(name: "Updated Agent")
      expect(agent.versions.count).to eq(2)
    end

    it "tracks Site changes" do
      site = create(:site)
      site.update!(name: "Updated Site")
      expect(site.versions.count).to eq(2)
    end

    it "tracks Screen changes" do
      screen = create(:screen)
      screen.update!(name: "Updated Screen")
      expect(screen.versions.count).to eq(2)
    end

    it "tracks Player creation" do
      player = create(:player)
      expect(player.versions.count).to eq(1)
    end

    it "ignores Player heartbeat updates" do
      player = create(:player)
      player.update!(last_heartbeat_at: Time.current, ip_address: "1.2.3.4", user_agent: "test")
      expect(player.versions.count).to eq(1) # only create, no update version
    end
  end

  describe "auth models" do
    it "tracks User changes" do
      user = create(:user)
      user.update!(first_name: "Updated")
      expect(user.versions.count).to eq(2)
    end

    it "tracks AccountUser changes" do
      au = create(:account_user)
      expect(au.versions.count).to eq(1)
    end

    it "tracks Invite changes" do
      invite = create(:invite)
      invite.update!(accepted_at: Time.current)
      expect(invite.versions.count).to eq(2)
    end
  end

  describe "join models" do
    let(:account) { create(:account) }

    it "tracks PlaylistAd" do
      playlist = create(:playlist, account: account)
      ad = create(:ad, account: account)
      pa = PlaylistAd.create!(playlist: playlist, ad: ad, position: 1, duration: 10)
      expect(pa.versions.count).to eq(1)
    end

    it "tracks ScreenPlaylist" do
      site = create(:site, account: account)
      screen = create(:screen, site: site)
      playlist = create(:playlist, account: account)
      sp = ScreenPlaylist.create!(screen: screen, playlist: playlist, active: true)
      expect(sp.versions.count).to eq(1)
    end

    it "tracks ScreenPlayer" do
      screen = create(:screen)
      player = create(:player)
      screen.pair_player!(player)
      sp = ScreenPlayer.last
      expect(sp.versions.count).to eq(1)
    end

    it "tracks LeadAgent" do
      lead = create(:lead, account: account)
      agent = create(:agent, account: account)
      la = LeadAgent.create!(lead: lead, agent: agent)
      expect(la.versions.count).to eq(1)
    end

    it "tracks ListingAgent" do
      listing = create(:listing, account: account)
      agent = create(:agent, account: account)
      la = ListingAgent.create!(listing: listing, agent: agent, role: "listing_agent")
      expect(la.versions.count).to eq(1)
    end
  end

  describe "metadata" do
    it "stores object_changes as jsonb" do
      listing = create(:listing, price: 500_000)
      listing.update!(price: 450_000)

      version = listing.versions.last
      expect(version.object_changes).to be_a(Hash)
      expect(version.object_changes).to have_key("price")
    end
  end
end
