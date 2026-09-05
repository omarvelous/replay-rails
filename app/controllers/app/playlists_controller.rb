module App
  class PlaylistsController < BaseController
  before_action :set_playlist, only: %i[ show edit update destroy preview ]

  def index
    base = authorized_scope(Playlist.all)
    base = base.search(params[:q]) if params[:q].present?
    base = base.by_status(params[:status]) if params[:status].present?
    @pagy, @playlists = pagy(base.order(created_at: :desc))
  end

  def show
    authorize! @playlist
    @playlist_ads = @playlist.playlist_ads.includes(:ad).order(:position)
    @screen_contents = @playlist.screen_contents.includes(screen: :site).where(active: true)
  end

  def new
    @playlist = Current.account.playlists.build(status: "draft")
    authorize! @playlist
  end

  def create
    @playlist = Current.account.playlists.build(playlist_params)
    authorize! @playlist

    if @playlist.save
      redirect_to @playlist, notice: t(".success")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize! @playlist
    @playlist_ads = @playlist.playlist_ads.includes(:ad).order(:position)
  end

  def update
    authorize! @playlist
    if @playlist.update(playlist_params)
      redirect_to @playlist, notice: t(".success")
    else
      @playlist_ads = @playlist.playlist_ads.includes(:ad).order(:position)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize! @playlist
    @playlist.destroy
    redirect_to playlists_path, notice: t(".success")
  end

  def preview
    authorize! @playlist, to: :show?
    @playlist_ads = @playlist.playlist_ads.includes(:ad)
    render layout: "preview"
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
