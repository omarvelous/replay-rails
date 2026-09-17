module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user, :current_player

    def connect
      self.current_user = find_verified_user
      self.current_player = find_verified_player
    rescue
      # Allow anonymous connections — PairingChannel authenticates
      # via its own params
    end

    private

      def find_verified_user
        if session = Session.find_by(id: cookies.signed[:session_id])
          session.user
        end
      end

      def find_verified_player
        if token = cookies.signed[:player_token]
          Player.find_by(token: token)
        end
      end
  end
end
