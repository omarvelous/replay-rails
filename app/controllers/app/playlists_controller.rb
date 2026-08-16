module App
  class PlaylistsController < BaseController
  before_action :set_playlist, only: %i[ show edit update destroy preview ]

  def index
    base = Current.account.playlists
    base = base.search(params[:q]) if params[:q].present?
    base = base.by_status(params[:status]) if params[:status].present?
    @pagy, @playlists = pagy(base.order(created_at: :desc))
  end

  def show
    @playlist_ads = @playlist.playlist_ads.includes(:ad).order(:position)
    @screen_playlists = @playlist.screen_playlists.includes(screen: :site).where(active: true)
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
    @playlist_ads = @playlist.playlist_ads.includes(:ad).order(:position)
  end

  def update
    if @playlist.update(playlist_params)
      redirect_to @playlist, notice: t(".success")
    else
      @playlist_ads = @playlist.playlist_ads.includes(:ad).order(:position)
      render :edit, status: :unprocessable_entity
    end
  end

  def preview
    @playlist_ads = @playlist.playlist_ads.includes(:ad)
    render layout: "preview"
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
end
