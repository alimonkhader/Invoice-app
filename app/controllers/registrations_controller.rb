class RegistrationsController < ApplicationController
  before_action :set_plan

  def new
    @user = @plan.users.new(role: "account_admin")
  end

  def create
    @user = @plan.users.new(user_params.merge(role: "account_admin"))

    if @plan.price.zero?
      complete_free_registration
    else
      create_paid_registration
    end
  end

  private

  def set_plan
    @plan = Plan.find(params[:plan_id])
  end

  def user_params
    params.require(:user).permit(:company_name, :name, :email, :phone, :password)
  end

  def complete_free_registration
    @user.active = true
    @user.status = "active"

    if @user.save
      redirect_to login_path, notice: "Registration completed for the #{@plan.name} plan. You can log in now."
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

    @user.active = false
    @user.status = "payment_pending"

    begin
      purchase = ActiveRecord::Base.transaction do
        @user.save!
        create_plan_purchase!(@user)
      end

      redirect_to plan_purchase_path(purchase), notice: "Registration saved. Complete the Razorpay payment to activate your account."
    rescue ActiveRecord::RecordInvalid
      render :new, status: :unprocessable_entity
    rescue RazorpayClient::Error => e
      @user.errors.add(:base, e.message)
      render :new, status: :unprocessable_entity
    end
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
end
