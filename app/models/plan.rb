class Plan < ApplicationRecord
  has_many :users, dependent: :restrict_with_exception
  has_many :plan_purchases, dependent: :restrict_with_exception

  validates :name, :code, :price, presence: true
  validates :code, uniqueness: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :duration_months, numericality: { greater_than_or_equal_to: 0 }
  validates :invoice_limit, numericality: { greater_than: 0 }, allow_nil: true

  scope :active_first, -> { where(active: true).order(:position, :price) }
  scope :ordered, -> { order(:position, :price, :name) }

  def unlimited_invoices?
    invoice_limit.nil?
  end

  def duration_label
    return "Trial" if duration_months.to_i.zero?
    return "1 month" if duration_months == 1

    "#{duration_months} months"
  end
end
