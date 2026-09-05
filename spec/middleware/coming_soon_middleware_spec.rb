require "rails_helper"

RSpec.describe ComingSoonMiddleware do
  let(:app) { ->(env) { [200, { "content-type" => "text/html" }, ["OK"]] } }
  let(:middleware) { described_class.new(app) }

  def env_for(path, method: "GET")
    Rack::MockRequest.env_for(path, method: method)
  end

  context "when COMING_SOON is true" do
    around do |example|
      original = ENV["COMING_SOON"]
      ENV["COMING_SOON"] = "true"
      example.run
    ensure
      ENV["COMING_SOON"] = original
    end

    it "serves the coming soon page" do
      status, headers, body = middleware.call(env_for("/"))
      expect(status).to eq(200)
      expect(body.first).to include("Coming Soon")
    end

    it "gates all paths" do
      %w[/ /features /pricing /about /demo /session/new].each do |path|
        _status, _headers, body = middleware.call(env_for(path))
        expect(body.first).to include("Coming Soon"), "Expected #{path} to be gated"
      end
    end

    it "allows the health check through" do
      status, _headers, body = middleware.call(env_for("/up"))
      expect(status).to eq(200)
      expect(body.first).to eq("OK")
    end
  end

  context "when COMING_SOON is not set" do
    around do |example|
      original = ENV["COMING_SOON"]
      ENV.delete("COMING_SOON")
      example.run
    ensure
      ENV["COMING_SOON"] = original if original
    end

    it "passes through to the app" do
      status, _headers, body = middleware.call(env_for("/"))
      expect(status).to eq(200)
      expect(body.first).to eq("OK")
    end
  end

  context "when COMING_SOON is false" do
    around do |example|
      original = ENV["COMING_SOON"]
      ENV["COMING_SOON"] = "false"
      example.run
    ensure
      ENV["COMING_SOON"] = original
    end

    it "passes through to the app" do
      status, _headers, body = middleware.call(env_for("/"))
      expect(body.first).to eq("OK")
    end
  end
end
