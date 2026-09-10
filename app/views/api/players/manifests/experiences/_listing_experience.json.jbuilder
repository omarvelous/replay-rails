json.id listing_experience.id
json.updated_at listing_experience.updated_at.to_i

json.listing do
  json.partial! "api/players/manifests/listing", listing: listing_experience.listing
end

if listing_experience.agent
  json.agent do
    json.partial! "api/players/manifests/agent", agent: listing_experience.agent
  end
end
