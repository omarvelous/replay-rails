module App
  class InvitesController < App::BaseController
    allow_unauthenticated_access only: %i[show update]
    before_action :set_invite, only: %i[show update destroy]
    before_action :require_authentication_for_existing_users, only: :show

    # GET /invites
    def index
      @invites = authorized_scope(Invite.all).order(created_at: :desc)
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
        redirect_to invites_path, notice: "Invite sent to #{@invite.email}."
      else
        render :new, status: :unprocessable_content
      end
    end

    # GET /invites/:token — accept page
    def show
      authorize! @invite

      if @invite.expired?
        render :expired, layout: "public"
        return
      end

      if @invite.accepted?
        redirect_to app_root_path, notice: "This invite has already been accepted."
        return
      end

      if Current.user
        @invite.accept!(Current.user)
        redirect_to app_root_path, notice: "You've joined the team."
        return
      end

      @user = User.new
    end

    # PATCH /invites/:token — register + accept
    def update
      authorize! @invite

      if @invite.expired? || @invite.accepted?
        redirect_to app_root_path, alert: "This invite is no longer valid."
        return
      end

      @user = User.new(user_params)
      @user.email_address = @invite.email

      if @user.save
        @invite.accept!(@user)
        start_new_session_for(@user)
        redirect_to app_root_path, notice: "Welcome! You've joined the team."
      else
        render :show, status: :unprocessable_content
      end
    end

    # DELETE /invites/:token
    def destroy
      authorize! @invite
      @invite.destroy
      redirect_to invites_path, notice: "Invite revoked."
    end

    private

    def set_invite
      @invite = Invite.find_by!(token: params[:token])
    end

    def require_authentication_for_existing_users
      return if Current.user
      return unless User.exists?(email_address: @invite.email)

      require_authentication
    end

    def invite_params
      permitted = params.require(:invite).permit(:email, :invited_role)
      permitted[:role] = permitted.delete(:invited_role) if permitted[:invited_role]
      permitted
    end

    def user_params
      params.require(:user).permit(
        :first_name, :last_name, :phone,
        :password, :password_confirmation
      )
    end
  end
end
