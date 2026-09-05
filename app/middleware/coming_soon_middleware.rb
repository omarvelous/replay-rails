class ComingSoonMiddleware
  ALLOWED_PATHS = [ "/up" ].freeze

  def initialize(app)
    @app = app
  end

  def call(env)
    if !enabled? || allowed?(env)
      @app.call(env)
    else
      [ 200, { "content-type" => "text/html; charset=utf-8" }, [ html ] ]
    end
  end

  private

    def enabled?
      ENV["COMING_SOON"] == "true"
    end

    def allowed?(env)
      ALLOWED_PATHS.include?(env["PATH_INFO"])
    end

    def html
      @html ||= File.read(File.join(__dir__, "coming_soon.html"))
    end
end
