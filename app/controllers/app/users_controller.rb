module App
  class UsersController < App::BaseController
    def index
      authorize! User
      @pagy, @users = pagy(
        authorized_scope(User.all)
          .includes(:account_users)
          .order(:first_name)
      )
    end

    def show
      @user = authorized_scope(User.all).find_by_param!(params[:id])
      authorize! @user
      @roles = @user.account_users.where(account: Current.account)
      @agent_profile = @user.agent_profile
    end

    def edit
      @user = find_user_for_edit
      authorize! @user
    end

    def update
      @user = find_user_for_edit
      authorize! @user

      if @user.update(user_params)
        redirect_to user_path(@user), notice: t(".success")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def find_user_for_edit
      user = authorized_scope(User.all).find_by_param!(params[:id])
      authorize! user, to: :edit?
      user
    end

    def user_params
      permitted = params.require(:user).permit(
        :first_name, :last_name, :email_address, :phone,
        :password, :password_confirmation
      )
      permitted.delete(:password) if permitted[:password].blank?
      permitted.delete(:password_confirmation) if permitted[:password_confirmation].blank?
      permitted
    end
  end
end
