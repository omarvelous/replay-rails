module Analytics
  module Events
    class Base
      include ActiveModel::Model
      include ActiveModel::Attributes
      include ActiveModel::Validations

      class_attribute :event_name, instance_writer: false
      class_attribute :event_context, instance_writer: false

      attr_accessor :request

      def create
        return false unless valid?
        emit
        true
      end

      def create!
        raise ActiveModel::ValidationError, self unless valid?
        emit
        true
      end

      def self.create(attributes = {})
        event = new(attributes)
        event.create
        event
      end

      def self.create!(attributes = {})
        event = new(attributes)
        event.create!
        event
      end

      private

      def emit
        tracker = if request
                    controller = request.env["action_controller.instance"]
                    controller&.ahoy || Ahoy::Tracker.new(request: request)
                  else
                    Ahoy::Tracker.new
                  end

        tracker.track(self.class.event_name, properties)
      end

      def properties
        self.class.attribute_names
            .index_with { |attr| send(attr) }
            .compact
            .symbolize_keys
      end
    end
  end
end
