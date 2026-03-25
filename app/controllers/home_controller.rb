class HomeController < ApplicationController
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
        description: "Offer Trial, Basic, and Premium plans with account registration, renewal, upgrade, and admin management."
      }
    ]

    @current_plan_user = current_account_user if account_authenticated?
    @show_account_plan_options = account_authenticated?
    @plans = visible_plans
  end

  private

  def visible_plans
    return Plan.none if admin_authenticated?
    return Plan.active_first unless account_authenticated?
    return Plan.active_first if @current_plan_user&.plan.blank?

    current_price = @current_plan_user.plan.price.to_i
    Plan.active_first.select do |plan|
      plan.price.to_i >= current_price || current_plan_downgrade_window_open?
    end
  end

  def current_plan_downgrade_window_open?
    return true if @current_plan_user&.plan&.price.to_i.zero?
    return true if @current_plan_user&.expires_on.blank?

    @current_plan_user.expires_on <= (Date.current + 7.days)
  end
end
