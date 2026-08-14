module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    rescue
      # Allow anonymous connections — PairingChannel and ScreenChannel
      # authenticate via their own params
    end

    private

      def find_verified_user
        if session = Session.find_by(id: cookies.signed[:session_id])
          session.user
        else
          raise "Unauthorized"
        end
      end
  end
end
