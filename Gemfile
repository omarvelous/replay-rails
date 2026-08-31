source "https://rubygems.org"

# ── Framework ─────────────────────────────────────────
gem "rails", "~> 8.1.3", ">= 8.1.3.1"
gem "propshaft"
gem "puma", ">= 5.0"

# ── Database ──────────────────────────────────────────
gem "pg", "~> 1.1"
gem "solid_cable"
gem "solid_cache"
gem "solid_queue"

# ── Frontend ──────────────────────────────────────────
gem "importmap-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "turbo-rails"

# ── Auth & Authorization ──────────────────────────────
gem "action_policy"
gem "acts_as_tenant"
gem "bcrypt", "~> 3.1"
gem "rack-attack"

# ── Content & Media ───────────────────────────────────
gem "chartkick"
gem "groupdate"
gem "aws-sdk-s3", require: false
gem "image_processing", "~> 2.0"
gem "pagy", "~> 43.6"
gem "paper_trail"
gem "positioning"
gem "rqrcode", "~> 3.2"
gem "ruby-vips", "~> 2.0"

# ── Admin ─────────────────────────────────────────────
gem "administrate"
gem "administrate-field-active_storage"

# ── API & Middleware ──────────────────────────────────
gem "jbuilder"
gem "rack-cors"

# ── Infrastructure ────────────────────────────────────
gem "bootsnap", require: false
gem "kamal", require: false
gem "psych", "~> 5.5"
gem "thruster", require: false
gem "tzinfo-data", platforms: %i[windows jruby]

group :development, :test do
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "factory_bot_rails"
  gem "faker"
  gem "rspec-rails", "~> 8.0"
  gem "rubocop-capybara", require: false
  gem "rubocop-factory_bot", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-rspec_rails", require: false
end

group :development do
  gem "letter_opener_web"
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "database_cleaner-active_record"
  gem "selenium-webdriver"
  gem "shoulda-matchers", "~> 8.0"
  gem "simplecov", require: false
end
