module App
  class AccountsController < BaseController
  allow_unauthenticated_access only: %i[ new create ]

  def new
    @account = Account.new
    @user    = User.new
  end

  def create
    @account = Account.new(account_params)
    @user    = User.new(user_params)

    if @user.valid? && @account.valid?
      ActiveRecord::Base.transaction do
        @account.save!
        @user.save!
        AccountUser.create!(account: @account, user: @user, role: "owner")
      end
      start_new_session_for @user
      redirect_to app_root_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

    def account_params
      params.fetch(:account, {}).permit
    end

    def user_params
      params.require(:user).permit(
        :first_name, :last_name, :email_address,
        :phone, :password, :password_confirmation
      )
    end
  end
end
