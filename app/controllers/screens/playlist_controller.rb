module Screens
  class PlaylistController < ApplicationController
    before_action :set_screen

    def new
      @playlists = Current.account.playlists.where(status: "published").order(:name)
    end

    def create
      @screen.screen_playlists.destroy_all
      playlist = Current.account.playlists.find(params[:screen_playlist][:playlist_id])
      @screen.screen_playlists.create!(playlist: playlist, active: true)
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = "Playlist assigned to screen." }
        format.html { redirect_to screen_path(@screen), notice: "Playlist assigned to screen." }
      end
    end

    def destroy
      @screen.screen_playlists.destroy_all
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = "Playlist removed from screen."
          render "screens/playlist/create"
        end
        format.html { redirect_to screen_path(@screen), notice: "Playlist removed from screen." }
      end
    end

    private

      def set_screen
        @screen = Current.account.screens.find(params[:screen_id])
        @site = @screen.site
      end
  end
end
