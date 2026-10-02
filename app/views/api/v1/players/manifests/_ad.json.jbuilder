json.pid ad.public_id
json.updated_at ad.updated_at.to_i
json.headline ad.headline
json.body ad.body
json.layout ad.layout
json.theme ad.theme

json.images ad.image.attached? ? [ ad.image_attachment ] : [] do |attachment|
  json.id attachment.id
  json.url rails_storage_proxy_url(attachment)
  json.created_at attachment.created_at.to_i
end

json.adable do
  json.type ad.adable_type
  json.partial! "api/v1/players/manifests/#{ad.adable_type.underscore}",
    ad.adable_type.demodulize.underscore.to_sym => ad.adable
end
