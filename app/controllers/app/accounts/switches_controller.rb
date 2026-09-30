module App
  module Accounts
    class SwitchesController < App::BaseController
      def create
        accounts = authorized_scope(Account.all)
        account = accounts.find_by_param!(params[:account_id])
        session[:account_id] = account.id
        redirect_to app_root_path, notice: "Switched to #{account.name}"
      end
    end
  end
end
