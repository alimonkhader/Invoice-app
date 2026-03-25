require "rails_helper"

RSpec.describe "Registrations", type: :request do
  let(:free_plan) { create(:plan, code: "trial", price: 0, duration_months: 0) }
  let(:paid_plan) { create(:plan, code: "paid", price: 999, duration_months: 1) }

  def user_params(email: "new@example.com")
    {
      company_name: "Example Co",
      name: "New User",
      email: email,
      phone: "9999999999",
      password: "password123"
    }
  end

  it "renders the registration page" do
    get new_plan_registration_path(free_plan)

    expect(response).to have_http_status(:ok)
  end

  it "completes free registration for guests" do
    post plan_registrations_path(free_plan), params: { user: user_params }

    expect(response).to redirect_to(login_path)
    expect(User.find_by(email: "new@example.com")).to be_active
  end

  it "renders errors for invalid free registration" do
    post plan_registrations_path(free_plan), params: { user: user_params(email: "") }

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "blocks paid registration when razorpay is not configured" do
    allow(RazorpayClient).to receive(:configured?).and_return(false)

    post plan_registrations_path(paid_plan), params: { user: user_params(email: "paid@example.com") }

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "creates a paid registration for new users" do
    allow(RazorpayClient).to receive(:configured?).and_return(true)
    allow_any_instance_of(RazorpayClient).to receive(:create_order).and_return({ "id" => "order_123" })

    post plan_registrations_path(paid_plan), params: { user: user_params(email: "paid@example.com") }

    expect(response).to redirect_to(plan_purchase_path(PlanPurchase.last, open_checkout: 1))
    expect(User.find_by(email: "paid@example.com")).not_to be_active
  end

  it "renders errors when paid registration order creation fails" do
    allow(RazorpayClient).to receive(:configured?).and_return(true)
    allow_any_instance_of(RazorpayClient).to receive(:create_order).and_raise(RazorpayClient::Error, "no order")

    post plan_registrations_path(paid_plan), params: { user: user_params(email: "paid2@example.com") }

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "renders errors when paid registration save fails before order creation" do
    allow(RazorpayClient).to receive(:configured?).and_return(true)

    post plan_registrations_path(paid_plan), params: { user: user_params(email: "") }

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "updates the current account with a free plan" do
    user = create(:user, expires_on: Date.current)
    sign_in user

    post plan_registrations_path(free_plan), params: { user: user_params(email: user.email) }

    expect(response).to redirect_to(plan_purchases_path)
  end

  it "creates a paid purchase for an existing account" do
    user = create(:user, expires_on: Date.current)
    sign_in user
    allow(RazorpayClient).to receive(:configured?).and_return(true)
    allow_any_instance_of(RazorpayClient).to receive(:create_order).and_return({ "id" => "order_456" })

    post plan_registrations_path(paid_plan), params: { user: user_params(email: user.email) }

    expect(response).to redirect_to(plan_purchase_path(PlanPurchase.last, open_checkout: 1))
  end

  it "renders errors when an existing account save fails before order creation" do
    user = create(:user, expires_on: Date.current)
    sign_in user
    allow(RazorpayClient).to receive(:configured?).and_return(true)

    post plan_registrations_path(paid_plan), params: { user: user_params(email: "") }

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "renders errors when an existing account order creation fails" do
    user = create(:user, expires_on: Date.current)
    sign_in user
    allow(RazorpayClient).to receive(:configured?).and_return(true)
    allow_any_instance_of(RazorpayClient).to receive(:create_order).and_raise(RazorpayClient::Error, "order failed")

    post plan_registrations_path(paid_plan), params: { user: user_params(email: user.email) }

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "blocks admins from registration purchase pages" do
    admin = create(:user, :admin)
    post admin_session_path, params: { email: admin.email, password: "password123" }

    get new_plan_registration_path(free_plan)

    expect(response).to redirect_to(root_path)
  end

  it "blocks downgrade attempts outside the renewal window" do
    current_plan = create(:plan, price: 1000, duration_months: 1)
    lower_plan = create(:plan, price: 100, duration_months: 1)
    user = create(:user, plan: current_plan, expires_on: Date.current + 20.days)
    sign_in user

    get new_plan_registration_path(lower_plan)

    expect(response).to redirect_to(root_path(anchor: "plans"))
  end
end
