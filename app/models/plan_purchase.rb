class PlanPurchase < ApplicationRecord
  STATUSES = %w[pending paid failed].freeze

  belongs_to :plan
  belongs_to :user

  validates :status, inclusion: { in: STATUSES }
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, :receipt, presence: true
  validates :receipt, uniqueness: true

  scope :recent_first, -> { includes(:plan, :user).order(created_at: :desc) }
  scope :pending, -> { where(status: "pending") }
  scope :paid, -> { where(status: "paid") }

  def paid?
    status == "paid"
  end

  def pending?
    status == "pending"
  end

  def amount_in_subunits
    amount * 100
  end

  def mark_paid!(payment_id:, signature:, payload: {})
    transaction do
      update!(
        status: "paid",
        razorpay_payment_id: payment_id,
        razorpay_signature: signature,
        payment_payload: payload,
        paid_at: Time.current,
        failure_reason: nil,
        failed_at: nil
      )
      user.activate_plan_access!
    end
  end

  def mark_failed!(reason:, payload: {})
    update!(
      status: "failed",
      payment_payload: payload.presence || payment_payload,
      failure_reason: reason,
      failed_at: Time.current
    )
  end
end
