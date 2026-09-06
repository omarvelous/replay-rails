module Admin
  module Ahoy
    class EventsController < Admin::ApplicationController
      def resource_class
        ::Ahoy::Event
      end
    end
  end
end
