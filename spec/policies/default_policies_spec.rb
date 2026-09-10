require "rails_helper"

RSpec.describe "Policies inheriting ApplicationPolicy defaults" do
  describe AdPolicy do
    it_behaves_like "default policy", described_class
  end

  describe PlaylistPolicy do
    it_behaves_like "default policy", described_class
  end

  describe QrCodePolicy do
    it_behaves_like "default policy", described_class
  end

  describe ScreenContentPolicy do
    it_behaves_like "default policy", described_class
  end

  describe ScreenPlayerPolicy do
    it_behaves_like "default policy", described_class
  end

  describe SitePolicy do
    it_behaves_like "default policy", described_class
  end

  describe ListingAgentPolicy do
    it_behaves_like "default policy", described_class
  end

  describe PlaylistAdPolicy do
    it_behaves_like "default policy", described_class
  end
end
