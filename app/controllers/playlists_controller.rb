class PlaylistsController < ApplicationController
  before_action :set_playlist, only: %i[ show edit update destroy preview ]

  def index
    @playlists = current_account.playlists.order(created_at: :desc)
  end

  def show
  end

  def new
    @playlist = current_account.playlists.build(status: "draft")
  end

  def create
    @playlist = current_account.playlists.build(playlist_params)

    if @playlist.save
      redirect_to @playlist, notice: "Playlist was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @playlist.update(playlist_params)
      redirect_to @playlist, notice: "Playlist was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def preview
    @playlist_ads = @playlist.playlist_ads.includes(:ad)
    render layout: "preview"
  end

  def destroy
    @playlist.destroy
    redirect_to playlists_path, notice: "Playlist was successfully deleted."
  end

  private

    def current_account
      Current.user.account
    end

    def set_playlist
      @playlist = current_account.playlists.find(params[:id])
    end

    def playlist_params
      params.require(:playlist).permit(:name, :status)
    end
end
