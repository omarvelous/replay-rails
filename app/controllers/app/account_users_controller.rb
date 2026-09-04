module App
  class AccountUsersController < App::BaseController
    before_action :set_user
    before_action :set_account_user, only: :destroy

    def index
      authorize! AccountUser
      @account_users = @user.account_users.where(account: Current.account)
      @available_roles = AccountUser::ROLES - @account_users.pluck(:role)
    end

    def create
      @account_user = Current.account.account_users.build(
        user: @user,
        role: params.dig(:account_user, :role)
      )
      authorize! @account_user

      if @account_user.save
        redirect_to user_account_users_path(@user), notice: "Role added."
      else
        @account_users = @user.account_users.where(account: Current.account)
        @available_roles = AccountUser::ROLES - @account_users.pluck(:role)
        render :index, status: :unprocessable_entity
      end
    end

    def destroy
      authorize! @account_user
      if @account_user.destroy
        redirect_to user_account_users_path(@user), notice: "Role removed."
      else
        redirect_to user_account_users_path(@user), alert: @account_user.errors.full_messages.to_sentence
      end
    end

    private

      def set_user
        @user = authorized_scope(User.all).find(params[:user_id])
      end

      def set_account_user
        @account_user = @user.account_users.where(account: Current.account).find(params[:id])
      end
  end
end
