class ApplicationController < ActionController::Base
  helper_method :admin_authenticated?, :current_admin, :account_authenticated?, :current_account_user, :portal_authenticated?

  private

  def current_admin
    @current_admin ||= User.admins.find_by(id: session[:admin_id]) if session[:admin_id].present?
  end

  def admin_authenticated?
    current_admin.present?
  end

  def current_account_user
    return nil unless user_signed_in?
    return nil unless current_user.account_admin?
    return nil unless current_user.active?

    current_user
  end

  def account_authenticated?
    current_account_user.present?
  end

  def portal_authenticated?
    admin_authenticated? || account_authenticated?
  end

  def require_admin_authentication
    return if admin_authenticated?

    redirect_to admin_login_path, alert: "Please log in as admin to continue."
  end

  def require_account_authentication
    return if account_authenticated?

    redirect_to login_path, alert: "Please log in as an account user to continue."
  end

  def require_portal_authentication
    return if portal_authenticated?

    redirect_to login_path, alert: "Please log in to continue."
  end

  def require_excel_reports_access
    return if current_account_user&.excel_reports_enabled?

    redirect_to purchase_reports_path(month: params[:month]), alert: "Your current plan does not include XLSX report export."
  end
end
