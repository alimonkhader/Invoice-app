class Invoice < ApplicationRecord
  before_save :calculate_totals

  belongs_to :customer
  belongs_to :user, optional: true
  has_many :invoice_items, dependent: :destroy

  accepts_nested_attributes_for :invoice_items, allow_destroy: true

  def gst_enabled?
    user&.gst_enabled? != false
  end

  def calculate_totals
    subtotal = invoice_items.sum { |item| item.quantity.to_f * item.price.to_f }

    self.total = subtotal.round(2)

    if gst_enabled?
      self.cgst = (subtotal * 0.09).round(2)
      self.sgst = (subtotal * 0.09).round(2)
    else
      self.cgst = 0
      self.sgst = 0
    end

    self.final_total = (total.to_f + cgst.to_f + sgst.to_f).round(2)
  end
end
