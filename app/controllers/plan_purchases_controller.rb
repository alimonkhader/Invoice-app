class PlanPurchasesController < ApplicationController
  before_action :set_plan_purchase

  def show
    return redirect_to login_path, notice: "Payment already completed. Please log in." if @plan_purchase.paid?

    unless RazorpayClient.checkout_enabled?
      redirect_to root_path, alert: "Razorpay is not configured. Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET."
      return
    end

    @checkout_options = {
      key: RazorpayClient.key_id,
      amount: @plan_purchase.amount_in_subunits,
      currency: @plan_purchase.currency,
      name: "Invoice App",
      description: "#{@plan_purchase.plan.name} plan purchase",
      order_id: @plan_purchase.razorpay_order_id,
      prefill: {
        name: @plan_purchase.user.name,
        email: @plan_purchase.user.email,
        contact: @plan_purchase.user.phone
      },
      notes: {
        company_name: @plan_purchase.user.company_name,
        plan_name: @plan_purchase.plan.name,
        receipt: @plan_purchase.receipt
      },
      theme: {
        color: "#2f855a"
      }
    }
  end

  def verify
    if @plan_purchase.paid?
      redirect_to login_path, notice: "Payment already verified. Please log in."
      return
    end

    payment_id = params[:razorpay_payment_id].to_s
    order_id = params[:razorpay_order_id].to_s
    signature = params[:razorpay_signature].to_s
    payload = params.to_unsafe_h.slice("razorpay_payment_id", "razorpay_order_id", "razorpay_signature")

    if order_id != @plan_purchase.razorpay_order_id
      @plan_purchase.mark_failed!(reason: "Order mismatch during verification.", payload: payload)
      redirect_to plan_purchase_path(@plan_purchase), alert: "Payment verification failed because the order did not match."
      return
    end

    verified = RazorpayClient.new.verify_payment_signature(
      order_id: @plan_purchase.razorpay_order_id,
      payment_id: payment_id,
      signature: signature
    )

    if verified
      @plan_purchase.mark_paid!(payment_id: payment_id, signature: signature, payload: payload)
      redirect_to login_path, notice: "Payment completed. Your account is now active."
    else
      @plan_purchase.mark_failed!(reason: "Signature verification failed.", payload: payload)
      redirect_to plan_purchase_path(@plan_purchase), alert: "Payment verification failed. Please retry the payment."
    end
  end

  private

  def set_plan_purchase
    @plan_purchase = PlanPurchase.includes(:plan, :user).find(params[:id])
  end
end
