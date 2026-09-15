require "rails_helper"

RSpec.describe AssignScreenContent do
  let(:account) { create(:account) }
  let(:site) { create(:site, account: account) }
  let(:screen) { create(:screen, site: site) }
  let(:playlist) { create(:playlist, account: account, status: "published") }

  describe "#call" do
    it "creates a new active screen_content" do
      result = described_class.new(screen_content: screen.screen_contents.build(contentable: playlist, active: true)).call

      expect(result).to be_persisted
      expect(result.contentable).to eq(playlist)
      expect(result.active).to be true
    end

    it "deactivates the previous active content" do
      old_content = create(:screen_content, screen: screen, contentable: playlist, active: true)
      new_playlist = create(:playlist, account: account, status: "published")

      described_class.new(screen_content: screen.screen_contents.build(contentable: new_playlist, active: true)).call

      expect(old_content.reload.active).to be false
    end

    it "does not destroy old content" do
      old_content = create(:screen_content, screen: screen, contentable: playlist, active: true)
      new_playlist = create(:playlist, account: account, status: "published")

      expect {
        described_class.new(screen_content: screen.screen_contents.build(contentable: new_playlist, active: true)).call
      }.to change(screen.screen_contents, :count).by(1)

      expect(ScreenContent.exists?(old_content.id)).to be true
    end

    it "handles no previous content gracefully" do
      result = described_class.new(screen_content: screen.screen_contents.build(contentable: playlist, active: true)).call

      expect(result).to be_persisted
      expect(screen.screen_contents.count).to eq(1)
    end

    it "works with experiences" do
      experience = create(:experience, account: account)
      result = described_class.new(screen_content: screen.screen_contents.build(contentable: experience, active: true)).call

      expect(result.contentable).to eq(experience)
      expect(result.active).to be true
    end
  end
end
