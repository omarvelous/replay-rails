module Screens
  class PlaylistController < ApplicationController
    before_action :set_site
    before_action :set_screen

    def new
      @playlists = current_account.playlists.where(status: "published").order(:name)
    end

    def create
      @screen.screen_playlists.destroy_all
      playlist = current_account.playlists.find(params[:screen_playlist][:playlist_id])
      @screen.screen_playlists.create!(playlist: playlist, active: true)
      respond_to do |format|
        format.turbo_stream { flash.now[:notice] = "Playlist assigned to screen." }
        format.html { redirect_to site_screen_path(@site, @screen), notice: "Playlist assigned to screen." }
      end
    end

    def destroy
      @screen.screen_playlists.destroy_all
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = "Playlist removed from screen."
          render "screens/playlist/create"
        end
        format.html { redirect_to site_screen_path(@site, @screen), notice: "Playlist removed from screen." }
      end
    end

    private

      def current_account
        Current.user.account
      end

      def set_site
        @site = current_account.sites.find(params[:site_id])
      end

      def set_screen
        @screen = @site.screens.find(params[:screen_id])
      end
  end
end
