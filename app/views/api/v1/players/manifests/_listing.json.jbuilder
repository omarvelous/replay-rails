json.pid listing.public_id
json.updated_at listing.updated_at.to_i
json.address listing.address
json.price listing.price.to_f
json.beds listing.beds
json.baths listing.baths
json.sqft listing.sqft
json.property_type listing.property_type
json.listing_type listing.listing_type
json.status listing.status

json.photos listing.photos_attachments do |attachment|
  json.id attachment.id
  json.url url_for(attachment)
  json.created_at attachment.created_at.to_i
end

json.floor_plans listing.floor_plans_attachments do |attachment|
  json.id attachment.id
  json.url url_for(attachment)
  json.created_at attachment.created_at.to_i
end

json.qr_codes listing.qr_codes do |qr_code|
  json.partial! "api/v1/players/manifests/qr_code", qr_code: qr_code
end
