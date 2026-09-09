class InquiryMailer < ApplicationMailer
  has_history
  track_clicks campaign: "inquiry"
  def notification(inquiry)
    @inquiry = inquiry
    mail(
      to: "hello@replaytv.co",
      subject: "New #{inquiry.inquiry_type.humanize}: #{inquiry.name}"
    )
  end
end
