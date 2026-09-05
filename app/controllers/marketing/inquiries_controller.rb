module Marketing
  class InquiriesController < BaseController
    def create
      # Honeypot — reject if filled but pretend success
      if params[:website].present?
        redirect_to redirect_path, notice: thanks_message
        return
      end

      @inquiry = Inquiry.new(inquiry_params)

      if @inquiry.save
        InquiryMailer.notification(@inquiry).deliver_later
        redirect_to redirect_path, notice: thanks_message
      else
        render failure_template, status: :unprocessable_content
      end
    end

    private

      def inquiry_params
        params.require(:inquiry).permit(:name, :email, :phone, :company, :inquiry_type, :interest, :message)
      end

      def general?
        inquiry_params[:inquiry_type] == "general"
      end

      def redirect_path
        general? ? contact_path : demo_path
      end

      def failure_template
        general? ? "marketing/pages/contact" : "marketing/pages/demo"
      end

      def thanks_message
        general? ? "Thanks for reaching out! We'll get back to you soon." : "Thanks! We'll be in touch within 24 hours."
      end
  end
end
