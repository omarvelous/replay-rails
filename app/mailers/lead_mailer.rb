class LeadMailer < ApplicationMailer
  def new_lead(lead)
    @lead = lead
    recipient = lead.current_agent&.email || lead.account.users.first.email_address

    mail(
      to: recipient,
      subject: "New inquiry: #{lead.listing&.address || 'General inquiry'}"
    )
  end
end
