module Playlists
  class PlaylistAdsController < ::PlaylistAdsController
    private

      def parent
        @parent ||= Current.account.playlists.find(params[:playlist_id])
      end
  end
end
