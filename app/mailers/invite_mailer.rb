class InviteMailer < ApplicationMailer
  def invite(invite)
    @invite = invite
    @accept_url = invite_url(token: invite.token, subdomain: "app")

    mail(
      to: invite.email,
      subject: "You're invited to RePlay"
    )
  end
end
