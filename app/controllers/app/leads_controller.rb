module App
  class LeadsController < App::BaseController
    def index
      base = authorized_scope(Lead.all)
      base = base.includes(:listing, :lead_agents, :agents)
      base = base.by_status(params[:status]) if params[:status].present?
      @pagy, @leads = pagy(base.order(created_at: :desc))
      @unread_count = authorized_scope(Lead.all).unread.count
    end

    def show
      @lead = Current.account.leads.find(params[:id])
      authorize! @lead
    end

    def update
      @lead = Current.account.leads.find(params[:id])
      authorize! @lead
      if @lead.update(lead_params)
        redirect_to @lead, notice: "Lead updated."
      else
        render :show, status: :unprocessable_content
      end
    end

    private

      def lead_params
        params.require(:lead).permit(:status)
      end
  end
end
