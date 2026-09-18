module App
  class AccountUsersController < App::BaseController
    before_action :set_user
    before_action :set_account_user, only: :destroy

    def index
      authorize! AccountUser
      @account_user = @user.membership_on(Current.account)
      @account_users = [ @account_user ].compact
      @available_roles = AccountUser::ROLES
    end

    def create
      @account_user = @user.membership_on(Current.account)
      authorize! @account_user

      if @account_user.update(role: params.dig(:account_user, :role))
        redirect_to user_roles_path(@user), notice: t(".success")
      else
        @account_users = [ @account_user ].compact
        @available_roles = AccountUser::ROLES
        render :index, status: :unprocessable_entity
      end
    end

    def destroy
      authorize! @account_user
      if @account_user.destroy
        redirect_to user_roles_path(@user), notice: t(".success")
      else
        redirect_to user_roles_path(@user), alert: @account_user.errors.full_messages.to_sentence
      end
    end

    private

      def set_user
        @user = authorized_scope(User.all).find_by_param!(params[:user_id])
      end

      def set_account_user
        @account_user = @user.account_users.where(account: Current.account).find_by_param!(params[:id])
      end
  end
end
