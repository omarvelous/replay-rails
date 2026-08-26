module Marketing
  class BaseController < ApplicationController
    allow_unauthenticated_access
    layout "marketing"
  end
end
