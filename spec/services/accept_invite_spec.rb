require "rails_helper"

RSpec.describe AcceptInvite do
  let(:account) { create(:account) }
  let(:invite) { create(:invite, account: account, role: "agent") }
  let(:user) { create(:user) }

  describe "#call" do
    it "marks the invite as accepted" do
      described_class.new(invite: invite, user: user).call
      expect(invite.reload).to be_accepted
    end

    it "creates an AccountUser with the invited role" do
      described_class.new(invite: invite, user: user).call

      au = AccountUser.find_by(account: account, user: user, role: "agent")
      expect(au).to be_present
    end

    it "links agent profile when role is agent and Agent record exists" do
      agent = create(:agent, account: account, email: invite.email)

      described_class.new(invite: invite, user: user).call
      expect(agent.reload.user).to eq(user)
    end

    it "does not link agent profile when no matching Agent exists" do
      described_class.new(invite: invite, user: user).call
      expect(user.agent_profile).to be_nil
    end

    it "does not overwrite an already-linked agent profile" do
      existing_user = create(:user)
      agent = create(:agent, account: account, email: invite.email, user: existing_user)

      described_class.new(invite: invite, user: user).call
      expect(agent.reload.user).to eq(existing_user)
    end
  end
end
