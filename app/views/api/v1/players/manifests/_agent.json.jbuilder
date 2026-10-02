json.pid agent.public_id
json.updated_at agent.updated_at.to_i
json.name agent.name
json.email agent.email
json.phone agent.phone
json.bio agent.bio

json.photos agent.photo.attached? ? [ agent.photo_attachment ] : [] do |attachment|
  json.id attachment.id
  json.url rails_storage_proxy_url(attachment)
  json.created_at attachment.created_at.to_i
end
