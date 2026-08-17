require "rails_helper"

RSpec.describe QrScan, type: :model do
  subject(:qr_scan) { build(:qr_scan) }

  describe "associations" do
    it { is_expected.to belong_to(:qr_code) }
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:ad).optional }
    it { is_expected.to belong_to(:screen).optional }
  end

  describe "scopes" do
    let(:account) { create(:account) }
    let(:qr_code) { create(:qr_code, account: account) }
    let(:ad) { create(:ad, account: account) }
    let(:site) { create(:site, account: account) }
    let(:screen) { create(:screen, site: site) }

    describe ".qualified" do
      it "returns scans with both ad and screen" do
        qualified = create(:qr_scan, qr_code: qr_code, account: account, ad: ad, screen: screen)
        create(:qr_scan, qr_code: qr_code, account: account, ad: ad, screen: nil)
        create(:qr_scan, qr_code: qr_code, account: account, ad: nil, screen: screen)
        create(:qr_scan, qr_code: qr_code, account: account, ad: nil, screen: nil)

        expect(described_class.qualified).to eq([ qualified ])
      end
    end

    describe ".unqualified" do
      it "returns scans missing ad or screen" do
        create(:qr_scan, qr_code: qr_code, account: account, ad: ad, screen: screen)
        no_screen = create(:qr_scan, qr_code: qr_code, account: account, ad: ad, screen: nil)
        no_ad = create(:qr_scan, qr_code: qr_code, account: account, ad: nil, screen: screen)
        neither = create(:qr_scan, qr_code: qr_code, account: account, ad: nil, screen: nil)

        expect(described_class.unqualified).to contain_exactly(no_screen, no_ad, neither)
      end
    end
  end
end
