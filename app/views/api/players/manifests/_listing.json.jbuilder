json.id listing.id
json.updated_at listing.updated_at.to_i

json.photos listing.photos_attachments do |attachment|
  json.id attachment.id
  json.created_at attachment.created_at.to_i
end

json.floor_plans listing.floor_plans_attachments do |attachment|
  json.id attachment.id
  json.created_at attachment.created_at.to_i
end

if listing.qr_code
  json.partial! "api/players/manifests/qr_code", qr_code: listing.qr_code
end
