require "rails_helper"

RSpec.describe ScreenPolicy do
  let(:account) { create(:account) }

  context "when user is owner" do
    let(:user) { create(:user, account: account, role: "owner") }
    let(:screen) { create(:screen, site: create(:site, account: account)) }
    let(:policy) { described_class.new(screen, user: user, account: account) }

    it { expect(policy).to permit(:index?) }
    it { expect(policy).to permit(:show?) }
    it { expect(policy).to permit(:create?) }
    it { expect(policy).to permit(:update?) }
    it { expect(policy).to permit(:destroy?) }
  end

  context "when user is agent" do
    let(:user) { create(:user, account: account, role: "agent") }
    let(:screen) { create(:screen, site: create(:site, account: account)) }
    let(:policy) { described_class.new(screen, user: user, account: account) }

    it { expect(policy).to permit(:index?) }
    it { expect(policy).to permit(:show?) }
    it { expect(policy).not_to permit(:create?) }
    it { expect(policy).not_to permit(:update?) }
    it { expect(policy).not_to permit(:destroy?) }
  end

  describe "scope" do
    let(:user) { create(:user, account: account, role: "owner") }
    let!(:own_screen) { create(:screen, site: create(:site, account: account)) }
    let!(:other_screen) { create(:screen) }

    it "returns only screens belonging to the account's sites" do
      scope = described_class.new(own_screen, user: user, account: account)
                             .apply_scope(Screen.all, type: :active_record_relation)
      expect(scope).to include(own_screen)
      expect(scope).not_to include(other_screen)
    end
  end
end
