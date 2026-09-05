module Marketing
  class InquiriesController < BaseController
    def create
      # Honeypot — reject if filled but pretend success
      if params[:website].present?
        redirect_to demo_path, notice: "Thanks! We'll be in touch within 24 hours."
        return
      end

      @inquiry = Inquiry.new(inquiry_params)

      if @inquiry.save
        InquiryMailer.notification(@inquiry).deliver_later
        redirect_to demo_path, notice: "Thanks! We'll be in touch within 24 hours."
      else
        render "marketing/pages/demo", status: :unprocessable_content
      end
    end

    private

      def inquiry_params
        params.require(:inquiry).permit(:name, :email, :phone, :company, :inquiry_type, :interest, :message)
      end
  end
end
