module Go
  class LeadsController < ApplicationController
    skip_before_action :require_authentication

    def create
      if lead_params[:website].present?
        head :ok
        return
      end

      listing = Listing.find_signed(lead_params[:listing_sid], purpose: :lead_form)
      agent = Agent.find_signed(lead_params[:agent_sid], purpose: :lead_form) || listing&.primary_agent
      account = listing&.account || agent&.account

      if account.nil?
        head :unprocessable_content
        return
      end

      @lead = Lead.new(lead_params.except(:listing_sid, :agent_sid, :website))
      @lead.listing = listing
      @lead.account = account
      @lead.context = {
        source_url: request.referer,
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      }

      if @lead.save
        @lead.lead_agents.create!(agent: agent) if agent
        LeadMailer.new_lead(@lead).deliver_later
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
          :listing_sid, :agent_sid, :website
        )
      end
  end
end
