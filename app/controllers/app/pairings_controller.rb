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

      screen = @screens.find_by(id: params[:screen_id])
      unless screen
        flash.now[:alert] = "Please select a screen."
        return render :show, status: :unprocessable_content
      end

      player = Player.find_by(pairing_code: @code)
      unless player
        flash.now[:alert] = "Invalid pairing code. Check the code on the screen and try again."
        return render :show, status: :unprocessable_content
      end

      unless player.pairing_code_valid?
        flash.now[:alert] = "Pairing code has expired. A new code should appear on the screen shortly."
        return render :show, status: :unprocessable_content
      end

      screen.pair_player!(player, paired_by: Current.user)
      redirect_to screen_path(screen), notice: "Player paired successfully."
    end
  end
end
