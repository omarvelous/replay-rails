require "rails_helper"

RSpec.describe "Go::Leads" do
  let(:account) { create(:account) }
  let(:listing) { create(:listing, account: account) }
  let(:agent) { create(:agent, account: account) }

  before do
    create(:listing_agent, listing: listing, agent: agent, primary_at: Time.current)
  end

  describe "POST /go/leads" do
    context "with a listing context" do
      it "creates a lead attributed to the listing's account" do
        expect {
          post go_leads_path, params: {
            lead: { name: "Jane Doe", email: "jane@example.com",
                    lead_type: "buyer_inquiry", listing_id: listing.id }
          }
        }.to change(Lead, :count).by(1)

        lead = Lead.last
        expect(lead.account).to eq(account)
        expect(lead.name).to eq("Jane Doe")
        expect(lead.lead_type).to eq("buyer_inquiry")
      end

      it "assigns the listing's primary agent via LeadAgent" do
        post go_leads_path, params: {
          lead: { name: "Jane Doe", email: "jane@example.com",
                  lead_type: "buyer_inquiry", listing_id: listing.id }
        }

        lead = Lead.last
        expect(lead.current_agent).to eq(agent)
      end

      it "stores listing_id in context" do
        post go_leads_path, params: {
          lead: { name: "Jane Doe", email: "jane@example.com",
                  lead_type: "buyer_inquiry", listing_id: listing.id }
        }

        expect(Lead.last.context["listing_id"]).to eq(listing.id)
      end

      it "links to a qr_scan when scan_id is provided" do
        qr_code = create(:qr_code, account: account, destination_record: listing)
        qr_scan = create(:qr_scan, qr_code: qr_code, account: account)

        post go_leads_path, params: {
          lead: { name: "Jane Doe", email: "jane@example.com",
                  lead_type: "buyer_inquiry", listing_id: listing.id,
                  scan_id: qr_scan.id }
        }

        expect(Lead.last.qr_scan).to eq(qr_scan)
      end

      it "redirects back with submitted flash" do
        post go_leads_path, params: {
          lead: { name: "Jane Doe", email: "jane@example.com",
                  lead_type: "buyer_inquiry", listing_id: listing.id }
        }, headers: { "HTTP_REFERER" => go_listing_url(listing, subdomain: "") }

        expect(response).to redirect_to(go_listing_url(listing, subdomain: ""))
        expect(flash[:submitted]).to be true
      end
    end

    context "with an agent context (no listing)" do
      it "creates a lead attributed to the agent's account" do
        expect {
          post go_leads_path, params: {
            lead: { name: "Tom Smith", phone: "555-1234",
                    lead_type: "general_inquiry", agent_id: agent.id }
          }
        }.to change(Lead, :count).by(1)

        lead = Lead.last
        expect(lead.account).to eq(account)
        expect(lead.current_agent).to eq(agent)
      end
    end

    context "with no parent context" do
      it "returns 422 when no listing or agent is provided" do
        post go_leads_path, params: {
          lead: { name: "Nobody", email: "no@example.com",
                  lead_type: "general_inquiry" }
        }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with invalid params" do
      it "redirects back with alert when name is blank" do
        post go_leads_path, params: {
          lead: { name: "", email: "jane@example.com",
                  lead_type: "buyer_inquiry", listing_id: listing.id }
        }, headers: { "HTTP_REFERER" => go_listing_url(listing, subdomain: "") }

        expect(response).to redirect_to(go_listing_url(listing, subdomain: ""))
        expect(flash[:alert]).to be_present
      end
    end
  end
end
