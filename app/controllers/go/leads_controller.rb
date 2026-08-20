module Go
  class LeadsController < ApplicationController
    skip_before_action :require_authentication

    def create
      listing = Listing.find_by(id: lead_params[:listing_id])
      agent = Agent.find_by(id: lead_params[:agent_id]) || listing&.primary_agent
      account = listing&.account || agent&.account

      if account.nil?
        head :unprocessable_content
        return
      end

      @lead = Lead.new(lead_params.except(:listing_id, :agent_id, :scan_id))
      @lead.account = account
      @lead.qr_scan = QrScan.find_by(id: lead_params[:scan_id])
      @lead.context = {
        listing_id: listing&.id,
        source_url: request.referer,
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      }

      if @lead.save
        @lead.lead_agents.create!(agent: agent) if agent
        redirect_back_or_to marketing_root_path, flash: { submitted: true }
      else
        redirect_back_or_to marketing_root_path,
                            alert: @lead.errors.full_messages.to_sentence
      end
    end

    private

      def lead_params
        params.require(:lead).permit(
          :name, :email, :phone, :message, :lead_type,
          :listing_id, :agent_id, :scan_id
        )
      end
  end
end
