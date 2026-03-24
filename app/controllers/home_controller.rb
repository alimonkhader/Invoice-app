class HomeController < ApplicationController
  def index
    @plans = Plan.active_first
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
  end
end
