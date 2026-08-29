require "rails_helper"

RSpec.describe Listing do
  let(:account_a) { create(:account) }
  let(:account_b) { create(:account) }

  describe "tenant scoping" do
    it "scopes queries to the current tenant" do
      listing_a = create(:listing, account: account_a)
      listing_b = create(:listing, account: account_b)

      ActsAsTenant.with_tenant(account_a) do
        expect(described_class.all).to include(listing_a)
        expect(described_class.all).not_to include(listing_b)
      end
    end

    it "automatically sets account on creation when tenant is set" do
      ActsAsTenant.with_tenant(account_a) do
        listing = described_class.create!(
          address: "123 Main St",
          price: 500_000,
          status: "active"
        )
        expect(listing.account).to eq(account_a)
      end
    end
  end
end
