class InviteMailerPreview < ActionMailer::Preview
  def invite
    invite = Invite.first || FactoryBot.create(:invite)
    InviteMailer.invite(invite)
  end
end
