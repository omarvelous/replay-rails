json.id listing_ad.id
json.updated_at listing_ad.updated_at.to_i

json.listing do
  json.partial! "api/players/manifests/listing", listing: listing_ad.listing
end

if listing_ad.listing.primary_agent
  json.agent do
    json.partial! "api/players/manifests/agent", agent: listing_ad.listing.primary_agent
  end
end
