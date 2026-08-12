require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    it "returns a successful response when not authenticated" do
      get root_path
      expect(response).to be_successful
    end

    it "returns a successful response when authenticated" do
      sign_in(create(:user))
      get root_path
      expect(response).to be_successful
    end
  end
end
