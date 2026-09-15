json.pid listing_experience.public_id
json.updated_at listing_experience.updated_at.to_i

json.listing do
  json.partial! "api/v1/players/manifests/listing", listing: listing_experience.listing
end

if listing_experience.agent
  json.agent do
    json.partial! "api/v1/players/manifests/agent", agent: listing_experience.agent
  end
end
