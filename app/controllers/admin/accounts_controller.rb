module Admin
  class AccountsController < BaseController
    def index
      authorize User, :admin_accounts?
      @accounts = User.account_admins.includes(:plan_purchases)
    end
  end
end
