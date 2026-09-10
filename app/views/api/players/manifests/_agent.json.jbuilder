json.id agent.id
json.updated_at agent.updated_at.to_i

json.photos agent.photo.attached? ? [agent.photo_attachment] : [] do |attachment|
  json.id attachment.id
  json.created_at attachment.created_at.to_i
end
