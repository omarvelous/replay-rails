class InquiryMailerPreview < ActionMailer::Preview
  def notification
    inquiry = Inquiry.first || FactoryBot.create(:inquiry, message: "We have 3 offices and would love a demo.")
    InquiryMailer.notification(inquiry)
  end
end
