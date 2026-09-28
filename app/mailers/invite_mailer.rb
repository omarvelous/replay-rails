class InviteMailer < ApplicationMailer
  has_history
  track_clicks campaign: "invite"

  def invite(invite)
    @invite = invite
    @accept_url = invite_url(token: invite.token, subdomain: "app")

    mail(
      to: invite.email,
      subject: "You're invited to RePlay"
    )
  end

  def accepted(invite)
    @invite = invite

    mail(
      to: invite.invited_by.email_address,
      subject: "#{invite.email} accepted your invite"
    )
  end
end
