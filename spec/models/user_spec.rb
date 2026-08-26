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
