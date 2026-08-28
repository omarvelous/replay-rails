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
      @user = authorized_scope(User.all).find(params[:id])
      authorize! @user
      @roles = @user.account_users.where(account: Current.account)
      @agent_profile = @user.agent_profile
    end
  end
end
