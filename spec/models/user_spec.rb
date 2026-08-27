require "rails_helper"

RSpec.describe User do
  subject(:user) { build(:user) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:first_name) }
    it { is_expected.to validate_presence_of(:last_name) }
    it { is_expected.to validate_presence_of(:email_address) }
    it { is_expected.to have_secure_password }

    it "validates uniqueness of email_address case-insensitively" do
      create(:user, email_address: "test@example.com")
      duplicate = build(:user, email_address: "TEST@EXAMPLE.COM")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email_address]).to be_present
    end

    it "normalizes email_address to lowercase and stripped" do
      u = create(:user, email_address: "  HELLO@EXAMPLE.COM  ")
      expect(u.email_address).to eq("hello@example.com")
    end

    context "with phone" do
      it "is valid with a standard phone number" do
        user.phone = "212-555-1234"
        expect(user).to be_valid
      end

      it "is invalid with a non-phone string" do
        user.phone = "not-a-phone"
        expect(user).not_to be_valid
        expect(user.errors[:phone]).to be_present
      end

      it "is valid when phone is blank" do
        user.phone = ""
        expect(user).to be_valid
      end
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:sessions).dependent(:destroy) }
    it { is_expected.to have_many(:account_users).dependent(:destroy) }
    it { is_expected.to have_many(:accounts).through(:account_users) }
  end

  describe "#admin?" do
    it "defaults to false" do
      expect(build(:user)).not_to be_admin
    end

    it "returns true when admin is set" do
      expect(build(:user, admin: true)).to be_admin
    end
  end

  describe "Authorizable" do
    let(:account) { create(:account) }
    let(:user) { create(:user, account: account, role: "manager") }

    describe "#roles_on" do
      it "returns all roles for the account" do
        create(:account_user, account: account, user: user, role: "agent")
        expect(user.roles_on(account)).to contain_exactly("manager", "agent")
      end
    end

    describe "#has_role?" do
      it "returns true when user has the role" do
        expect(user.has_role?("manager", account)).to be true
      end

      it "returns false when user does not have the role" do
        expect(user.has_role?("owner", account)).to be false
      end
    end

    describe "#owner_of?" do
      it "returns true for owners" do
        owner = create(:user, account: account, role: "owner")
        expect(owner.owner_of?(account)).to be true
      end

      it "returns false for non-owners" do
        expect(user.owner_of?(account)).to be false
      end
    end

    describe "#can_manage?" do
      it "returns true for owners" do
        owner = create(:user, account: account, role: "owner")
        expect(owner.can_manage?(account)).to be true
      end

      it "returns true for managers" do
        expect(user.can_manage?(account)).to be true
      end

      it "returns false for agents" do
        agent = create(:user, account: account, role: "agent")
        expect(agent.can_manage?(account)).to be false
      end
    end

    describe "#agent_on?" do
      it "returns true when user has agent role" do
        agent = create(:user, account: account, role: "agent")
        expect(agent.agent_on?(account)).to be true
      end
    end

    describe "#member_of?" do
      it "returns true when user is a member" do
        expect(user.member_of?(account)).to be true
      end

      it "returns false for non-members" do
        other_account = create(:account)
        expect(user.member_of?(other_account)).to be false
      end
    end
  end

  describe "authentication" do
    it "authenticates with correct password" do
      user = create(:user, password: "secret123")
      expect(user.authenticate("secret123")).to eq(user)
    end

    it "does not authenticate with wrong password" do
      user = create(:user, password: "secret123")
      expect(user.authenticate("wrong")).to be_falsey
    end
  end
end
