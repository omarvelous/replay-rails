class ScreenPlaylistsController < ApplicationController
  before_action :set_screen

  def show
    @screen_playlist = @screen.screen_playlists.includes(playlist: { playlist_ads: :ad }).find_by(active: true)
  end

  def new
    @playlists = Current.account.playlists.where(status: "published").order(:name)
  end

  def create
    @screen.screen_playlists.destroy_all
    playlist = Current.account.playlists.find(params[:screen_playlist][:playlist_id])
    @screen.screen_playlists.create!(playlist: playlist, active: true)
    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = t(".success") }
      format.html { redirect_to @screen, notice: t(".success") }
    end
  end

  def destroy
    @screen.screen_playlists.destroy_all
    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = t(".success") }
      format.html { redirect_to @screen, notice: t(".success") }
    end
  end

  private

    def set_screen
      @screen = Current.account.screens.find(params[:screen_id])
    end
end
