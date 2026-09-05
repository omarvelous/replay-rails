module App
  class ExperiencesController < BaseController
    before_action :set_experience, only: %i[show edit update destroy]

    def index
      @experiences = authorized_scope(Experience.all).order(created_at: :desc)
    end

    def show
      authorize! @experience
    end

    def new
      listing_exp = Experiences::ListingExperience.new
      listing_exp.listing_id = params[:listing_id] if params[:listing_id]
      @experience = Current.account.experiences.build(experienceable: listing_exp)
      authorize! @experience
    end

    def create
      listing_exp = Experiences::ListingExperience.new(listing_experience_params)
      @experience = Current.account.experiences.build(
        name: params[:experience][:name],
        config: params[:experience][:config] || {},
        experienceable: listing_exp
      )
      authorize! @experience

      if @experience.save
        redirect_to @experience, notice: "Experience created."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      authorize! @experience
    end

    def update
      authorize! @experience
      if @experience.update(experience_params)
        redirect_to @experience, notice: "Experience updated."
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      authorize! @experience
      @experience.destroy
      redirect_to experiences_path, notice: "Experience deleted."
    end

    private

      def set_experience
        @experience = Current.account.experiences.find(params[:id])
      end

      def experience_params
        params.require(:experience).permit(:name, config: {})
      end

      def listing_experience_params
        params.require(:experience).permit(:listing_id, :agent_id)
      end
  end
end
