require "rails_helper"

RSpec.describe ApplicationPolicy do
  let(:account) { create(:account) }

  context "as an owner" do
    subject { described_class.new(account_user, nil) }

    let(:account_user) { create(:account_user, account: account, role: "owner") }


    it { is_expected.to permit_actions(%i[index show create update destroy]) }
  end

  context "as a manager" do
    subject { described_class.new(account_user, nil) }

    let(:account_user) { create(:account_user, :manager, account: account) }


    it { is_expected.to permit_actions(%i[index show create update destroy]) }
  end

  context "as an agent" do
    subject { described_class.new(account_user, nil) }

    let(:account_user) { create(:account_user, :agent, account: account) }


    it { is_expected.to permit_actions(%i[index show]) }
    it { is_expected.to forbid_actions(%i[create update destroy]) }
  end
end
