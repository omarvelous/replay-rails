require "pundit/matchers"

Pundit::Matchers.configure do |config|
  config.default_user_alias = :account_user
end
