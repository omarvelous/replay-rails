module App
  module Invites
    class RegistrationsController < App::BaseController
    allow_unauthenticated_access
    before_action :set_invite
    before_action :require_authentication_for_existing_users, only: :show

    # GET /invites/:token/register
    def show
      if @invite.expired?
        render :expired, layout: "public"
        return
      end

      if @invite.accepted?
        redirect_to app_root_path, notice: "This invite has already been accepted."
        return
      end

      if Current.user
        AcceptInvite.new(invite: @invite, user: Current.user).call
        redirect_to app_root_path, notice: "You've joined the team."
        return
      end

      @user = User.new
    end

    # PATCH /invites/:token/register
    def update
      if @invite.expired? || @invite.accepted?
        redirect_to app_root_path, alert: "This invite is no longer valid."
        return
      end

      @user = User.new(user_params)
      @user.email_address = @invite.email

      if @user.save
        AcceptInvite.new(invite: @invite, user: @user).call
        start_new_session_for(@user)
        redirect_to app_root_path, notice: "Welcome! You've joined the team."
      else
        render :show, status: :unprocessable_content
      end
    end

    private

      def set_invite
        @invite = Invite.find_by!(token: params[:invite_token])
      end

      def user_params
        params.require(:user).permit(
          :first_name, :last_name, :phone,
          :password, :password_confirmation
        )
      end

      def require_authentication_for_existing_users
        return if Current.user
        return unless User.exists?(email_address: @invite.email)

        require_authentication
      end
    end
  end
end
