module Admin
  module Ahoy
    class VisitsController < Admin::ApplicationController
      def resource_class
        ::Ahoy::Visit
      end
    end
  end
end
