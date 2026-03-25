class InvoicePolicy < ApplicationPolicy
  def index?
    account_admin?
  end

  def show?
    owns_record?
  end

  def create?
    account_admin?
  end

  def update?
    owns_record?
  end

  def destroy?
    owns_record?
  end

  def send_email?
    owns_record?
  end

  def share_whatsapp?
    owns_record?
  end

  private

  def owns_record?
    account_admin? && record.user_id == user.id
  end
end
