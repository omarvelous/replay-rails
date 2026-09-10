json.id playlist_ad.id
json.updated_at playlist_ad.updated_at.to_i
json.position playlist_ad.position
json.duration playlist_ad.duration

json.partial! "api/players/manifests/ad", ad: playlist_ad.ad
