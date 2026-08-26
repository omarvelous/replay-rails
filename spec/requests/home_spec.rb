require "rails_helper"

RSpec.describe "Home" do
  describe "GET / (app root)" do
    it "returns a successful response when not authenticated" do
      get app_root_path
      expect(response).to be_successful
    end

    it "returns a successful response when authenticated" do
      sign_in(create(:user))
      get app_root_path
      expect(response).to be_successful
    end
  end
end
