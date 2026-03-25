require "rails_helper"

RSpec.describe "Plan purchases", type: :request do
  let(:plan) { create(:plan, price: 999, duration_months: 1) }
  let(:user) { create(:user, plan: plan) }
  let(:purchase) { create(:plan_purchase, plan: plan, user: user, status: "pending") }

  before do
    sign_in user
  end

  it "lists purchases for the signed-in account user" do
    purchase

    get plan_purchases_path

    expect(response).to have_http_status(:ok)
  end

  it "redirects admins away from account order pages" do
    sign_out user
    admin = create(:user, :admin)
    post admin_session_path, params: { email: admin.email, password: "password123" }

    get plan_purchase_path(purchase)

    expect(response).to redirect_to(root_path)
  end

  it "shows the order page and checkout options when enabled" do
    allow(RazorpayClient).to receive(:checkout_enabled?).and_return(true)
    allow(RazorpayClient).to receive(:key_id).and_return("key")

    get plan_purchase_path(purchase), params: { open_checkout: 1 }

    expect(response).to have_http_status(:ok)
  end

  it "serves the pdf invoice to the owner" do
    get plan_purchase_path(purchase, format: :pdf)

    expect(response.media_type).to eq("application/pdf")
  end

  it "redirects guests who try to open the pdf invoice" do
    sign_out user

    get plan_purchase_path(purchase, format: :pdf)

    expect(response).to redirect_to(login_path)
  end

  it "downloads the invoice for the owner" do
    get download_invoice_plan_purchase_path(purchase)

    expect(response.media_type).to eq("application/pdf")
  end

  it "redirects when verification is attempted twice" do
    purchase.update!(status: "paid")

    post verify_plan_purchase_path(purchase)

    expect(response).to redirect_to(plan_purchases_path)
  end

  it "sends guests to login when a paid order is re-verified" do
    purchase.update!(status: "paid")
    sign_out user

    post verify_plan_purchase_path(purchase)

    expect(response).to redirect_to(login_path)
  end

  it "marks a purchase failed when the order id mismatches" do
    post verify_plan_purchase_path(purchase), params: {
      razorpay_order_id: "wrong",
      razorpay_payment_id: "pay",
      razorpay_signature: "sig"
    }

    expect(response).to redirect_to(plan_purchase_path(purchase))
    expect(purchase.reload).to be_failed
  end

  it "marks a purchase paid when signature verification passes" do
    allow_any_instance_of(RazorpayClient).to receive(:verify_payment_signature).and_return(true)

    post verify_plan_purchase_path(purchase), params: {
      razorpay_order_id: purchase.razorpay_order_id,
      razorpay_payment_id: "pay",
      razorpay_signature: "sig"
    }

    expect(response).to redirect_to(plan_purchases_path)
    expect(purchase.reload).to be_paid
  end

  it "marks a purchase failed when signature verification fails" do
    allow_any_instance_of(RazorpayClient).to receive(:verify_payment_signature).and_return(false)

    post verify_plan_purchase_path(purchase), params: {
      razorpay_order_id: purchase.razorpay_order_id,
      razorpay_payment_id: "pay",
      razorpay_signature: "sig"
    }

    expect(response).to redirect_to(plan_purchase_path(purchase))
    expect(purchase.reload).to be_failed
  end
end
