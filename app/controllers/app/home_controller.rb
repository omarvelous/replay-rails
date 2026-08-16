module App
  class HomeController < BaseController
  allow_unauthenticated_access only: [ :index ]

  def index
  end
end
end
