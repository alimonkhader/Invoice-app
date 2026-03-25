require "rails_helper"

RSpec.describe Invoice, type: :model do
  describe "#gst_enabled?" do
    it "defaults to true when the user is nil" do
      expect(build(:invoice, user: nil).gst_enabled?).to be(true)
    end

    it "reflects the user setting" do
      invoice = build(:invoice, user: build(:user, gst_enabled: false))

      expect(invoice.gst_enabled?).to be(false)
    end
  end

  describe "#calculate_totals" do
    it "calculates subtotal and GST totals when GST is enabled" do
      invoice = build(:invoice)
      invoice.invoice_items = [
        build(:invoice_item, invoice: invoice, quantity: 2, price: 100),
        build(:invoice_item, invoice: invoice, quantity: 1, price: 50)
      ]

      invoice.calculate_totals

      expect(invoice.total).to eq(250)
      expect(invoice.cgst).to eq(22.5)
      expect(invoice.sgst).to eq(22.5)
      expect(invoice.final_total).to eq(295)
    end

    it "removes GST when the user disables it" do
      invoice = build(:invoice, user: build(:user, gst_enabled: false))
      invoice.invoice_items = [build(:invoice_item, invoice: invoice, quantity: 1, price: 100)]

      invoice.calculate_totals

      expect(invoice.total).to eq(100)
      expect(invoice.cgst).to eq(0)
      expect(invoice.sgst).to eq(0)
      expect(invoice.final_total).to eq(100)
    end
  end
end
