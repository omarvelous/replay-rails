class InviteMailerPreview < ActionMailer::Preview
  def invite
    invite = Invite.first || FactoryBot.create(:invite)
    InviteMailer.invite(invite)
  end

  def accepted
    invite = Invite.where.not(accepted_at: nil).first
    invite ||= FactoryBot.create(:invite).tap { |i| i.update!(accepted_at: Time.current) }
    InviteMailer.accepted(invite)
  end
end
