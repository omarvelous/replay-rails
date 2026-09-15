require "rails_helper"

RSpec.describe CaptureLead do
  let(:account) { create(:account) }
  let(:listing) { create(:listing, account: account) }
  let(:agent) { create(:agent, account: account) }

  before do
    create(:listing_agent, listing: listing, agent: agent, primary_at: Time.current)
  end

  describe "#call" do
    let(:valid_params) do
      {
        name: "Jane Doe",
        email: "jane@example.com",
        lead_type: "buyer_inquiry",
        listing_sid: listing.signed_id(purpose: :lead_form)
      }
    end

    let(:request_context) do
      { source_url: "https://example.com/listing", ip_address: "1.2.3.4", user_agent: "Test/1.0" }
    end

    it "creates a lead" do
      result = described_class.new(params: valid_params, request_context: request_context).call

      expect(result).to be_success
      expect(result.lead).to be_persisted
      expect(result.lead.name).to eq("Jane Doe")
      expect(result.lead.account).to eq(account)
    end

    it "associates the lead with the listing" do
      result = described_class.new(params: valid_params, request_context: request_context).call

      expect(result.lead.listing).to eq(listing)
    end

    it "assigns the listing's primary agent" do
      result = described_class.new(params: valid_params, request_context: request_context).call

      expect(result.lead.current_agent).to eq(agent)
    end

    it "stores request context" do
      result = described_class.new(params: valid_params, request_context: request_context).call

      expect(result.lead.context["ip_address"]).to eq("1.2.3.4")
    end

    it "enqueues the lead notification email" do
      expect {
        described_class.new(params: valid_params, request_context: request_context).call
      }.to have_enqueued_mail(LeadMailer, :new_lead)
    end

    context "with agent context only (no listing)" do
      let(:agent_params) do
        {
          name: "Tom",
          phone: "555-1234",
          lead_type: "general_inquiry",
          agent_sid: agent.signed_id(purpose: :lead_form)
        }
      end

      it "creates a lead via the agent's account" do
        result = described_class.new(params: agent_params, request_context: request_context).call

        expect(result).to be_success
        expect(result.lead.account).to eq(account)
        expect(result.lead.current_agent).to eq(agent)
      end
    end

    context "with no listing or agent" do
      it "returns failure" do
        result = described_class.new(
          params: { name: "Nobody", email: "no@example.com", lead_type: "general_inquiry" },
          request_context: request_context
        ).call

        expect(result).not_to be_success
        expect(result.lead).to be_nil
      end
    end

    context "with invalid lead params" do
      it "returns failure with errors" do
        result = described_class.new(
          params: valid_params.merge(name: ""),
          request_context: request_context
        ).call

        expect(result).not_to be_success
        expect(result.lead.errors).to be_present
      end
    end
  end
end
