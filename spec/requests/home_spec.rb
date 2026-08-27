require "rails_helper"

RSpec.describe "Home" do
  describe "GET / (app root → dashboard)" do
    it "redirects to login when not authenticated" do
      get app_root_path
      expect(response).to redirect_to(new_session_path)
    end

    it "returns a successful response when authenticated" do
      sign_in(create(:user))
      get app_root_path
      expect(response).to be_successful
    end
  end
end
