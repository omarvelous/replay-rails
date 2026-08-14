class ScreenPlayersController < ApplicationController
  before_action :set_screen

  def new
  end

  def create
    player = Player.find_by(pairing_code: params[:code]&.strip&.upcase)

    if player.nil?
      flash[:alert] = "Code not found. Check the TV and try again."
      return redirect_to new_screen_screen_player_path(@screen)
    end

    unless player.pairing_code_valid?
      flash[:alert] = "That code has expired. Restart the device to get a new one."
      return redirect_to new_screen_screen_player_path(@screen)
    end

    @screen.pair_player!(player, paired_by: Current.user)
    redirect_to @screen, notice: "Player paired successfully."
  end

  def destroy
    @screen.unpair_player!
    redirect_to @screen, notice: "Player unpaired."
  end

  private

    def set_screen
      @screen = Current.account.screens.find(params[:screen_id])
    end
end
