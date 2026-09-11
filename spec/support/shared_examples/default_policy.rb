RSpec.shared_examples "default policy" do |policy_class|
  let(:account) { create(:account) }

  context "when user is owner" do
    let(:user) { create(:user, account: account, role: "owner") }
    let(:policy) { policy_class.new(nil, user: user, account: account) }

    it { expect(policy).to permit(:index?) }
    it { expect(policy).to permit(:show?) }
    it { expect(policy).to permit(:create?) }
    it { expect(policy).to permit(:update?) }
    it { expect(policy).to permit(:destroy?) }
  end

  context "when user is manager" do
    let(:user) { create(:user, account: account, role: "manager") }
    let(:policy) { policy_class.new(nil, user: user, account: account) }

    it { expect(policy).to permit(:index?) }
    it { expect(policy).to permit(:show?) }
    it { expect(policy).to permit(:create?) }
    it { expect(policy).to permit(:update?) }
    it { expect(policy).to permit(:destroy?) }
  end

  context "when user is agent" do
    let(:user) { create(:user, account: account, role: "agent") }
    let(:policy) { policy_class.new(nil, user: user, account: account) }

    it { expect(policy).to permit(:index?) }
    it { expect(policy).to permit(:show?) }
    it { expect(policy).not_to permit(:create?) }
    it { expect(policy).not_to permit(:update?) }
    it { expect(policy).not_to permit(:destroy?) }
  end
end
