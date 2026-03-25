class PlanPurchasesController < ApplicationController
  before_action :require_account_authentication, only: :index
  before_action :redirect_admin_users!
  before_action :set_plan_purchase, except: :index

  def index
    authorize PlanPurchase
    @plan_purchases = current_account_user.plan_purchases.recent_first
  end

  def show
    authorize @plan_purchase
    respond_to do |format|
      format.html do
        @checkout_options = checkout_options if show_checkout?
      end
      format.pdf do
        return unless require_account_purchase_access!

        send_purchase_invoice_pdf
      end
    end
  end

  def verify
    authorize @plan_purchase
    if @plan_purchase.paid?
      redirect_to post_payment_redirect_path, notice: "Payment already verified."
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
      redirect_to post_payment_redirect_path, notice: "Payment completed. Your order is now marked as paid."
    else
      @plan_purchase.mark_failed!(reason: "Signature verification failed.", payload: payload)
      redirect_to plan_purchase_path(@plan_purchase), alert: "Payment verification failed. Please retry the payment."
    end
  end

  def download_invoice
    authorize @plan_purchase, :download_invoice?
    return unless require_account_purchase_access!

    send_purchase_invoice_pdf
  end

  private

  def redirect_admin_users!
    return unless admin_authenticated?

    redirect_to root_path, alert: "Admin accounts cannot open account order pages."
  end

  def set_plan_purchase
    @plan_purchase = if account_authenticated?
                       current_account_user.plan_purchases.includes(:plan, :user).find(params[:id])
                     else
                       PlanPurchase.includes(:plan, :user).find(params[:id])
                     end
  end

  def require_account_purchase_access!
    return true if account_authenticated? && @plan_purchase.user_id == current_account_user.id

    redirect_to login_path, alert: "Please log in to view this order invoice."
    false
  end

  def show_checkout?
    return false if @plan_purchase.paid?
    return false unless RazorpayClient.checkout_enabled?

    true
  end

  def checkout_options
    {
      key: RazorpayClient.key_id,
      amount: @plan_purchase.amount_in_subunits,
      currency: @plan_purchase.currency,
      name: "Nilam Invoice",
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

  def send_purchase_invoice_pdf
    send_data purchase_invoice_pdf_data(@plan_purchase),
              filename: @plan_purchase.invoice_filename,
              type: "application/pdf",
              disposition: "inline"
  end

  def purchase_invoice_pdf_data(plan_purchase)
    PlanPurchaseInvoicePdfBuilder.new(plan_purchase, view_context: view_context).render
  end

  def post_payment_redirect_path
    return plan_purchases_path if account_authenticated?

    login_path
  end
end
