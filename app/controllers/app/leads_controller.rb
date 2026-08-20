module App
  class LeadsController < App::BaseController
    def index
      base = Current.account.leads.includes(:lead_agents, :agents)
      base = base.by_status(params[:status]) if params[:status].present?
      @pagy, @leads = pagy(base.order(created_at: :desc))
      @unread_count = Current.account.leads.unread.count
    end

    def show
      @lead = Current.account.leads.find(params[:id])
    end

    def update
      @lead = Current.account.leads.find(params[:id])
      @lead.update!(status: params[:lead][:status]) if params[:lead][:status].present?
      if params[:lead][:agent_id].present?
        @lead.lead_agents.create!(agent_id: params[:lead][:agent_id])
      end
      redirect_to @lead, notice: "Lead updated."
    end
  end
end
