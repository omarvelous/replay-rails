module App
  class LeadAgentsController < App::BaseController
    before_action :set_lead

    def new
      @lead_agent = @lead.lead_agents.build
      authorize! @lead_agent
    end

    def create
      @lead_agent = @lead.lead_agents.build(lead_agent_params)
      authorize! @lead_agent
      @lead_agent.save!
      redirect_to @lead, notice: t(".success")
    end

    private

      def set_lead
        @lead = Current.account.leads.find_by_param!(params[:lead_id])
      end

      def lead_agent_params
        params.require(:lead_agent).permit(:agent_id)
      end
  end
end
