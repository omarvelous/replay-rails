module App
  class InvitesController < App::BaseController
    before_action :set_invite, only: %i[destroy resend]

    # GET /invites
    def index
      @pagy, @invites = pagy(authorized_scope(Invite.all).order(created_at: :desc))
    end

    # GET /invites/new
    def new
      @invite = Invite.new(account: Current.account, role: "agent")
      authorize! @invite
    end

    # POST /invites
    def create
      @invite = Invite.new(invite_params)
      @invite.account = Current.account
      @invite.invited_by = Current.user
      authorize! @invite

      if @invite.save
        InviteMailer.invite(@invite).deliver_later
        redirect_to invites_path, notice: t(".success")
      else
        render :new, status: :unprocessable_content
      end
    end

    # DELETE /invites/:token
    def destroy
      authorize! @invite
      @invite.destroy
      redirect_to invites_path, notice: t(".success")
    end

    # POST /invites/:token/resend
    def resend
      authorize! @invite
      if @invite.pending?
        @invite.update!(resent_at: Time.current)
        InviteMailer.invite(@invite).deliver_later
        redirect_to invites_path, notice: t(".success")
      else
        redirect_to invites_path, alert: "This invite can no longer be resent."
      end
    end

    private

      def set_invite
        @invite = Invite.find_by!(token: params[:token])
      end

      def invite_params
        permitted = params.require(:invite).permit(:email, :invited_role)
        permitted[:role] = permitted.delete(:invited_role) if permitted[:invited_role]
        permitted
      end
  end
end
