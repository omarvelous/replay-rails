json.id listing_ad.id
json.updated_at listing_ad.updated_at.to_i

json.partial! "api/players/manifests/listing", listing: listing_ad.listing
