module Go
  class BaseController < ApplicationController
    skip_before_action :require_authentication
    layout "public"
  end
end
