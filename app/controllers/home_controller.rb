class HomeController < ApplicationController
  RENEWAL_NOTICE_DAYS = 7

  def index
    @feature_groups = [
      {
        title: "Fast invoice workflow",
        description: "Create invoices quickly, add items, send PDF, and share on WhatsApp."
      },
      {
        title: "Purchase reporting",
        description: "Track daily and monthly purchase totals with GST, CGST, and SGST visibility."
      },
      {
        title: "Plan-based onboarding",
        description: "Offer Trial, Basic, and Premium plans with account registration and admin management."
      }
    ]

    @current_plan_user = current_account_user if account_authenticated?
    @show_account_plan_options = account_plan_options_visible?
    @plans = visible_plans
  end

  private

  def visible_plans
    return Plan.none if admin_authenticated?
    return Plan.active_first unless account_authenticated?
    return Plan.none unless @show_account_plan_options
    return Plan.active_first if @current_plan_user&.plan.blank?

    Plan.active_first.where("price <= ?", @current_plan_user.plan.price)
  end

  def account_plan_options_visible?
    return false unless account_authenticated?
    return true if @current_plan_user&.plan.blank?
    return true if @current_plan_user.plan.price.to_i.zero?
    return true if @current_plan_user.expires_on.blank?

    @current_plan_user.expires_on <= (Date.current + RENEWAL_NOTICE_DAYS)
  end
end
