class AccountMailer < ApplicationMailer
  def welcome(user, account)
    @user = user
    @account = account

    mail(
      to: user.email_address,
      subject: "Welcome to RePlay"
    )
  end
end
