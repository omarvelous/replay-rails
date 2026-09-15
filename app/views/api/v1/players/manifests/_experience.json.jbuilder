json.pid experience.public_id
json.updated_at experience.updated_at.to_i
json.config experience.config

json.experienceable do
  json.type experience.experienceable_type
  json.pid experience.experienceable.public_id
  json.updated_at experience.experienceable.updated_at.to_i
  json.partial! "api/v1/players/manifests/#{experience.experienceable_type.underscore}",
    experience.experienceable_type.demodulize.underscore.to_sym => experience.experienceable
end
