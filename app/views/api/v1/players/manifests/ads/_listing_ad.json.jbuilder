json.pid listing_ad.public_id
json.updated_at listing_ad.updated_at.to_i

json.listing do
  json.partial! "api/v1/players/manifests/listing", listing: listing_ad.listing
end

if listing_ad.listing.primary_agent
  json.agent do
    json.partial! "api/v1/players/manifests/agent", agent: listing_ad.listing.primary_agent
  end
end
