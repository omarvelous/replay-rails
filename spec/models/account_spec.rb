require "rails_helper"

RSpec.describe Account do
  it { is_expected.to be_valid }

  describe "associations" do
    it { is_expected.to have_many(:account_users).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:account_users) }
    it { is_expected.to have_many(:sites) }
    it { is_expected.to have_many(:listings) }
    it { is_expected.to have_many(:agents) }
    it { is_expected.to have_many(:ads) }
    it { is_expected.to have_many(:playlists) }
  end
end
