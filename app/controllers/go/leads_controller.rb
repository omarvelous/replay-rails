module Go
  class LeadsController < ApplicationController
    include HoneypotProtection

    skip_before_action :require_authentication
    rate_limit to: 10, within: 1.hour, only: :create, by: -> { request.remote_ip }

    def create
      return head(:ok) if honeypot_triggered?

      result = CaptureLead.new(
        params: lead_params.except(:website),
        request_context: {
          source_url: request.referer,
          ip_address: request.remote_ip,
          user_agent: request.user_agent
        }
      ).call

      if result.success?
        redirect_back_or_to marketing_root_path, flash: { submitted: true }
      elsif result.lead
        redirect_back_or_to marketing_root_path,
                            alert: result.lead.errors.full_messages.to_sentence
      else
        head :unprocessable_content
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
