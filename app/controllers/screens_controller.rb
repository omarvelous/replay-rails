class ScreensController < ApplicationController
  before_action :set_screen

  def show
  end

  def edit
  end

  def update
    if @screen.update(screen_params)
      redirect_to @screen, notice: "Screen was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    site = @screen.site
    @screen.destroy
    redirect_to site_path(site), notice: "Screen was successfully deleted."
  end

  private

    def current_account
      Current.user.account
    end

    def set_screen
      @screen = Screen.joins(:site).find_by!(id: params[:id], sites: { account_id: current_account.id })
      @site = @screen.site
    end

    def screen_params
      params.require(:screen).permit(:name, :orientation)
    end
end
