class PlanPurchasePolicy < ApplicationPolicy
  def index?
    account_admin?
  end

  def show?
    owns_record?
  end

  def verify?
    owns_record?
  end

  def download_invoice?
    owns_record?
  end

  private

  def owns_record?
    account_admin? && record.user_id == user.id
  end
end
