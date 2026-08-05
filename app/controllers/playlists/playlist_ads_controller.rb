module Playlists
  class PlaylistAdsController < ::PlaylistAdsController
    private

      def parent
        @parent ||= Current.account.playlists.find(params[:playlist_id])
      end

      def next_position
        (parent.playlist_ads.maximum(:position) || 0) + 1
      end
  end
end
