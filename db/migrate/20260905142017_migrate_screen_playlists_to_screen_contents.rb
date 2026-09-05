class MigrateScreenPlaylistsToScreenContents < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      INSERT INTO screen_contents (screen_id, contentable_type, contentable_id, active, created_at, updated_at)
      SELECT screen_id, 'Playlist', playlist_id, active, created_at, updated_at
      FROM screen_playlists
    SQL
  end

  def down
    execute "DELETE FROM screen_contents WHERE contentable_type = 'Playlist'"
  end
end
