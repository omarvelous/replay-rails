json.qr_code do
  json.pid qr_code.public_id
  json.updated_at qr_code.updated_at.to_i
end
