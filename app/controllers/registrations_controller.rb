class RegistrationsController < ApplicationController
  RENEWAL_NOTICE_DAYS = 7

  before_action :redirect_admin_users!
  before_action :set_plan
  before_action :ensure_plan_available_for_current_user!, if: :account_authenticated?

  def new
    @user = registration_user
  end

  def create
    @user = registration_user
    @user.assign_attributes(user_params)
    @user.role = "account_admin"

    if @plan.price.zero?
      complete_free_registration
    else
      create_paid_registration
    end
  end

  private

  def redirect_admin_users!
    return unless admin_authenticated?

    redirect_to root_path, alert: "Super admin accounts cannot purchase or renew plans."
  end

  def set_plan
    @plan = Plan.find(params[:plan_id])
  end

  def registration_user
    return current_account_user if account_authenticated?

    @plan.users.new(role: "account_admin")
  end

  def user_params
    permitted = %i[company_name name email phone]
    permitted << :password if params.dig(:user, :password).present? || !account_authenticated?
    params.require(:user).permit(*permitted)
  end

  def complete_free_registration
    @user.plan = @plan
    @user.active = true
    @user.status = "active"

    if @user.save
      redirect_to(account_authenticated? ? plan_purchases_path : login_path, notice: success_message_for_free_plan)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def create_paid_registration
    unless RazorpayClient.configured?
      @user.errors.add(:base, "Razorpay is not configured. Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET.")
      render :new, status: :unprocessable_entity
      return
    end

    if account_authenticated?
      build_paid_purchase_for_existing_account
    else
      build_paid_purchase_for_new_account
    end
  end

  def build_paid_purchase_for_existing_account
    purchase = ActiveRecord::Base.transaction do
      @user.save! if @user.changed?
      create_plan_purchase!(@user)
    end

    redirect_to plan_purchase_path(purchase, open_checkout: 1), notice: "Continue with Razorpay to complete your payment."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  rescue RazorpayClient::Error => e
    @user.errors.add(:base, e.message)
    render :new, status: :unprocessable_entity
  end

  def build_paid_purchase_for_new_account
    @user.plan = @plan
    @user.active = false
    @user.status = "payment_pending"

    purchase = ActiveRecord::Base.transaction do
      @user.save!
      create_plan_purchase!(@user)
    end

    redirect_to plan_purchase_path(purchase, open_checkout: 1), notice: "Registration saved. Razorpay checkout will open for payment."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  rescue RazorpayClient::Error => e
    @user.errors.add(:base, e.message)
    render :new, status: :unprocessable_entity
  end

  def create_plan_purchase!(user)
    receipt = "plan_#{SecureRandom.hex(8)}"
    order = RazorpayClient.new.create_order(
      amount_subunits: @plan.price * 100,
      currency: "INR",
      receipt: receipt,
      notes: {
        plan_code: @plan.code,
        user_email: user.email,
        company_name: user.company_name
      }
    )

    PlanPurchase.create!(
      plan: @plan,
      user: user,
      status: "pending",
      amount: @plan.price,
      currency: "INR",
      receipt: receipt,
      razorpay_order_id: order.fetch("id"),
      order_payload: order
    )
  end

  def ensure_plan_available_for_current_user!
    return if plan_available_for_current_user?

    redirect_to root_path(anchor: "plans"), alert: "That plan is not available for your account right now."
  end

  def plan_available_for_current_user?
    return true if current_account_user.plan.blank?
    return true if @plan.price.to_i >= current_account_user.plan.price.to_i

    current_plan_renewable?
  end

  def current_plan_renewable?
    return true if current_account_user.plan.price.to_i.zero?
    return true if current_account_user.expires_on.blank?

    current_account_user.expires_on <= (Date.current + RENEWAL_NOTICE_DAYS)
  end

  def success_message_for_free_plan
    return "Plan updated successfully. Your order history is available in Orders." if account_authenticated?

    "Registration completed for the #{@plan.name} plan. You can log in now."
  end
end
