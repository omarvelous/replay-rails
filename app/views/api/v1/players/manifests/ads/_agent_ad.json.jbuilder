json.pid agent_ad.public_id
json.updated_at agent_ad.updated_at.to_i

json.agent do
  json.partial! "api/v1/players/manifests/agent", agent: agent_ad.agent
end
