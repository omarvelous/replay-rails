require "rails_helper"

RSpec.describe "Agents" do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account) }

  before { sign_in(user) }

  describe "GET /agents" do
    it "returns a successful response" do
      get agents_path
      expect(response).to be_successful
    end

    it "renders pagination" do
      get agents_path
      expect(assigns(:pagy)).to be_present
    end

    it "lists agents for the current account" do
      agent = create(:agent, account: account, name: "Jane Smith")
      other_agent = create(:agent, name: "Other Agent")

      get agents_path
      expect(response.body).to include("Jane Smith")
      expect(response.body).not_to include("Other Agent")
    end
  end

  describe "GET /agents/new" do
    it "returns a successful response" do
      get new_agent_path
      expect(response).to be_successful
    end
  end

  describe "POST /agents" do
    let(:valid_params) do
      { agent: { name: "Jane Smith", email: "jane@example.com", phone: "+12125551234" } }
    end

    context "with valid params" do
      it "creates an agent scoped to the current account" do
        expect {
          post agents_path, params: valid_params
        }.to change(account.agents, :count).by(1)
      end

      it "redirects to the agent" do
        post agents_path, params: valid_params
        expect(response).to redirect_to(agent_path(Agent.last))
      end
    end

    context "with a linked user" do
      it "associates the agent with a user in the same account" do
        post agents_path, params: valid_params.deep_merge(agent: { user_id: user.id })
        expect(Agent.last.user).to eq(user)
      end
    end

    context "with invalid params" do
      it "does not create an agent" do
        expect {
          post agents_path, params: { agent: { name: "" } }
        }.not_to change(Agent, :count)
      end

      it "returns 422" do
        post agents_path, params: { agent: { name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /agents/:id" do
    it "shows the agent" do
      agent = create(:agent, account: account, name: "Jane Smith")
      get agent_path(agent)
      expect(response).to be_successful
      expect(response.body).to include("Jane Smith")
    end

    it "returns 404 for another account's agent" do
      other_agent = create(:agent)
      get agent_path(other_agent)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /agents/:id/edit" do
    it "returns a successful response" do
      agent = create(:agent, account: account)
      get edit_agent_path(agent)
      expect(response).to be_successful
    end
  end

  describe "PATCH /agents/:id" do
    let(:agent) { create(:agent, account: account, name: "Old Name") }

    context "with valid params" do
      it "updates the agent" do
        patch agent_path(agent), params: { agent: { name: "New Name" } }
        expect(agent.reload.name).to eq("New Name")
      end

      it "redirects to the agent" do
        patch agent_path(agent), params: { agent: { name: "New Name" } }
        expect(response).to redirect_to(agent_path(agent))
      end
    end

    context "with invalid params" do
      it "returns 422" do
        patch agent_path(agent), params: { agent: { name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /agents/:id" do
    it "destroys the agent" do
      agent = create(:agent, account: account)
      expect {
        delete agent_path(agent)
      }.to change(account.agents, :count).by(-1)
    end

    it "redirects to the index" do
      agent = create(:agent, account: account)
      delete agent_path(agent)
      expect(response).to redirect_to(agents_path)
    end
  end
end
