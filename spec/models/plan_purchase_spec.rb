require "rails_helper"

RSpec.describe PlanPurchase, type: :model do
  describe "validations" do
    it "validates status, amount, currency, and receipt" do
      purchase = build(:plan_purchase, status: "unknown", amount: -1, currency: nil, receipt: nil)

      expect(purchase).not_to be_valid
      expect(purchase.errors[:status]).to include("is not included in the list")
      expect(purchase.errors[:amount]).to include("must be greater than or equal to 0")
      expect(purchase.errors[:currency]).to include("can't be blank")
      expect(purchase.errors[:receipt]).to include("can't be blank")
    end
  end

  describe "scopes" do
    it "returns recent, pending, and paid purchases" do
      older = create(:plan_purchase, created_at: 2.days.ago, status: "pending")
      newer = create(:plan_purchase, created_at: 1.day.ago, status: "paid")

      expect(described_class.recent_first).to eq([newer, older])
      expect(described_class.pending).to eq([older])
      expect(described_class.paid).to eq([newer])
    end
  end

  describe "status helpers" do
    it "reports paid, pending, and failed states" do
      expect(build(:plan_purchase, status: "paid")).to be_paid
      expect(build(:plan_purchase, status: "pending")).to be_pending
      expect(build(:plan_purchase, status: "failed")).to be_failed
    end
  end

  describe "display helpers" do
    it "returns amount in subunits and file identifiers" do
      purchase = build(:plan_purchase, id: 12, amount: 123, receipt: "abc")

      expect(purchase.amount_in_subunits).to eq(12_300)
      expect(purchase.display_number).to eq("ORD-000012")
      expect(purchase.invoice_filename).to eq("plan_purchase_abc.pdf")
    end

    it "allows retry only when unpaid and order id exists" do
      expect(build(:plan_purchase, status: "pending", razorpay_order_id: "order_1")).to be_can_retry_payment
      expect(build(:plan_purchase, status: "paid", razorpay_order_id: "order_1")).not_to be_can_retry_payment
      expect(build(:plan_purchase, status: "failed", razorpay_order_id: nil)).not_to be_can_retry_payment
    end
  end

  describe "#mark_paid!" do
    it "marks the purchase paid and activates the user plan" do
      plan = create(:plan, duration_months: 1, price: 999)
      user = create(:user, plan: create(:plan), active: false, status: "payment_pending")
      purchase = create(:plan_purchase, plan: plan, user: user, status: "pending")

      purchase.mark_paid!(payment_id: "pay_1", signature: "sig_1", payload: { "ok" => true })

      expect(purchase.reload).to have_attributes(
        status: "paid",
        razorpay_payment_id: "pay_1",
        razorpay_signature: "sig_1",
        payment_payload: { "ok" => true },
        failure_reason: nil
      )
      expect(purchase.paid_at).to be_present
      expect(purchase.failed_at).to be_nil
      expect(user.reload.plan).to eq(plan)
      expect(user).to be_active
    end
  end

  describe "#mark_failed!" do
    it "stores failure details and keeps prior payload when a blank one is passed" do
      purchase = create(:plan_purchase, payment_payload: { "before" => true })

      purchase.mark_failed!(reason: "bad", payload: {})

      expect(purchase.reload).to have_attributes(
        status: "failed",
        failure_reason: "bad",
        payment_payload: { "before" => true }
      )
      expect(purchase.failed_at).to be_present
    end
  end
end
