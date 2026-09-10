json.id agent_ad.id
json.updated_at agent_ad.updated_at.to_i

json.partial! "api/players/manifests/agent", agent: agent_ad.agent
