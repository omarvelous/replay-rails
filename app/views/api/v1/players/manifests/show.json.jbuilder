json.deploy ENV.fetch("REVISION", "dev")
json.account_pid @screen_content&.screen&.site&.account&.public_id
json.screen_pid @screen_content&.screen&.public_id

if @screen_content
  json.screen_content do
    json.pid @screen_content.public_id
    json.updated_at @screen_content.updated_at.to_i
  end

  json.contentable do
    json.type @screen_content.contentable_type
    json.pid @screen_content.contentable.public_id
    json.partial! "api/v1/players/manifests/#{@screen_content.contentable_type.underscore}",
      @screen_content.contentable_type.underscore.to_sym => @screen_content.contentable
  end
else
  json.screen_content nil
  json.contentable nil
end
