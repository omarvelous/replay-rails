module App
  class ScreenContentsController < BaseController
    before_action :set_screen

    def new
      authorize! ScreenContent
      @playlists = Current.account.playlists.where(status: "published").order(:name)
      @experiences = Current.account.experiences.includes(experienceable: :listing).order(:name)
    end

    def create
      authorize! ScreenContent
      @screen.screen_contents.destroy_all
      @screen.screen_contents.create!(
        contentable_type: params[:screen_content][:contentable_type],
        contentable_id: params[:screen_content][:contentable_id],
        active: true
      )
      redirect_to @screen, notice: "Content updated."
    end

    def destroy
      authorize! ScreenContent
      @screen.screen_contents.destroy_all
      redirect_to @screen, notice: "Content removed."
    end

    private

      def set_screen
        @screen = Current.account.screens.find(params[:screen_id])
      end
  end
end
