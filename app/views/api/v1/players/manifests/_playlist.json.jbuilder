json.pid playlist.public_id
json.updated_at playlist.updated_at.to_i
json.status playlist.status

playlist_ads = playlist.playlist_ads.includes(ad: [ :adable, :image_attachment ]).to_a

# Preload nested associations for ListingAd adables to avoid N+1
listing_ads = playlist_ads.map { |pa| pa.ad.adable }.select { |a| a.is_a?(Ads::ListingAd) }
if listing_ads.any?
  ActiveRecord::Associations::Preloader.new(
    records: listing_ads,
    associations: { listing: [ :photos_attachments, :floor_plans_attachments, :qr_codes ] }
  ).call
end

json.playlist_ads playlist_ads do |pa|
  json.partial! "api/v1/players/manifests/playlist_ad", playlist_ad: pa
end
