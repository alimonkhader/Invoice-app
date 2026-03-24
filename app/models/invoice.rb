class Invoice < ApplicationRecord
  
  before_save :calculate_totals

  has_many :invoice_items, dependent: :destroy
  belongs_to :customer
  has_many :invoice_items, dependent: :destroy
  accepts_nested_attributes_for :invoice_items, allow_destroy: true

  def calculate_totals
    subtotal = invoice_items.sum { |item| item.quantity.to_f * item.price.to_f }

    self.total = subtotal.round(2)
    self.cgst = (subtotal * 0.09).round(2)
    self.sgst = (subtotal * 0.09).round(2)
    self.final_total = (subtotal + cgst + sgst).round(2)
  end
end
