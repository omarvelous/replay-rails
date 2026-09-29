module App
  class SettingsController < BaseController
    def show
      @account = Current.account
      authorize! @account, to: :show?, with: SettingsPolicy
    end

    def update
      @account = Current.account
      authorize! @account, to: :update?, with: SettingsPolicy

      if @account.update(account_params)
        redirect_to settings_path, notice: t(".success")
      else
        render :show, status: :unprocessable_entity
      end
    end

    private

    def account_params
      params.require(:account).permit(:name)
    end
  end
end
