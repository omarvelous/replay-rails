module App
  class PairingsController < App::BaseController
    # GET /pair
    def show
      @screens = authorized_scope(Screen.all).order(:name)
      @code = params[:code]
    end

    # POST /pair
    def create
      @screens = authorized_scope(Screen.all).order(:name)
      @code = params[:code]

      screen = @screens.find_by_param!(params[:screen_id])
      authorize! screen, to: :update?

      result = PairPlayerToScreen.new(
        screen: screen,
        code: @code,
        paired_by: Current.user
      ).call

      if result.success?
        redirect_to screen_path(screen), notice: "Player paired successfully."
      else
        flash.now[:alert] = result.error
        render :show, status: :unprocessable_content
      end
    end
  end
end
