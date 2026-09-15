module App
  class ScreenContentsController < BaseController
    before_action :set_screen

    def new
      authorize! ScreenContent
      @playlists = Current.account.playlists.where(status: "published").order(:name)
      @experiences = Current.account.experiences.order(:name)
    end

    def create
      contentable = find_contentable
      @screen_content = @screen.screen_contents.build(contentable: contentable, active: true)
      authorize! @screen_content

      AssignScreenContent.new(screen_content: @screen_content).call
      redirect_to @screen, notice: "Content updated."
    end

    def destroy
      authorize! ScreenContent
      @screen.screen_contents.where(active: true).update_all(active: false)
      redirect_to @screen, notice: "Content removed."
    end

    private

      def set_screen
        @screen = Current.account.screens.find_by_param!(params[:screen_id])
      end

      def screen_content_params
        params.require(:screen_content).permit(:contentable_type, :contentable_id)
      end

      def find_contentable
        type = screen_content_params[:contentable_type]
        raise ActiveRecord::RecordNotFound unless type.in?(ScreenContent.contentable_types)
        type.constantize.where(account: Current.account).find_by_param!(screen_content_params[:contentable_id])
      end
  end
end
