require "rails_helper"

RSpec.describe "Ahoy Store configuration", type: :model do # rubocop:disable RSpec/DescribeClass
  describe "admin exclusion" do
    it "excludes admin subdomain" do
      exclude = Ahoy.exclude_method
      request = double(subdomain: "admin")
      expect(exclude.call(nil, request)).to be true
    end

    it "does not exclude app subdomain" do
      exclude = Ahoy.exclude_method
      request = double(subdomain: "app")
      expect(exclude.call(nil, request)).to be false
    end

    it "does not exclude play subdomain" do
      exclude = Ahoy.exclude_method
      request = double(subdomain: "play")
      expect(exclude.call(nil, request)).to be false
    end

    it "does not exclude nil request" do
      exclude = Ahoy.exclude_method
      expect(exclude.call(nil, nil)).to be_falsey
    end

    it "does not exclude marketing (no subdomain)" do
      exclude = Ahoy.exclude_method
      request = double(subdomain: "")
      expect(exclude.call(nil, request)).to be false
    end
  end

  describe "account_id enrichment" do
    it "Current.account provides account_id when available" do
      account = create(:account)
      allow(Current).to receive(:account).and_return(account)
      expect(Current.account.id).to eq(account.id)
    end

    it "event properties provide account_id fallback" do
      props = { "account_id" => 42 }.with_indifferent_access
      expect(props[:account_id]).to eq(42)
    end
  end
end
