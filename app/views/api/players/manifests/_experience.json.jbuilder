json.id experience.id
json.updated_at experience.updated_at.to_i
json.config experience.config

json.experienceable do
  json.type experience.experienceable_type
  json.id experience.experienceable_id
  json.updated_at experience.experienceable.updated_at.to_i

  listing = experience.listing
  if listing
    json.partial! "api/players/manifests/listing", listing: listing
  end

  agent = experience.default_agent
  if agent
    json.partial! "api/players/manifests/agent", agent: agent
  end
end
