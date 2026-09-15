module App
  class ScreenPlayersController < BaseController
  before_action :set_screen

  def new
    authorize! ScreenPlayer
  end

  def create
    authorize! ScreenPlayer

    result = PairPlayerToScreen.new(
      screen: @screen,
      code: params[:code],
      paired_by: Current.user
    ).call

    if result.success?
      redirect_to @screen, notice: t(".success")
    else
      flash[:alert] = result.error
      redirect_to new_screen_screen_player_path(@screen)
    end
  end

  def destroy
    authorize! ScreenPlayer
    @screen.unpair_player!
    redirect_to @screen, notice: t(".success")
  end

  private

    def set_screen
      @screen = Current.account.screens.find_by_param!(params[:screen_id])
    end
  end
end
