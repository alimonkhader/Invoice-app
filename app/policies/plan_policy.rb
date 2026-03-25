class PlanPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def edit?
    update?
  end

  def register?
    return false unless account_admin? || user.nil?
    return true if user.nil?
    return false unless user.active?
    return true if user.plan.blank?
    return true if record.price.to_i >= user.plan.price.to_i
    return true if user.plan.price.to_i.zero?
    return true if user.expires_on.blank?

    user.expires_on <= (Date.current + RegistrationsController::RENEWAL_NOTICE_DAYS)
  end
end
