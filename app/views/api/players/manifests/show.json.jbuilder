json.deploy ENV.fetch("REVISION", "dev")

json.screen_content do
  json.id @screen_content.id
  json.updated_at @screen_content.updated_at.to_i
end

json.contentable do
  json.type @screen_content.contentable_type
  json.id @screen_content.contentable_id
  json.partial! "api/players/manifests/#{@screen_content.contentable_type.underscore}",
    @screen_content.contentable_type.underscore.to_sym => @screen_content.contentable
end
