module App
  class ScreenPlaylistsController < BaseController
  before_action :set_screen

  def new
    authorize! ScreenPlaylist
    @playlists = Current.account.playlists.where(status: "published").order(:name)
  end

  def create
    authorize! ScreenPlaylist
    @screen.screen_playlists.destroy_all
    playlist = Current.account.playlists.find(params[:screen_playlist][:playlist_id])
    @screen.screen_playlists.create!(playlist: playlist, active: true)
    redirect_to @screen, notice: t(".success")
  end

  def destroy
    authorize! ScreenPlaylist
    @screen.screen_playlists.destroy_all
    redirect_to @screen, notice: t(".success")
  end

  private

    def set_screen
      @screen = Current.account.screens.find(params[:screen_id])
    end
  end
end
