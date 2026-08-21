module App
  class LeadAgentsController < App::BaseController
    before_action :set_lead

    def create
      @lead.lead_agents.create!(lead_agent_params)
      redirect_to @lead, notice: "Agent assigned."
    end

    private

      def set_lead
        @lead = Current.account.leads.find(params[:lead_id])
      end

      def lead_agent_params
        params.require(:lead_agent).permit(:agent_id)
      end
  end
end
