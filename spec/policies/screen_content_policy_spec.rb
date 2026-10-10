require "rails_helper"

RSpec.describe ScreenContentPolicy do
  let(:account) { create(:account) }
  let(:record) { create(:screen_content) }

  %w[owner manager].each do |role|
    context "when user is #{role}" do
      let(:user) { create(:user, account: account, role: role) }
      let(:account_user) { user.membership_on(account) }
      let(:policy) { described_class.new(record, user: user, account: account, account_user: account_user) }

      it { expect(policy).to permit(:index?) }
      it { expect(policy).to permit(:show?) }
      it { expect(policy).to permit(:create?) }
      it { expect(policy).to permit(:update?) }
      it { expect(policy).to permit(:destroy?) }
    end
  end

  context "when user is agent" do
    let(:user) { create(:user, account: account, role: "agent") }
    let(:account_user) { user.membership_on(account) }
    let(:policy) { described_class.new(record, user: user, account: account, account_user: account_user) }

    it { expect(policy).to permit(:index?) }
    it { expect(policy).to permit(:show?) }
    it { expect(policy).not_to permit(:create?) }
    it { expect(policy).not_to permit(:update?) }
    it { expect(policy).not_to permit(:destroy?) }
  end
end
