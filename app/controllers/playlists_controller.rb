class PlaylistsController < ApplicationController
  before_action :set_playlist, only: %i[ show edit update destroy preview screens ]

  def index
    @playlists = Current.account.playlists.order(created_at: :desc)
  end

  def show
  end

  def new
    @playlist = Current.account.playlists.build(status: "draft")
  end

  def create
    @playlist = Current.account.playlists.build(playlist_params)

    if @playlist.save
      redirect_to @playlist, notice: t(".success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @playlist.update(playlist_params)
      redirect_to @playlist, notice: t(".success")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def preview
    @playlist_ads = @playlist.playlist_ads.includes(ad: { listing: { listing_agents: :agent } })
    render layout: "preview"
  end

  def screens
    @screen_playlists = @playlist.screen_playlists.includes(screen: :site).where(active: true)
  end

  def destroy
    @playlist.destroy
    redirect_to playlists_path, notice: t(".success")
  end

  private

    def set_playlist
      @playlist = Current.account.playlists.find(params[:id])
    end

    def playlist_params
      params.require(:playlist).permit(:name, :status)
    end
end
