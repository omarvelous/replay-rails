class LeadMailerPreview < ActionMailer::Preview
  def new_lead
    lead = Lead.first || FactoryBot.create(:lead, message: "I'd like to schedule a viewing this weekend.")
    LeadMailer.new_lead(lead)
  end
end
