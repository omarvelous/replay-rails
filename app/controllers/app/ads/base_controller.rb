module App
  module Ads
    class BaseController < App::BaseController
      before_action :set_ad, only: %i[edit update]

      def new
        set_adable(adable_class.new)
        @ad = @adable.build_ad({ account: Current.account }.merge(ad_defaults))
        @ad.apply_defaults
        authorize! @ad
        load_form_data
      end

      def create
        set_adable(adable_class.new(adable_params))
        @ad = @adable.build_ad(ad_params.merge(account: Current.account).merge(ad_defaults))
        authorize! @ad

        if @ad.valid? & @adable.valid?
          @adable.save!
          redirect_to @ad, notice: t(".success")
        else
          load_form_data
          render :new, status: :unprocessable_entity
        end
      end

      def edit
        authorize! @ad
        set_adable(@ad.adable)
        load_form_data
      end

      def update
        authorize! @ad
        set_adable(@ad.adable)
        @adable.assign_attributes(adable_params)
        @ad.assign_attributes(ad_params.merge(ad_defaults))

        if @ad.valid? & @adable.valid?
          @adable.save!
          @ad.save!
          redirect_to @ad, notice: t(".success")
        else
          load_form_data
          render :edit, status: :unprocessable_entity
        end
      end

      private

        def set_ad
          @ad = Current.account.ads.find_by_param!(params[:id])
        end

        def ad_params
          params.require(:ad).permit(:headline, :body, :layout, :theme, :image)
        end

        def set_adable(adable)
          @adable = adable
          # Set typed ivar for views (e.g., @listing_ad, @agent_ad)
          instance_variable_set(:"@#{adable_class.model_name.element}", adable)
        end

        # Override in subclasses
        def adable_class = raise(NotImplementedError)
        def adable_params = ActionController::Parameters.new.permit
        def ad_defaults = {}
        def load_form_data = nil
    end
  end
end
