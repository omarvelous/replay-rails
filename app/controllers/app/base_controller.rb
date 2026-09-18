module App
  class BaseController < ApplicationController
    include ActionPolicy::Controller
    layout "app"

    authorize :user, through: :current_user
    authorize :account, through: :current_account
    authorize :account_user, through: :current_account_user

    rescue_from ActionPolicy::Unauthorized, with: :handle_unauthorized

    before_action :set_paper_trail_whodunnit

    private

      def current_user
        Current.user
      end

      def current_account
        Current.account
      end

      def current_account_user
        Current.account_user
      end

      def handle_unauthorized
        redirect_to app_root_path, alert: "You don't have permission to do that."
      end

      def user_for_paper_trail
        Current.user&.id
      end
  end
end
