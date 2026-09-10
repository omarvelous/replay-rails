json.id playlist.id
json.updated_at playlist.updated_at.to_i
json.status playlist.status

json.playlist_ads playlist.playlist_ads.includes(ad: :adable) do |pa|
  json.partial! "api/players/manifests/playlist_ad", playlist_ad: pa
end
