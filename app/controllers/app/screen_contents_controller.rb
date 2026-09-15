module App
  class ScreenContentsController < BaseController
    before_action :set_screen

    ALLOWED_CONTENT_TYPES = %w[Playlist Experience].freeze

    def new
      authorize! ScreenContent
      @playlists = Current.account.playlists.where(status: "published").order(:name)
      @experiences = Current.account.experiences.order(:name)
    end

    def create
      authorize! ScreenContent

      type = screen_content_params[:contentable_type]
      raise ActionController::BadRequest, "Invalid content type" unless type.in?(ALLOWED_CONTENT_TYPES)

      scope = type == "Playlist" ? Current.account.playlists : Current.account.experiences
      contentable = scope.find_by_param!(screen_content_params[:contentable_id])
      authorize! contentable, to: :show?

      @screen.screen_contents.destroy_all
      @screen.screen_contents.create!(contentable: contentable, active: true)
      redirect_to @screen, notice: "Content updated."
    end

    def destroy
      authorize! ScreenContent
      @screen.screen_contents.destroy_all
      redirect_to @screen, notice: "Content removed."
    end

    private

      def set_screen
        @screen = Current.account.screens.find_by_param!(params[:screen_id])
      end

      def screen_content_params
        params.require(:screen_content).permit(:contentable_type, :contentable_id)
      end
  end
end
