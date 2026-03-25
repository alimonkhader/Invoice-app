class UserPolicy < ApplicationPolicy
  def admin_accounts?
    admin?
  end

  def manage_settings?
    account_admin? && user == record
  end
end
