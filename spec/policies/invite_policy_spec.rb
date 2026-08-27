require "rails_helper"

RSpec.describe InvitePolicy do
  let(:account) { create(:account) }
  let(:invite) { create(:invite, account: account, role: "agent") }

  context "when user is owner" do
    let(:user) { create(:user, account: account, role: "owner") }
    let(:policy) { described_class.new(invite, user: user, account: account) }

    it { expect(policy).to permit(:index?) }
    it { expect(policy).to permit(:new?) }
    it { expect(policy).to permit(:destroy?) }

    it "permits creating any role" do
      manager_invite = build(:invite, account: account, role: "manager")
      p = described_class.new(manager_invite, user: user, account: account)
      expect(p).to permit(:create?)
    end
  end

  context "when user is manager" do
    let(:user) { create(:user, account: account, role: "manager") }
    let(:policy) { described_class.new(invite, user: user, account: account) }

    it { expect(policy).to permit(:index?) }
    it { expect(policy).to permit(:new?) }
    it { expect(policy).to permit(:destroy?) }

    it "permits creating agent invites" do
      agent_invite = build(:invite, account: account, role: "agent")
      p = described_class.new(agent_invite, user: user, account: account)
      expect(p).to permit(:create?)
    end

    it "forbids creating manager invites" do
      manager_invite = build(:invite, account: account, role: "manager")
      p = described_class.new(manager_invite, user: user, account: account)
      expect(p).not_to permit(:create?)
    end
  end

  context "when user is agent" do
    let(:user) { create(:user, account: account, role: "agent") }
    let(:policy) { described_class.new(invite, user: user, account: account) }

    it { expect(policy).not_to permit(:index?) }
    it { expect(policy).not_to permit(:new?) }
    it { expect(policy).not_to permit(:create?) }
    it { expect(policy).not_to permit(:destroy?) }
  end

  context "when user matches invite email (invitee)" do
    let(:user) { create(:user, account: account, role: "agent") }
    let(:invite) { create(:invite, account: account, email: user.email_address, role: "manager") }
    let(:policy) { described_class.new(invite, user: user, account: account) }

    it { expect(policy).to permit(:show?) }
    it { expect(policy).to permit(:update?) }
  end

  context "when user does not match invite email" do
    let(:user) { create(:user, account: account, role: "owner") }
    let(:invite) { create(:invite, account: account, email: "other@example.com") }
    let(:policy) { described_class.new(invite, user: user, account: account) }

    it { expect(policy).not_to permit(:show?) }
    it { expect(policy).not_to permit(:update?) }
  end

  context "when user is nil (unauthenticated new user)" do
    let(:policy) { described_class.new(invite, user: nil, account: account) }

    it { expect(policy).to permit(:show?) }
    it { expect(policy).to permit(:update?) }
  end
end
