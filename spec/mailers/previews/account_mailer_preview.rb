class AccountMailerPreview < ActionMailer::Preview
  def welcome
    user = User.first || FactoryBot.create(:user)
    account = user.accounts.first || FactoryBot.create(:account)
    AccountMailer.welcome(user, account)
  end
end
