class PasswordsMailerPreview < ActionMailer::Preview
  def reset
    user = User.first || FactoryBot.create(:user)
    PasswordsMailer.reset(user)
  end

  def changed
    user = User.first || FactoryBot.create(:user)
    PasswordsMailer.changed(user)
  end
end
