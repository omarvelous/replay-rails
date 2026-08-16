Capybara.register_driver :headless_chrome_custom do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--window-size=1280,800")

  if ENV["SELENIUM_URL"]
    Capybara::Selenium::Driver.new(
      app,
      browser: :remote,
      url: ENV["SELENIUM_URL"],
      options: options
    )
  else
    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  end
end

if ENV["SELENIUM_URL"]
  Capybara.server_host = "0.0.0.0"
  Capybara.app_host = "http://app.#{ENV.fetch("WEB_HOST", "web")}:#{Capybara.server_port}"
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :headless_chrome_custom
  end
end
