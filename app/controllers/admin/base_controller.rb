module Admin
  class BaseController < ApplicationController
    before_action :require_admin_authentication
  end
end
