class ReportPolicy < ApplicationPolicy
  def purchases?
    account_admin?
  end

  def monthly_purchases_xlsx?
    account_admin?
  end
end
