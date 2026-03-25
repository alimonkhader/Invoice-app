require "rails_helper"

RSpec.describe PlanPurchaseInvoicePdfBuilder do
  it "renders a pdf for a plan purchase" do
    purchase = create(:plan_purchase, status: "paid", razorpay_payment_id: "pay_1", paid_at: Time.current)

    pdf = described_class.new(purchase, view_context: ApplicationController.helpers).render

    expect(pdf).to start_with("%PDF")
  end
end
