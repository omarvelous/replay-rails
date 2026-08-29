require "rails_helper"

RSpec.describe "Tenant scoping" do
  let(:account_a) { create(:account) }
  let(:account_b) { create(:account) }

  describe "Listing" do
    it "scopes queries to the current tenant" do
      listing_a = create(:listing, account: account_a)
      listing_b = create(:listing, account: account_b)

      ActsAsTenant.with_tenant(account_a) do
        expect(Listing.all).to include(listing_a)
        expect(Listing.all).not_to include(listing_b)
      end
    end

    it "automatically sets account on creation when tenant is set" do
      ActsAsTenant.with_tenant(account_a) do
        listing = Listing.create!(
          address: "123 Main St",
          price: 500_000,
          bedrooms: 3,
          bathrooms: 2,
          sqft: 1500,
          status: "active"
        )
        expect(listing.account).to eq(account_a)
      end
    end
  end
end
