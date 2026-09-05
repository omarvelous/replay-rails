require "rails_helper"

RSpec.describe "Experiences" do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }
  let(:listing) { create(:listing, account: account) }

  before { sign_in(user) }

  describe "GET /experiences" do
    it "returns a successful response" do
      get experiences_path
      expect(response).to be_successful
    end

    it "lists experiences for the current account" do
      experience = create(:experience, account: account, name: "Main St Open House")
      get experiences_path
      expect(response.body).to include("Main St Open House")
    end
  end

  describe "GET /experiences/:id" do
    it "shows the experience" do
      experience = create(:experience, account: account)
      get experience_path(experience)
      expect(response).to be_successful
    end

    it "returns 404 for another account's experience" do
      other = create(:experience)
      get experience_path(other)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /experiences/new" do
    it "returns a successful response" do
      get new_experience_path
      expect(response).to be_successful
    end

    it "pre-fills listing from params" do
      get new_experience_path(listing_id: listing.id)
      expect(response).to be_successful
    end
  end

  describe "POST /experiences" do
    it "creates an experience" do
      expect {
        post experiences_path, params: {
          experience: { name: "Test Experience", listing_id: listing.id }
        }
      }.to change(Experience, :count).by(1)

      expect(response).to redirect_to(experience_path(Experience.last))
    end

    it "rejects blank name" do
      post experiences_path, params: {
        experience: { name: "", listing_id: listing.id }
      }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "PATCH /experiences/:id" do
    it "updates the experience" do
      experience = create(:experience, account: account, name: "Old Name")
      patch experience_path(experience), params: { experience: { name: "New Name" } }
      expect(experience.reload.name).to eq("New Name")
      expect(response).to redirect_to(experience_path(experience))
    end
  end

  describe "DELETE /experiences/:id" do
    it "destroys the experience" do
      experience = create(:experience, account: account)
      expect {
        delete experience_path(experience)
      }.to change(Experience, :count).by(-1)
      expect(response).to redirect_to(experiences_path)
    end
  end

  context "when user is agent" do
    let(:agent_user) { create(:user, account: account, role: "agent") }

    before { sign_in(agent_user) }

    it "allows viewing experiences" do
      get experiences_path
      expect(response).to be_successful
    end

    it "denies creating experiences" do
      post experiences_path, params: {
        experience: { name: "Test", listing_id: listing.id }
      }
      expect(response).to redirect_to(app_root_path)
    end
  end
end
