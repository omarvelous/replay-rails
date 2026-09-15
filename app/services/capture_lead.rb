class CaptureLead
  Result = Struct.new(:success?, :lead, keyword_init: true)

  def initialize(params:, request_context: {})
    @params = params.to_h.symbolize_keys
    @request_context = request_context
  end

  def call
    listing = Listing.find_signed(@params.delete(:listing_sid), purpose: :lead_form)
    agent = Agent.find_signed(@params.delete(:agent_sid), purpose: :lead_form) || listing&.primary_agent
    account = listing&.account || agent&.account

    return Result.new(success?: false) unless account

    lead = Lead.new(@params.except(:website))
    lead.listing = listing
    lead.account = account
    lead.context = @request_context

    if lead.save
      lead.lead_agents.create!(agent: agent) if agent
      LeadMailer.new_lead(lead).deliver_later
      Result.new(success?: true, lead: lead)
    else
      Result.new(success?: false, lead: lead)
    end
  end
end
