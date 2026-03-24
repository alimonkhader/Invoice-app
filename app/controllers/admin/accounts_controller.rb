module Admin
  class AccountsController < BaseController
    def index
      @accounts = User.account_admins.includes(:plan_purchases)
    end
  end
end
