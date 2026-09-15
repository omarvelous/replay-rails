module App
  class DashboardController < App::BaseController
    def show
      @dashboard = DashboardPresenter.new(account: Current.account)
    end
  end
end
