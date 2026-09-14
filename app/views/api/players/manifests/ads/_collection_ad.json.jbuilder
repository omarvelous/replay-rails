json.pid collection_ad.public_id
json.updated_at collection_ad.updated_at.to_i

json.collection_ads collection_ad.collection_ad_ads.includes(:ad) do |caa|
  json.pid caa.public_id
  json.position caa.position
  json.partial! "api/players/manifests/ad", ad: caa.ad
end
